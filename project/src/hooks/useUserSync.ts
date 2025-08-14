import { useEffect, useState } from 'react';
import { useUser } from '@clerk/clerk-react';
import { upsertUser } from '../lib/supabase';

export const useUserSync = () => {
  const { user, isLoaded } = useUser();
  const [syncStatus, setSyncStatus] = useState<'idle' | 'syncing' | 'success' | 'error'>('idle');
  const [syncError, setSyncError] = useState<string | null>(null);

  useEffect(() => {
    console.log('useUserSync: isLoaded =', isLoaded, 'user =', user);
    
    if (isLoaded && user) {
      console.log('useUserSync: User detected, syncing to Supabase...');
      setSyncStatus('syncing');
      setSyncError(null);
      
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
          
          // Add retry logic for better reliability
          let retryCount = 0;
          const maxRetries = 3;
          
          while (retryCount < maxRetries) {
            try {
              const result = await upsertUser(userData);
              console.log('useUserSync: Upsert result:', result);
              
              if (result) {
                setSyncStatus('success');
                console.log('User synced successfully to Supabase');
                return;
              } else {
                throw new Error('Upsert returned null');
              }
            } catch (error) {
              retryCount++;
              console.error(`useUserSync: Attempt ${retryCount} failed:`, error);
              
              if (retryCount >= maxRetries) {
                throw error;
              }
              
              // Wait before retrying (exponential backoff)
              await new Promise(resolve => setTimeout(resolve, 1000 * retryCount));
            }
          }
        } catch (error) {
          console.error('Error syncing user to Supabase:', error);
          setSyncStatus('error');
          setSyncError(error instanceof Error ? error.message : 'Unknown error occurred');
          
          // Don't throw the error - just log it and continue
          // The app should still work even if sync fails
        }
      };

      syncUser();
    } else if (isLoaded && !user) {
      // User is not authenticated
      setSyncStatus('idle');
      setSyncError(null);
    }
  }, [isLoaded, user]);

  // Function to manually retry sync
  const retrySync = async () => {
    if (!user) return;
    
    setSyncStatus('syncing');
    setSyncError(null);
    
    try {
      const userData = {
        clerk_id: user.id,
        name: user.fullName || user.firstName || user.username || 'User',
        username: user.username || user.emailAddresses[0]?.emailAddress?.split('@')[0] || 'user',
        email: user.emailAddresses[0]?.emailAddress || '',
        image_url: user.imageUrl || undefined,
      };

      const result = await upsertUser(userData);
      
      if (result) {
        setSyncStatus('success');
        console.log('Manual sync successful');
      } else {
        throw new Error('Upsert returned null');
      }
    } catch (error) {
      console.error('Manual sync failed:', error);
      setSyncStatus('error');
      setSyncError(error instanceof Error ? error.message : 'Unknown error occurred');
    }
  };

  return { 
    user, 
    isLoaded, 
    syncStatus, 
    syncError, 
    retrySync,
    isSynced: syncStatus === 'success'
  };
}; 