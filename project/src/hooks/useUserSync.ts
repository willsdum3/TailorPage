import { useEffect, useState } from 'react';
import { useUser } from '@clerk/clerk-react';
import { upsertUser } from '../lib/supabase';

export const useUserSync = () => {
  const { user, isLoaded } = useUser();
  const [syncStatus, setSyncStatus] = useState<'idle' | 'syncing' | 'success' | 'error'>('idle');
  const [syncError, setSyncError] = useState<string | null>(null);
  const [syncAttempts, setSyncAttempts] = useState(0);

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
          
          // Optimized retry logic with shorter timeouts
          let retryCount = 0;
          const maxRetries = 2; // Reduced from 3 to 2
          
          while (retryCount < maxRetries) {
            try {
              // Add timeout to prevent hanging
              const timeoutPromise = new Promise((_, reject) => 
                setTimeout(() => reject(new Error('Sync timeout')), 5000)
              );
              
              const syncPromise = upsertUser(userData);
              const result = await Promise.race([syncPromise, timeoutPromise]);
              
              console.log('useUserSync: Upsert result:', result);
              
              if (result) {
                setSyncStatus('success');
                setSyncAttempts(0);
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
              
              // Shorter wait time between retries
              await new Promise(resolve => setTimeout(resolve, 500 * retryCount));
            }
          }
        } catch (error) {
          console.error('Error syncing user to Supabase:', error);
          setSyncStatus('error');
          setSyncError(error instanceof Error ? error.message : 'Unknown error occurred');
          setSyncAttempts(prev => prev + 1);
          
          // Auto-retry after 10 seconds if this is the first error
          if (syncAttempts === 0) {
            setTimeout(() => {
              if (user) {
                console.log('Auto-retrying sync...');
                setSyncStatus('syncing');
                setSyncError(null);
                syncUser();
              }
            }, 10000);
          }
        }
      };

      // Start sync immediately
      syncUser();
    } else if (isLoaded && !user) {
      // User is not authenticated
      setSyncStatus('idle');
      setSyncError(null);
      setSyncAttempts(0);
    }
  }, [isLoaded, user, syncAttempts]);

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

      // Add timeout to manual retry
      const timeoutPromise = new Promise((_, reject) => 
        setTimeout(() => reject(new Error('Sync timeout')), 5000)
      );
      
      const syncPromise = upsertUser(userData);
      const result = await Promise.race([syncPromise, timeoutPromise]);
      
      if (result) {
        setSyncStatus('success');
        setSyncAttempts(0);
        console.log('Manual sync successful');
      } else {
        throw new Error('Upsert returned null');
      }
    } catch (error) {
      console.error('Manual sync failed:', error);
      setSyncStatus('error');
      setSyncError(error instanceof Error ? error.message : 'Unknown error occurred');
      setSyncAttempts(prev => prev + 1);
    }
  };

  return { 
    user, 
    isLoaded, 
    syncStatus, 
    syncError, 
    retrySync,
    isSynced: syncStatus === 'success',
    syncAttempts
  };
}; 