import { useEffect } from 'react';
import { useUser } from '@clerk/clerk-react';
import { upsertUser } from '../lib/supabase';

export const useUserSync = () => {
  const { user, isLoaded } = useUser();

  useEffect(() => {
    console.log('useUserSync: isLoaded =', isLoaded, 'user =', user);
    
    if (isLoaded && user) {
      console.log('useUserSync: User detected, syncing to Supabase...');
      // Sync user data to Supabase when user is loaded
      const syncUser = async () => {
        try {
          const userData = {
            clerk_id: user.id,
            name: user.fullName || user.firstName || user.username || 'User',
            username: user.username || user.emailAddresses[0]?.emailAddress?.split('@')[0] || 'user',
            email: user.emailAddresses[0]?.emailAddress || '',
            image_url: user.imageUrl || undefined,
          };

          console.log('useUserSync: User data to sync:', userData);
          const result = await upsertUser(userData);
          console.log('useUserSync: Upsert result:', result);
        } catch (error) {
          console.error('Error syncing user to Supabase:', error);
        }
      };

      syncUser();
    }
  }, [isLoaded, user]);

  return { user, isLoaded };
}; 