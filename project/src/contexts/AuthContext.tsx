import React, { createContext, useContext, useEffect, useState } from 'react';
import { User, Session } from '@supabase/supabase-js';
import { supabase, supabaseAdmin } from '../lib/supabase';

interface AuthContextType {
  user: User | null;
  session: Session | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<{ error: any }>;
  signUp: (email: string, password: string, userData: { name: string; username: string }) => Promise<{ error: any }>;
  signOut: () => Promise<void>;
  resetPassword: (email: string) => Promise<{ error: any }>;
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
                 const { data: userProfile, error: profileError } = await supabaseAdmin
                   .rpc('get_or_create_user', {
                     auth_user_id: session.user.id,
                     user_name: session.user.user_metadata?.name || 'User',
                     user_email: session.user.email || '',
                     user_username: session.user.user_metadata?.username || null,
                     user_avatar_url: session.user.user_metadata?.avatar_url || null
                   });

                 if (profileError) {
                   console.error('❌ Error ensuring user profile exists:', profileError);
                 } else {
                   console.log('✅ User profile ensured:', userProfile);
                   
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
                 }
               } catch (err) {
                 console.error('❌ Unexpected error ensuring user profile:', err);
               }
             };
             
             // Run profile creation in background without blocking signin
             ensureProfile().catch(err => {
               console.log('⚠️ Profile creation failed, but signin continues:', err);
             });
           } else if (event === 'SIGNED_OUT') {
            console.log('🚪 User signed out event detected - letting signOut function handle state clearing');
          } else if (event === 'USER_UPDATED' && session?.user) {
            console.log('🔄 User updated, ensuring profile exists...');
            console.log('🔄 Updated user metadata:', session.user.user_metadata);
            try {
              const { data: userProfile, error: profileError } = await supabaseAdmin
                .rpc('get_or_create_user', {
                  auth_user_id: session.user.id,
                  user_name: session.user.user_metadata?.name || 'User',
                  user_email: session.user.email || '',
                  user_username: session.user.user_metadata?.username || null,
                  user_avatar_url: session.user.user_metadata?.avatar_url || null
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

  const signIn = async (email: string, password: string) => {
    try {
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
      
      // Small delay to ensure state is cleared before signout
      await new Promise(resolve => setTimeout(resolve, 100));
      
      // Sign out from Supabase
      const { error } = await supabase.auth.signOut();
      
      if (error) {
        console.error('❌ Error during signout:', error);
        // Don't throw error, just log it and continue
        console.log('⚠️ Continuing with signout despite error');
      } else {
        console.log('✅ Supabase signout successful');
      }
      
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

  const resetPassword = async (email: string) => {
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/reset-password`,
    });
    return { error };
  };

  const refreshUserMetadata = async () => {
    if (!user) return;
    
    try {
      console.log('🔄 Refreshing user metadata...');
      
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
          await supabase.auth.refreshSession();
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
      
      // Get the user profile from database
      const { data: userProfile, error: profileError } = await supabaseAdmin
        .rpc('get_or_create_user', {
          auth_user_id: user.id,
          user_name: user.user_metadata?.name || 'User',
          user_email: user.email || '',
          user_username: null, // Don't create new username, just get existing
          user_avatar_url: user.user_metadata?.avatar_url || null
        });
      
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
    signOut,
    resetPassword,
    refreshUserMetadata,
    fixExistingUserUsernames,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};
