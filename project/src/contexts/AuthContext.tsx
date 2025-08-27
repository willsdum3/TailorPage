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
        console.log('Getting initial session...');
        const { data: { session }, error } = await supabase.auth.getSession();
        
        if (error) {
          console.error('Error getting initial session:', error);
          // Clear any corrupted session data
          await supabase.auth.signOut();
          setSession(null);
          setUser(null);
          setLoading(false);
          return;
        }
        
        console.log('Initial session:', session?.user?.id);
        setSession(session);
        setUser(session?.user ?? null);
        setLoading(false);
      } catch (err) {
        console.error('Unexpected error getting initial session:', err);
        // Clear session and continue
        await supabase.auth.signOut();
        setSession(null);
        setUser(null);
        setLoading(false);
      }
    };

    // Add timeout protection
    const timeoutId = setTimeout(() => {
      console.warn('Session loading timeout - forcing continue');
      setLoading(false);
    }, 10000); // 10 second timeout

    getInitialSession().finally(() => {
      clearTimeout(timeoutId);
    });

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        console.log('Auth state changed:', event, session?.user?.id);
        
        try {
          // Update session and user state
          setSession(session);
          setUser(session?.user ?? null);
          
          // Handle specific auth events
          if (event === 'SIGNED_IN' && session?.user) {
            console.log('User signed in, ensuring profile exists...');
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
                console.error('Error ensuring user profile exists:', profileError);
              } else {
                console.log('User profile ensured:', userProfile);
              }
            } catch (err) {
              console.error('Unexpected error ensuring user profile:', err);
            }
          } else if (event === 'SIGNED_OUT') {
            console.log('User signed out, state should be cleared by App.tsx useEffect');
          } else if (event === 'USER_UPDATED' && session?.user) {
            console.log('User updated, ensuring profile exists...');
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
                console.error('Error ensuring user profile exists on update:', profileError);
              } else {
                console.log('User profile ensured on update:', userProfile);
              }
            } catch (err) {
              console.error('Unexpected error ensuring user profile on update:', err);
            }
          }
        } catch (err) {
          console.error('Error in auth state change handler:', err);
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
    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
    return { error };
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

      return { error: null };
    } catch (err) {
      console.error('Unexpected error during signup:', err);
      return { error: err };
    }
  };

  const signOut = async () => {
    try {
      console.log('Starting signout process...');
      
      // Clear local state first to prevent flickering
      setUser(null);
      setSession(null);
      
      // Sign out from Supabase
      const { error } = await supabase.auth.signOut();
      
      if (error) {
        console.error('Error during signout:', error);
      } else {
        console.log('Signout successful');
      }
      
      setLoading(false);
    } catch (err) {
      console.error('Unexpected error during signout:', err);
      // Ensure state is cleared even on error
      setUser(null);
      setSession(null);
      setLoading(false);
    }
  };

  const resetPassword = async (email: string) => {
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/reset-password`,
    });
    return { error };
  };

  const value = {
    user,
    session,
    loading,
    signIn,
    signUp,
    signOut,
    resetPassword,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};
