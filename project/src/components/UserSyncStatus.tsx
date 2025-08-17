import React from 'react';
import { CheckCircle, AlertCircle, RefreshCw, Loader2 } from 'lucide-react';

interface UserSyncStatusProps {
  syncStatus: 'idle' | 'syncing' | 'success' | 'error';
  syncError: string | null;
  onRetry: () => void;
  isVisible?: boolean;
}

export const UserSyncStatus: React.FC<UserSyncStatusProps> = ({
  syncStatus,
  syncError,
  onRetry,
  isVisible = false
}) => {
  if (!isVisible) return null;

  const getStatusConfig = () => {
    switch (syncStatus) {
      case 'syncing':
        return {
          icon: <Loader2 className="w-4 h-4 animate-spin" />,
          text: 'Syncing account...',
          color: 'text-blue-500',
          bgColor: 'bg-blue-50',
          borderColor: 'border-blue-200'
        };
      case 'success':
        return {
          icon: <CheckCircle className="w-4 h-4" />,
          text: 'Account synced successfully',
          color: 'text-green-600',
          bgColor: 'bg-green-50',
          borderColor: 'border-green-200'
        };
      case 'error':
        return {
          icon: <AlertCircle className="w-4 h-4" />,
          text: 'Sync failed',
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
    <div className={`fixed top-4 right-4 z-50 max-w-sm ${config.bgColor} ${config.borderColor} border rounded-lg p-4 shadow-lg`}>
      <div className="flex items-start space-x-3">
        <div className={`flex-shrink-0 ${config.color}`}>
          {config.icon}
        </div>
        <div className="flex-1 min-w-0">
          <p className={`text-sm font-medium ${config.color}`}>
            {config.text}
          </p>
          {syncError && (
            <p className="text-xs text-red-600 mt-1">
              {syncError}
            </p>
          )}
        </div>
        {syncStatus === 'error' && (
          <button
            onClick={onRetry}
            className="flex-shrink-0 p-1 text-red-600 hover:text-red-800 transition-colors"
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

