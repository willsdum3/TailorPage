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
  // Show for all sync states when user is loaded and sync is active
  const shouldShow = isVisible && syncStatus !== 'idle';
  
  if (!shouldShow) return null;

  const getStatusConfig = () => {
    switch (syncStatus) {
      case 'syncing':
        return {
          icon: <Loader2 className="w-5 h-5 animate-spin" />,
          text: 'Syncing account to database...',
          color: 'text-blue-600',
          bgColor: 'bg-blue-50',
          borderColor: 'border-blue-200'
        };
      case 'success':
        return {
          icon: <CheckCircle className="w-5 h-5" />,
          text: 'Account synced successfully!',
          color: 'text-green-600',
          bgColor: 'bg-green-50',
          borderColor: 'border-green-200'
        };
      case 'error':
        return {
          icon: <AlertCircle className="w-5 h-5" />,
          text: 'Account sync failed',
          color: 'text-red-600',
          bgColor: 'bg-red-50',
          borderColor: 'border-red-200'
        };
      default:
        return {
          icon: null,
          text: 'Account sync status',
          color: 'text-gray-600',
          bgColor: 'bg-gray-50',
          borderColor: 'border-gray-200'
        };
    }
  };

  const config = getStatusConfig();

  return (
    <div className={`fixed top-4 left-1/2 transform -translate-x-1/2 z-[9999] max-w-md ${config.bgColor} ${config.borderColor} border-2 rounded-lg p-4 shadow-lg`}>
      <div className="flex items-center space-x-3">
        <div className={`flex-shrink-0 ${config.color}`}>
          {config.icon}
        </div>
        <div className="flex-1 min-w-0">
          <p className={`text-sm font-semibold ${config.color}`}>
            {config.text}
          </p>
          {syncError && (
            <p className="text-xs text-red-600 mt-1">
              Error: {syncError.includes('timeout') ? 'Connection timeout - please check your internet' : syncError}
            </p>
          )}
          {syncStatus === 'error' && (
            <p className="text-xs text-red-500 mt-1">
              Attempt {syncAttempts} - You can still use the app, but some features may be limited.
            </p>
          )}
          {syncStatus === 'syncing' && (
            <p className="text-xs text-blue-500 mt-1">
              Please wait while we set up your account...
            </p>
          )}
        </div>
        {syncStatus === 'error' && (
          <button
            onClick={onRetry}
            className="flex-shrink-0 p-2 text-red-600 hover:text-red-800 hover:bg-red-100 rounded-full transition-colors"
            title="Retry sync"
          >
            <RefreshCw className="w-4 h-4" />
          </button>
        )}
      </div>
    </div>
  );
};

export default UserSyncStatus;

