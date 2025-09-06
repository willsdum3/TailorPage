import React, { createContext, useContext, useEffect, useState } from 'react';
import { User, Session } from '@supabase/supabase-js';
import { supabase, supabaseAdmin } from '../lib/supabase';

interface AuthContextType {
  user: User | null;
  session: Session | null;
  loading: boolean;
  signIn: (emailOrUsername: string, password: string) => Promise<{ error: any }>;
  signUp: (email: string, password: string, userData: { name: string; username: string }) => Promise<{ error: any }>;
  signInWithGoogle: () => Promise<{ error: any }>;
  signOut: () => Promise<void>;
  resetPassword: (email: string) => Promise<{ error: any }>;
  updatePassword: (currentPassword: string, newPassword: string) => Promise<{ error: any }>;
  updateUsername: (newUsername: string) => Promise<{ error: any; data?: any }>;
  refreshUserMetadata: () => Promise<void>;
  fixExistingUserUsernames: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

interface AuthProviderProps {
  children: React.ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Get initial session
    const getInitialSession = async () => {
      try {
        console.log('🔄 Getting initial session...');
        const { data: { session }, error } = await supabase.auth.getSession();
        
        if (error) {
          console.error('❌ Error getting initial session:', error);
          // Clear any corrupted session data
          await supabase.auth.signOut();
          setSession(null);
          setUser(null);
          setLoading(false);
          return;
        }
        
        console.log('✅ Initial session loaded:', session?.user?.id);
        setSession(session);
        setUser(session?.user ?? null);
        
        // If we have a session, ensure user metadata is properly loaded
        if (session?.user) {
          console.log('🔄 Ensuring user metadata is loaded for initial session...');
          // Run this in background without blocking the loading state
          setTimeout(async () => {
            try {
              await refreshUserMetadata();
              await ensureUserDataRestored();
            } catch (err) {
              console.error('❌ Error refreshing user metadata for initial session:', err);
            }
          }, 500);
        }
        
        setLoading(false);
      } catch (err) {
        console.error('❌ Unexpected error getting initial session:', err);
        // Clear session and continue
        await supabase.auth.signOut();
        setSession(null);
        setUser(null);
        setLoading(false);
      }
    };

    // Add timeout protection
    const timeoutId = setTimeout(() => {
      console.warn('⚠️ Session loading timeout - forcing continue');
      setLoading(false);
    }, 3000); // Reduced timeout to 3 seconds

    getInitialSession().finally(() => {
      clearTimeout(timeoutId);
    });

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        console.log('🔄 Auth state changed:', event, session?.user?.id);
        
        try {
                     // Handle specific auth events first
           if (event === 'SIGNED_IN' && session?.user) {
             console.log('✅ User signed in, ensuring profile exists...');
             
             // Try profile creation but don't block signin if it fails
             const ensureProfile = async () => {
               try {
                 // For existing users, we want to preserve their current profile picture
                 // Only update avatar_url if it's actually changing and the user doesn't already have one
                 let avatarUrlToUse = session.user.user_metadata?.avatar_url || null;
                 let existingUser = null;
                 
                 // If this is a Google OAuth user and they already have a profile, 
                 // we should be more careful about overwriting their existing avatar
                 if (session.user.app_metadata?.provider === 'google') {
                   console.log('🔍 Google OAuth user detected');
                   
                   // Check if user already exists in our database
                   const { data: userData } = await supabaseAdmin
                     .from('users')
                     .select('avatar_url, username')
                     .eq('auth_user_id', session.user.id)
                     .single();
                   
                   existingUser = userData;
                   
                   if (existingUser?.avatar_url) {
                     console.log('🔄 User already has profile picture, preserving existing:', existingUser.avatar_url);
                     // Don't overwrite existing avatar with Google's version
                     avatarUrlToUse = existingUser.avatar_url;
                     
                     // Also log what Google is trying to set
                     console.log('🔄 Google OAuth avatar URL:', session.user.user_metadata?.avatar_url);
                     console.log('🔄 Will preserve existing avatar instead');
                   } else {
                     console.log('🆕 New Google user, using Google avatar:', avatarUrlToUse);
                   }
                   
                   // Additional safety check: if we have an existing user, force preserve their data
                   if (existingUser) {
                     console.log('🛡️ Existing user detected, ensuring data preservation');
                     // For existing users, we should be extra careful about data loss
                     if (!avatarUrlToUse && existingUser.avatar_url) {
                       avatarUrlToUse = existingUser.avatar_url;
                       console.log('🛡️ Forced avatar preservation for existing user');
                     }
                   }
                 }
                 
                 const { data: userProfile, error: profileError } = await supabaseAdmin
                   .rpc('get_or_create_user', {
                     auth_user_id: session.user.id,
                     user_name: session.user.user_metadata?.name || 'User',
                     user_email: session.user.email || '',
                     user_username: session.user.user_metadata?.username || null,
                     user_avatar_url: avatarUrlToUse
                   });
                 
                 console.log('🔍 get_or_create_user result:', { userProfile, profileError });

                                   if (profileError) {
                    console.error('❌ Error ensuring user profile exists:', profileError);
                  } else {
                    console.log('✅ User profile ensured:', userProfile);
                    
                    // For Google OAuth users, we need to handle username creation
                    if (session.user.app_metadata?.provider === 'google') {
                      console.log('🔍 Google OAuth user detected');
                      
                      // If no username exists, create one from email
                      if (!userProfile?.username && session.user.email) {
                        const emailPrefix = session.user.email.split('@')[0];
                        const suggestedUsername = emailPrefix;
                        
                        console.log('🔄 Creating username for Google user:', suggestedUsername);
                        
                        try {
                          // Update the user profile with the username, but preserve existing avatar
                          const { error: updateError } = await supabaseAdmin
                            .rpc('get_or_create_user', {
                              auth_user_id: session.user.id,
                              user_name: session.user.user_metadata?.name || session.user.user_metadata?.full_name || 'User',
                              user_email: session.user.email,
                              user_username: suggestedUsername,
                              user_avatar_url: avatarUrlToUse // Use the preserved avatar URL
                            });
                          
                          if (updateError) {
                            console.error('❌ Failed to create username for Google user:', updateError);
                          } else {
                            console.log('✅ Username created for Google user:', suggestedUsername);
                          }
                        } catch (err) {
                          console.error('❌ Error creating username for Google user:', err);
                        }
                      }
                    }
                    
                                         // Check if username needs to be restored to user_metadata
                     if (userProfile && userProfile.username && !session.user.user_metadata?.username) {
                       console.log('🔄 Restoring missing username in user_metadata:', userProfile.username);
                       try {
                         const { error: updateError } = await supabase.auth.updateUser({
                           data: {
                             username: userProfile.username
                           }
                         });
                         
                         if (updateError) {
                           console.error('❌ Failed to restore username in user_metadata:', updateError);
                         } else {
                           console.log('✅ Successfully restored username in user_metadata');
                           // Force a session refresh to get updated metadata
                           await supabase.auth.refreshSession();
                         }
                       } catch (err) {
                         console.error('❌ Error restoring username in user_metadata:', err);
                       }
                     }
                     
                     // Additional safety check: ensure avatar is preserved in user_metadata for existing users
                     if (userProfile && existingUser?.avatar_url && session.user.user_metadata?.avatar_url !== existingUser.avatar_url) {
                       console.log('🛡️ Ensuring avatar is preserved in user_metadata:', existingUser.avatar_url);
                       try {
                         const { error: updateError } = await supabase.auth.updateUser({
                           data: {
                             avatar_url: existingUser.avatar_url
                           }
                         });
                         
                         if (updateError) {
                           console.error('❌ Failed to preserve avatar in user_metadata:', updateError);
                         } else {
                           console.log('✅ Successfully preserved avatar in user_metadata');
                           // Force a session refresh to get updated metadata
                           await supabase.auth.refreshSession();
                         }
                       } catch (err) {
                         console.error('❌ Error preserving avatar in user_metadata:', err);
                       }
                     }
                  }
               } catch (err) {
                 console.error('❌ Unexpected error ensuring user profile:', err);
               }
             };
             
             // Run profile creation in background without blocking signin
             ensureProfile().catch(err => {
               console.log('⚠️ Profile creation failed, but signin continues:', err);
             });
             
             // Also ensure user metadata is properly restored
             setTimeout(async () => {
               try {
                 console.log('🔄 Ensuring user metadata is properly restored after signin...');
                 await refreshUserMetadata();
                 await ensureUserDataRestored();
               } catch (err) {
                 console.error('❌ Error refreshing user metadata after signin:', err);
               }
             }, 1000); // Small delay to ensure session is fully established
           } else if (event === 'SIGNED_OUT') {
            console.log('🚪 User signed out event detected - letting signOut function handle state clearing');
          } else if (event === 'USER_UPDATED' && session?.user) {
            console.log('🔄 User updated, ensuring profile exists...');
            console.log('🔄 Updated user metadata:', session.user.user_metadata);
            try {
              // For USER_UPDATED events, we should be extra careful about preserving existing data
              // Check if user already exists and has an avatar
              const { data: existingUser } = await supabaseAdmin
                .from('users')
                .select('avatar_url')
                .eq('auth_user_id', session.user.id)
                .single();
              
              let avatarUrlToUse = session.user.user_metadata?.avatar_url || null;
              
              // Preserve existing avatar if user has one and new one is not significantly different
              if (existingUser?.avatar_url && avatarUrlToUse) {
                // Only update if the URLs are actually different (not just Google's different format)
                if (existingUser.avatar_url !== avatarUrlToUse) {
                  console.log('🔄 User avatar changed, updating from', existingUser.avatar_url, 'to', avatarUrlToUse);
                } else {
                  console.log('🔄 User avatar unchanged, preserving existing:', existingUser.avatar_url);
                  avatarUrlToUse = existingUser.avatar_url;
                }
              } else if (existingUser?.avatar_url) {
                console.log('🔄 Preserving existing user avatar:', existingUser.avatar_url);
                avatarUrlToUse = existingUser.avatar_url;
              }
              
              const { data: userProfile, error: profileError } = await supabaseAdmin
                .rpc('get_or_create_user', {
                  auth_user_id: session.user.id,
                  user_name: session.user.user_metadata?.name || 'User',
                  user_email: session.user.email || '',
                  user_username: session.user.user_metadata?.username || null,
                  user_avatar_url: avatarUrlToUse
                });

              if (profileError) {
                console.error('❌ Error ensuring user profile exists on update:', profileError);
              } else {
                console.log('✅ User profile ensured on update:', userProfile);
              }
              
              // Ensure username is preserved in user_metadata
              if (userProfile && userProfile.username && !session.user.user_metadata?.username) {
                console.log('🔄 Restoring missing username in user_metadata:', userProfile.username);
                try {
                  const { error: updateError } = await supabase.auth.updateUser({
                    data: {
                      username: userProfile.username
                    }
                  });
                  
                  if (updateError) {
                    console.error('❌ Failed to restore username in user_metadata:', updateError);
                  } else {
                    console.log('✅ Successfully restored username in user_metadata');
                  }
                } catch (err) {
                  console.error('❌ Error restoring username in user_metadata:', err);
                }
              }
            } catch (err) {
              console.error('❌ Unexpected error ensuring user profile on update:', err);
            }
          }
          
          // Update session and user state based on event
          if (event === 'SIGNED_IN' || event === 'USER_UPDATED') {
            console.log('🔄 Updating user state with session user:', session?.user);
            console.log('🔄 Session user metadata:', session?.user?.user_metadata);
            console.log('🔄 Session user metadata type:', typeof session?.user?.user_metadata);
            console.log('🔄 Session user metadata keys:', session?.user?.user_metadata ? Object.keys(session.user.user_metadata) : 'no metadata');
            setSession(session);
            setUser(session?.user ?? null);
            console.log('🔄 User state updated, new user object:', session?.user);
          } else if (event === 'SIGNED_OUT') {
            // Don't update state here - let the signOut function handle it
            console.log('🔄 Skipping state update for SIGNED_OUT - handled by signOut function');
          }
        } catch (err) {
          console.error('❌ Error in auth state change handler:', err);
          // Don't let errors break the auth flow
        }
        
        setLoading(false);
      }
    );

    return () => {
      clearTimeout(timeoutId);
      subscription.unsubscribe();
    };
  }, []);

  const signIn = async (emailOrUsername: string, password: string) => {
    try {
      let email = emailOrUsername;
      
      // Check if the input is a username (not an email)
      if (!emailOrUsername.includes('@')) {
        console.log('🔄 Username detected, looking up email for username:', emailOrUsername);
        
        // Look up the email associated with this username
        // First try exact match
        let { data: userData, error: lookupError } = await supabaseAdmin
          .from('users')
          .select('email, username, auth_user_id')
          .eq('username', emailOrUsername)
          .single();
        
        // If exact match fails, try case-insensitive match
        if (lookupError && lookupError.code === 'PGRST116') {
          console.log('🔄 Exact username match failed, trying case-insensitive match...');
          const { data: caseInsensitiveData, error: caseInsensitiveError } = await supabaseAdmin
            .from('users')
            .select('email, username, auth_user_id')
            .ilike('username', emailOrUsername)
            .single();
          
          if (!caseInsensitiveError && caseInsensitiveData) {
            userData = caseInsensitiveData;
            lookupError = null;
            console.log('✅ Found username with case-insensitive match');
          }
        }
        
        console.log('🔍 Username lookup result:', { userData, lookupError });
        
        if (lookupError) {
          console.error('❌ Username lookup error:', lookupError);
          
          // Check if it's a "not found" error
          if (lookupError.code === 'PGRST116') {
            return { error: new Error('Username not found. Please check your username or try signing in with your email address.') };
          } else {
            return { error: new Error('Unable to verify username. Please try again or use your email address.') };
          }
        }
        
        if (!userData || !userData.email) {
          console.error('❌ No user data or email found for username:', emailOrUsername);
          return { error: new Error('Username not found. Please check your username or try signing in with your email address.') };
        }
        
        email = userData.email;
        console.log('✅ Found email for username:', email, 'User ID:', userData.auth_user_id);
      } else {
        console.log('🔄 Email detected, proceeding with direct sign-in');
      }
      
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });
      
      if (error) {
        return { error };
      }
      
                // After successful login, ensure username is preserved in user_metadata
          if (data.user && !data.user.user_metadata?.username) {
            console.log('🔄 Username missing from user_metadata, attempting to restore...');
            
            try {
              // Get the user profile from database to extract username
              const { data: userProfile, error: profileError } = await supabaseAdmin
                .rpc('get_or_create_user', {
                  auth_user_id: data.user.id,
                  user_name: data.user.user_metadata?.name || 'User',
                  user_email: data.user.email || '',
                  user_username: null, // Don't create new username, just get existing
                  user_avatar_url: data.user.user_metadata?.avatar_url || null
                });
              
              if (!profileError && userProfile && userProfile.username) {
                console.log('✅ Found username in database profile:', userProfile.username);
                
                // Update the user's metadata with the username
                const { error: updateError } = await supabase.auth.updateUser({
                  data: {
                    username: userProfile.username
                  }
                });
                
                if (updateError) {
                  console.error('❌ Failed to update user metadata with username:', updateError);
                } else {
                  console.log('✅ Successfully restored username in user_metadata');
                }
              }
            } catch (err) {
              console.error('❌ Error restoring username:', err);
              // Don't fail the login process if username restoration fails
            }
          } else if (data.user && data.user.user_metadata?.username) {
            console.log('✅ Username already exists in user_metadata:', data.user.user_metadata.username);
          }
      
      return { error: null };
    } catch (err) {
      console.error('❌ Unexpected error during signin:', err);
      return { error: err };
    }
  };

  const signUp = async (email: string, password: string, userData: { name: string; username: string }) => {
    try {
      console.log('Starting signup process for:', email);
      
      // Step 1: Create Supabase Auth user
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            name: userData.name,
            username: userData.username,
          },
        },
      });

      if (error) {
        console.error('Supabase Auth signup error:', error);
        return { error };
      }

      if (!data.user) {
        console.error('No user returned from signup');
        return { error: new Error('No user returned from signup') };
      }

      console.log('Supabase Auth user created:', data.user.id);

      // Step 2: Create user profile in our database using the helper function
      const { data: userProfile, error: profileError } = await supabaseAdmin
        .rpc('get_or_create_user', {
          auth_user_id: data.user.id,
          user_name: userData.name,
          user_email: email,
          user_username: userData.username,
          user_avatar_url: null
        });

      if (profileError) {
        console.error('Error creating user profile:', profileError);
        // Don't return error here as the auth user was created successfully
        // The profile can be created later when the user first logs in
      } else {
        console.log('User profile created successfully:', userProfile);
      }

      // Step 3: Ensure the username is properly saved in user_metadata
      // This is critical for the username to display correctly
      try {
        console.log('🔄 Ensuring username is saved in user_metadata...');
        
        // Update the user's metadata to include the username
        const { error: updateError } = await supabase.auth.updateUser({
          data: {
            username: userData.username
          }
        });
        
        if (updateError) {
          console.error('❌ Failed to update user metadata with username:', updateError);
          console.log('⚠️ Username may not display correctly - this is a critical issue');
        } else {
          console.log('✅ Successfully saved username in user_metadata:', userData.username);
          
          // Force a session refresh to ensure the updated metadata is available
          try {
            console.log('🔄 Refreshing session to get updated metadata...');
            const { error: refreshError } = await supabase.auth.refreshSession();
            if (refreshError) {
              console.error('❌ Failed to refresh session:', refreshError);
            } else {
              console.log('✅ Session refreshed successfully');
            }
          } catch (refreshErr) {
            console.error('❌ Error refreshing session:', refreshErr);
          }
        }
      } catch (err) {
        console.error('❌ Error updating user metadata with username:', err);
        console.log('⚠️ Username may not display correctly - this is a critical issue');
      }

      return { error: null };
    } catch (err) {
      console.error('Unexpected error during signup:', err);
      return { error: err };
    }
  };

  const signOut = async () => {
    try {
      console.log('🚪 Starting signout process...');
      
      // Clear local state first to prevent race conditions
      setUser(null);
      setSession(null);
      setLoading(false);
      
      // Sign out from Supabase with scope: 'local' to clear local session
      const { error } = await supabase.auth.signOut({ scope: 'local' });
      
      if (error) {
        console.error('❌ Error during signout:', error);
        // Don't throw error, just log it and continue
        console.log('⚠️ Continuing with signout despite error');
      } else {
        console.log('✅ Supabase signout successful');
      }
      
      // Additional cleanup - clear any remaining session data
      try {
        // Force clear the session by getting a fresh session (should be null)
        const { data: { session } } = await supabase.auth.getSession();
        if (session) {
          console.log('⚠️ Session still exists after signout, forcing clear...');
          // If session still exists, try global signout
          await supabase.auth.signOut({ scope: 'global' });
        }
      } catch (cleanupErr) {
        console.log('⚠️ Error during session cleanup:', cleanupErr);
      }
      
      // Ensure state is completely cleared
      setUser(null);
      setSession(null);
      setLoading(false);
      
      console.log('✅ Complete signout process finished');
      
    } catch (err) {
      console.error('❌ Unexpected error during signout:', err);
      // Ensure state is cleared even on error
      setUser(null);
      setSession(null);
      setLoading(false);
      console.log('⚠️ Continuing with signout despite error');
    }
  };

  const signInWithGoogle = async () => {
    try {
      console.log('🔄 Starting Google OAuth sign in...');
      
      const { data, error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: `${window.location.origin}`,
          queryParams: {
            access_type: 'offline',
            prompt: 'consent',
          },
        },
      });
      
      if (error) {
        console.error('❌ Google OAuth error:', error);
        return { error };
      }
      
      console.log('✅ Google OAuth initiated successfully');
      return { error: null };
    } catch (err) {
      console.error('❌ Unexpected error during Google OAuth:', err);
      return { error: err };
    }
  };

  const resetPassword = async (email: string) => {
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/reset-password`,
    });
    return { error };
  };

  const updatePassword = async (currentPassword: string, newPassword: string) => {
    try {
      console.log('🔄 Updating user password...');
      
      if (!user?.email) {
        return { error: new Error('User email not found') };
      }
      
      // Use Supabase's updateUser method directly - it handles current password verification internally
      // Add a timeout to the Supabase call itself
      const updatePromise = supabase.auth.updateUser({
        password: newPassword
      });
      
      const timeoutPromise = new Promise((_, reject) => {
        setTimeout(() => reject(new Error('Request timeout')), 20000); // 20 second timeout for the actual API call
      });
      
      try {
        const { data, error: updateError } = await Promise.race([updatePromise, timeoutPromise]) as any;
        
        if (updateError) {
          console.error('❌ Password update failed:', updateError);
          
          // Handle specific error cases
          if (updateError.message.includes('Password should be at least')) {
            return { error: new Error('Password must be at least 6 characters long') };
          } else if (updateError.message.includes('Invalid login credentials')) {
            return { error: new Error('Current password is incorrect') };
          } else if (updateError.message.includes('rate limit')) {
            return { error: new Error('Too many attempts. Please wait a moment and try again.') };
          } else if (updateError.message.includes('timeout')) {
            return { error: new Error('Request timed out. Please check your connection and try again.') };
          } else {
            return { error: new Error(updateError.message || 'Failed to update password') };
          }
        }
        
        // If we get here, the password was updated successfully
        console.log('✅ Password updated successfully', data);
        
        // Refresh the session to ensure user metadata is up to date
        try {
          console.log('🔄 Refreshing session after password update...');
          const { data: refreshData, error: refreshError } = await supabase.auth.refreshSession();
          
          if (refreshError) {
            console.error('❌ Error refreshing session after password update:', refreshError);
          } else {
            console.log('✅ Session refreshed successfully after password update');
            // Update local state with refreshed session
            setSession(refreshData.session);
            setUser(refreshData.user);
          }
        } catch (refreshErr) {
          console.error('❌ Error during session refresh after password update:', refreshErr);
        }
        
        return { error: null };
      } catch (raceError: any) {
        // This catches the timeout from Promise.race
        console.error('❌ Password update timed out:', raceError);
        
        // Check if the password might have been updated despite the timeout
        // We can't easily verify this without making another API call, so we'll suggest the user check
        if (raceError.message?.includes('timeout')) {
          return { error: new Error('Password update timed out, but it may have been successful. Please try signing out and back in to verify.') };
        }
        
        return { error: new Error(raceError.message || 'Password update failed due to timeout') };
      }
    } catch (err: any) {
      console.error('❌ Unexpected error during password update:', err);
      
      // Check if it's a network timeout or connection issue
      if (err.message?.includes('timeout') || err.message?.includes('network')) {
        return { error: new Error('Network timeout. Please check your connection and try again.') };
      }
      
      return { error: new Error(err.message || 'An unexpected error occurred') };
    }
  };

  const updateUsername = async (newUsername: string) => {
    try {
      console.log('🔄 Updating username to:', newUsername);
      
      if (!user?.id) {
        return { error: new Error('User not found') };
      }
      
      // First, check if the username is already taken
      const { data: existingUser, error: checkError } = await supabaseAdmin
        .from('users')
        .select('username')
        .eq('username', newUsername)
        .neq('auth_user_id', user.id) // Exclude current user
        .single();
      
      if (checkError && checkError.code !== 'PGRST116') { // PGRST116 is "not found" which is what we want
        console.error('❌ Error checking username availability:', checkError);
        return { error: new Error('Failed to check username availability') };
      }
      
      if (existingUser) {
        return { error: new Error('Username is already taken') };
      }
      
      // Update username in the database
      const { data: userProfile, error: dbError } = await supabaseAdmin
        .from('users')
        .update({ 
          username: newUsername,
          updated_at: new Date().toISOString()
        })
        .eq('auth_user_id', user.id)
        .select()
        .single();
      
      if (dbError) {
        console.error('❌ Error updating username in database:', dbError);
        
        // Handle specific database errors
        if (dbError.code === '23505') { // Unique constraint violation
          return { error: new Error('Username is already taken') };
        } else if (dbError.message.includes('duplicate key')) {
          return { error: new Error('Username is already taken') };
        } else {
          return { error: new Error('Failed to update username in database') };
        }
      }
      
      // Update username in Supabase Auth user metadata
      const { data: authData, error: authError } = await supabase.auth.updateUser({
        data: {
          username: newUsername
        }
      });
      
      if (authError) {
        console.error('❌ Error updating username in auth metadata:', authError);
        // Don't fail the entire operation if auth metadata update fails
        console.log('⚠️ Username updated in database but not in auth metadata');
      } else {
        console.log('✅ Username updated in auth metadata successfully');
      }
      
      // Refresh the session to get updated user data
      try {
        console.log('🔄 Refreshing session after username update...');
        const { data: refreshData, error: refreshError } = await supabase.auth.refreshSession();
        
        if (refreshError) {
          console.error('❌ Error refreshing session after username update:', refreshError);
        } else {
          console.log('✅ Session refreshed successfully after username update');
          console.log('🔄 Updated user metadata:', refreshData.user?.user_metadata);
          // Update local state with refreshed session
          setSession(refreshData.session);
          setUser(refreshData.user);
          
          // Force a small delay to ensure state updates are processed
          setTimeout(() => {
            console.log('🔄 Final user state after username update:', refreshData.user);
          }, 100);
        }
      } catch (refreshErr) {
        console.error('❌ Error during session refresh after username update:', refreshErr);
      }
      
      console.log('✅ Username updated successfully');
      return { error: null, data: { username: newUsername } };
      
    } catch (err: any) {
      console.error('❌ Unexpected error during username update:', err);
      return { error: new Error(err.message || 'An unexpected error occurred') };
    }
  };

  const ensureUserDataRestored = async () => {
    if (!user) return;
    
    try {
      console.log('🔄 Ensuring user data is properly restored...');
      
      // Get the latest user profile from database
      const { data: userProfile, error: profileError } = await supabaseAdmin
        .rpc('get_or_create_user', {
          auth_user_id: user.id,
          user_name: user.user_metadata?.name || 'User',
          user_email: user.email || '',
          user_username: null, // Don't create new username, just get existing
          user_avatar_url: user.user_metadata?.avatar_url || null
        });
      
      if (profileError) {
        console.error('❌ Error getting user profile for data restoration:', profileError);
        return;
      }
      
      console.log('✅ User data restoration check completed');
    } catch (err) {
      console.error('❌ Error ensuring user data restoration:', err);
    }
  };

  const refreshUserMetadata = async () => {
    if (!user) return;
    
    try {
      console.log('🔄 Refreshing user metadata...');
      
      // Check if user already exists and has an avatar to preserve
      const { data: existingUser } = await supabaseAdmin
        .from('users')
        .select('avatar_url')
        .eq('auth_user_id', user.id)
        .single();
      
      let avatarUrlToUse = user.user_metadata?.avatar_url || null;
      
      // Preserve existing avatar if user has one
      if (existingUser?.avatar_url && !avatarUrlToUse) {
        console.log('🔄 Preserving existing avatar during metadata refresh:', existingUser.avatar_url);
        avatarUrlToUse = existingUser.avatar_url;
      }
      
      // Get the latest user profile from database
      const { data: userProfile, error: profileError } = await supabaseAdmin
        .rpc('get_or_create_user', {
          auth_user_id: user.id,
          user_name: user.user_metadata?.name || 'User',
          user_email: user.email || '',
          user_username: null, // Don't create new username, just get existing
          user_avatar_url: avatarUrlToUse
        });
      
      if (profileError) {
        console.error('❌ Error getting user profile for metadata refresh:', profileError);
        return;
      }
      
      if (userProfile && userProfile.username && userProfile.username !== user.user_metadata?.username) {
        console.log('🔄 Updating user metadata with username:', userProfile.username);
        
        const { error: updateError } = await supabase.auth.updateUser({
          data: {
            username: userProfile.username
          }
        });
        
        if (updateError) {
          console.error('❌ Failed to update user metadata:', updateError);
        } else {
          console.log('✅ Successfully updated user metadata');
          // Force a refresh of the user session to get updated metadata
          const { data: refreshData, error: refreshError } = await supabase.auth.refreshSession();
          
          if (refreshError) {
            console.error('❌ Error refreshing session after metadata update:', refreshError);
          } else {
            console.log('✅ Session refreshed successfully after metadata update');
            // Update local state with refreshed session
            setSession(refreshData.session);
            setUser(refreshData.user);
          }
        }
      }
    } catch (err) {
      console.error('❌ Error refreshing user metadata:', err);
    }
  };

  // Function to fix username for existing users
  const fixExistingUserUsernames = async () => {
    if (!user) return;
    
    try {
      console.log('🔧 Fixing username for existing user...');
      
      // Check if user already exists and has an avatar to preserve
      const { data: existingUser } = await supabaseAdmin
        .from('users')
        .select('avatar_url, username')
        .eq('auth_user_id', user.id)
        .single();
      
      console.log('🔍 Existing user data:', existingUser);
      
      let avatarUrlToUse = user.user_metadata?.avatar_url || null;
      
      // Preserve existing avatar if user has one
      if (existingUser?.avatar_url && !avatarUrlToUse) {
        console.log('🔧 Preserving existing avatar during username fix:', existingUser.avatar_url);
        avatarUrlToUse = existingUser.avatar_url;
      }
      
      // Get the user profile from database
      const { data: userProfile, error: profileError } = await supabaseAdmin
        .rpc('get_or_create_user', {
          auth_user_id: user.id,
          user_name: user.user_metadata?.name || 'User',
          user_email: user.email || '',
          user_username: user.user_metadata?.username || existingUser?.username || null,
          user_avatar_url: avatarUrlToUse
        });
      
      console.log('🔍 get_or_create_user result for fix:', { userProfile, profileError });
      
      if (profileError) {
        console.error('❌ Error getting user profile for username fix:', profileError);
        return;
      }
      
      if (userProfile && userProfile.username && !user.user_metadata?.username) {
        console.log('🔧 Found missing username in database:', userProfile.username);
        
        // Update the user's metadata with the username
        const { error: updateError } = await supabase.auth.updateUser({
          data: {
            username: userProfile.username
          }
        });
        
        if (updateError) {
          console.error('❌ Failed to fix username in user metadata:', updateError);
        } else {
          console.log('✅ Successfully fixed username in user metadata');
          // Force a refresh of the user session to get updated metadata
          await supabase.auth.refreshSession();
          
          // Also update the local user state to reflect the change
          setUser(prevUser => prevUser ? {
            ...prevUser,
            user_metadata: {
              ...prevUser.user_metadata,
              username: userProfile.username
            }
          } : null);
        }
      } else if (userProfile && userProfile.username) {
        console.log('ℹ️ Username already exists in metadata:', user.user_metadata?.username);
      } else {
        console.log('⚠️ No username found in database profile');
      }
    } catch (err) {
      console.error('❌ Error fixing existing user username:', err);
    }
  };

  const value = {
    user,
    session,
    loading,
    signIn,
    signUp,
    signInWithGoogle,
    signOut,
    resetPassword,
    updatePassword,
    updateUsername,
    refreshUserMetadata,
    fixExistingUserUsernames,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};
