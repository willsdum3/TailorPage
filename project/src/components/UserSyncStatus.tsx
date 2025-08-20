import React from 'react';
import { CheckCircle, AlertCircle, RefreshCw, Loader2 } from 'lucide-react';

interface UserSyncStatusProps {
  syncStatus: 'idle' | 'syncing' | 'success' | 'error';
  syncError: string | null;
  onRetry: () => void;
  isVisible?: boolean;
  syncAttempts?: number;
}

export const UserSyncStatus: React.FC<UserSyncStatusProps> = ({
  syncStatus,
  syncError,
  onRetry,
  isVisible = false,
  syncAttempts = 0
}) => {
  // Only show error status after multiple attempts to reduce noise
  const shouldShowError = isVisible && syncStatus === 'error' && syncAttempts > 1;
  
  if (!shouldShowError) return null;

  return (
    <div className="fixed top-4 right-4 z-50 max-w-sm bg-red-50 border-red-200 border rounded-lg p-4 shadow-lg">
      <div className="flex items-start space-x-3">
        <div className="flex-shrink-0 text-red-600">
          <AlertCircle className="w-4 h-4" />
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-sm font-medium text-red-600">
            Account sync issue
          </p>
          {syncError && (
            <p className="text-xs text-red-600 mt-1">
              {syncError.includes('timeout') ? 'Connection timeout - please check your internet' : syncError}
            </p>
          )}
          <p className="text-xs text-red-500 mt-1">
            You can still use the app, but some features may be limited.
          </p>
        </div>
        <button
          onClick={onRetry}
          className="flex-shrink-0 p-1 text-red-600 hover:text-red-800 transition-colors"
          title="Retry sync"
        >
          <RefreshCw className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
};

export default UserSyncStatus;

