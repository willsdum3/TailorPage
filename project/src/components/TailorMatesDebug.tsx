import React, { useState, useEffect } from 'react';
import { TailorMatesService } from '../services/tailorMatesService';
import { supabase } from '../lib/supabase';

interface TailorMatesDebugProps {
  user: any;
}

export const TailorMatesDebug: React.FC<TailorMatesDebugProps> = ({ user }) => {
  const [debugInfo, setDebugInfo] = useState<any>({});
  const [isLoading, setIsLoading] = useState(false);
  const [hasRun, setHasRun] = useState(false);

  const runDiagnostics = async () => {
    setIsLoading(true);
    const info: any = {};

    try {
      console.log('Starting TailorMatesDebug diagnostics...');
      // Check Supabase connection
      console.log('Testing Supabase connection...');
      const { data: testData, error: testError } = await supabase
        .from('users')
        .select('id')
        .limit(1);
      
      info.supabaseConnection = {
        success: !testError,
        error: testError?.message,
        data: testData
      };

      // Check if user exists in database
      if (user) {
        console.log('Checking user in database...');
        const { data: userData, error: userError } = await supabase
          .from('users')
          .select('*')
          .eq('clerk_id', user.id)
          .single();
        
        info.userInDatabase = {
          exists: !!userData,
          error: userError?.message,
          userData
        };
      }

      // Check if Tailor Mates tables exist
      console.log('Checking Tailor Mates tables...');
      const tables = ['book_clubs', 'club_memberships', 'discussions', 'friend_connections'];
      info.tables = {};

      for (const table of tables) {
        try {
          const { data, error } = await supabase
            .from(table)
            .select('id')
            .limit(1);
          
          info.tables[table] = {
            exists: !error,
            error: error?.message
          };
        } catch (err: any) {
          info.tables[table] = {
            exists: false,
            error: err.message
          };
        }
      }

      // Test Tailor Mates functions
      if (user) {
        console.log('Testing Tailor Mates functions...');
        
        try {
          const clubs = await TailorMatesService.getBookClubs(user.id);
          info.getBookClubs = {
            success: true,
            count: clubs.length,
            data: clubs
          };
        } catch (error: any) {
          info.getBookClubs = {
            success: false,
            error: error.message
          };
        }

        try {
          const discussions = await TailorMatesService.getDiscussions(user.id);
          info.getDiscussions = {
            success: true,
            count: discussions.length,
            data: discussions
          };
        } catch (error: any) {
          info.getDiscussions = {
            success: false,
            error: error.message
          };
        }

        try {
          const connections = await TailorMatesService.getFriendConnections(user.id);
          info.getFriendConnections = {
            success: true,
            count: connections.length,
            data: connections
          };
        } catch (error: any) {
          info.getFriendConnections = {
            success: false,
            error: error.message
          };
        }
      }

      // Check environment variables
      info.environment = {
        supabaseUrl: import.meta.env.VITE_SUPABASE_URL ? 'Set' : 'Missing',
        supabaseAnonKey: import.meta.env.VITE_SUPABASE_ANON_KEY ? 'Set' : 'Missing',
        supabaseServiceKey: import.meta.env.VITE_SUPABASE_SERVICE_KEY ? 'Set' : 'Missing'
      };

    } catch (error: any) {
      info.generalError = error.message;
    }

    setDebugInfo(info);
    setIsLoading(false);
    console.log('Debug info:', info);
  };

  useEffect(() => {
    if (user && !hasRun) {
      runDiagnostics();
      setHasRun(true);
    }
  }, [user, hasRun]);

  return (
    <div className="fixed top-4 left-4 z-[9999] bg-red-900/95 backdrop-blur-xl border-2 border-red-400 rounded-xl p-4 shadow-2xl max-w-md max-h-96 overflow-y-auto">
      <h3 className="text-white font-bold mb-4">🔧 Tailor Mates Debug Panel</h3>
      
      {isLoading ? (
        <div className="text-white">Running diagnostics...</div>
      ) : (
        <div className="space-y-3 text-sm">
          {/* Environment Variables */}
          <div>
            <h4 className="text-white font-semibold">Environment:</h4>
            <div className="text-white/70">
              <div>Supabase URL: {debugInfo.environment?.supabaseUrl}</div>
              <div>Anon Key: {debugInfo.environment?.supabaseAnonKey}</div>
              <div>Service Key: {debugInfo.environment?.supabaseServiceKey}</div>
            </div>
          </div>

          {/* Supabase Connection */}
          <div>
            <h4 className="text-white font-semibold">Supabase Connection:</h4>
            <div className={debugInfo.supabaseConnection?.success ? 'text-green-400' : 'text-red-400'}>
              {debugInfo.supabaseConnection?.success ? '✅ Connected' : '❌ Failed'}
            </div>
            {debugInfo.supabaseConnection?.error && (
              <div className="text-red-400 text-xs">{debugInfo.supabaseConnection.error}</div>
            )}
          </div>

          {/* User in Database */}
          <div>
            <h4 className="text-white font-semibold">User in Database:</h4>
            <div className={debugInfo.userInDatabase?.exists ? 'text-green-400' : 'text-red-400'}>
              {debugInfo.userInDatabase?.exists ? '✅ Found' : '❌ Not Found'}
            </div>
            {debugInfo.userInDatabase?.error && (
              <div className="text-red-400 text-xs">{debugInfo.userInDatabase.error}</div>
            )}
          </div>

          {/* Tables */}
          <div>
            <h4 className="text-white font-semibold">Tables:</h4>
            {debugInfo.tables && Object.entries(debugInfo.tables).map(([table, info]: [string, any]) => (
              <div key={table} className="flex justify-between">
                <span className="text-white/70">{table}:</span>
                <span className={info.exists ? 'text-green-400' : 'text-red-400'}>
                  {info.exists ? '✅' : '❌'}
                </span>
              </div>
            ))}
          </div>

          {/* Functions */}
          <div>
            <h4 className="text-white font-semibold">Functions:</h4>
            {debugInfo.getBookClubs && (
              <div className={debugInfo.getBookClubs.success ? 'text-green-400' : 'text-red-400'}>
                getBookClubs: {debugInfo.getBookClubs.success ? '✅' : '❌'}
                {debugInfo.getBookClubs.error && (
                  <div className="text-red-400 text-xs">{debugInfo.getBookClubs.error}</div>
                )}
              </div>
            )}
            {debugInfo.getDiscussions && (
              <div className={debugInfo.getDiscussions.success ? 'text-green-400' : 'text-red-400'}>
                getDiscussions: {debugInfo.getDiscussions.success ? '✅' : '❌'}
                {debugInfo.getDiscussions.error && (
                  <div className="text-red-400 text-xs">{debugInfo.getDiscussions.error}</div>
                )}
              </div>
            )}
            {debugInfo.getFriendConnections && (
              <div className={debugInfo.getFriendConnections.success ? 'text-green-400' : 'text-red-400'}>
                getFriendConnections: {debugInfo.getFriendConnections.success ? '✅' : '❌'}
                {debugInfo.getFriendConnections.error && (
                  <div className="text-red-400 text-xs">{debugInfo.getFriendConnections.error}</div>
                )}
              </div>
            )}
          </div>

          {/* General Error */}
          {debugInfo.generalError && (
            <div className="text-red-400">
              <h4 className="font-semibold">General Error:</h4>
              <div className="text-xs">{debugInfo.generalError}</div>
            </div>
          )}
        </div>
      )}

             <div className="mt-4 space-y-2">
         <button
           onClick={runDiagnostics}
           className="w-full bg-blue-600 hover:bg-blue-700 text-white px-3 py-2 rounded-lg text-sm"
         >
           Refresh Diagnostics
         </button>
         
         {user && (
           <button
             onClick={async () => {
               try {
                 console.log('Attempting to sync user:', user.id);
                 const { data, error } = await supabase
                   .from('users')
                   .upsert({
                     clerk_id: user.id,
                     name: user.name || 'Unknown',
                     username: user.username || 'unknown',
                     email: user.email || '',
                     image_url: user.imageUrl || null,
                     updated_at: new Date().toISOString()
                   }, {
                     onConflict: 'clerk_id'
                   });
                 
                 if (error) {
                   console.error('User sync error:', error);
                   alert('Failed to sync user: ' + error.message);
                 } else {
                   console.log('User synced successfully:', data);
                   alert('User synced successfully! Please refresh diagnostics.');
                   runDiagnostics();
                 }
               } catch (err: any) {
                 console.error('User sync failed:', err);
                 alert('User sync failed: ' + err.message);
               }
             }}
             className="w-full bg-green-600 hover:bg-green-700 text-white px-3 py-2 rounded-lg text-sm"
           >
             🔄 Sync User Account
           </button>
         )}
       </div>
    </div>
  );
};

export default TailorMatesDebug;
