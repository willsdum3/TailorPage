import React, { useState, useEffect } from 'react';
import { BookCover, BookCoverGrid } from './BookCover';
import { useBookCovers } from '../hooks/useBookCovers';
import { bookCoverService } from '../services/bookCoverService';
import { BookCoverData } from '../services/bookCoverService';
import { 
  Settings, 
  RefreshCw, 
  Trash2, 
  Download, 
  Upload, 
  BarChart3, 
  Zap,
  AlertCircle,
  CheckCircle,
  Clock,
  HardDrive,
  Wifi,
  WifiOff
} from 'lucide-react';

export interface BookCoverManagerProps {
  books: Array<{ title: string; author: string; id?: string }>;
  size?: 'sm' | 'md' | 'lg' | 'xl';
  showAdminControls?: boolean;
  showStats?: boolean;
  className?: string;
  onCoverLoad?: (bookId: string, coverData: BookCoverData) => void;
  onCoverError?: (bookId: string, error: string) => void;
}

export const BookCoverManager: React.FC<BookCoverManagerProps> = ({
  books,
  size = 'md',
  showAdminControls = false,
  showStats = false,
  className = '',
  onCoverLoad,
  onCoverError
}) => {
  const [isAdminMode, setIsAdminMode] = useState(false);
  const [showCacheStats, setShowCacheStats] = useState(false);
  const [isOnline, setIsOnline] = useState(navigator.onLine);
  const [cacheStats, setCacheStats] = useState<any>(null);
  const [loadingState, setLoadingState] = useState<'idle' | 'loading' | 'success' | 'error'>('idle');

  const {
    coverState,
    loadCovers,
    preloadCovers,
    clearAllCovers,
    getCacheStats,
    isLoading
  } = useBookCovers({
    preloadCount: 8,
    enableCache: true,
    retryAttempts: 3,
    retryDelay: 1000,
    onCoverLoad,
    onCoverError
  });

  // Monitor online/offline status
  useEffect(() => {
    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  // Update cache stats periodically
  useEffect(() => {
    const updateStats = () => {
      const stats = getCacheStats();
      const serviceStats = bookCoverService.getCacheStats();
      setCacheStats({ ...stats, serviceStats });
    };

    updateStats();
    const interval = setInterval(updateStats, 5000);

    return () => clearInterval(interval);
  }, [getCacheStats]);

  // Load covers when books change
  useEffect(() => {
    if (books.length > 0) {
      loadCovers(books);
    }
  }, [books, loadCovers]);

  const handleRefreshAll = async () => {
    setLoadingState('loading');
    try {
      await loadCovers(books);
      setLoadingState('success');
      setTimeout(() => setLoadingState('idle'), 2000);
    } catch (error) {
      setLoadingState('error');
      setTimeout(() => setLoadingState('idle'), 3000);
    }
  };

  const handlePreloadAll = async () => {
    setLoadingState('loading');
    try {
      await preloadCovers(books);
      setLoadingState('success');
      setTimeout(() => setLoadingState('idle'), 2000);
    } catch (error) {
      setLoadingState('error');
      setTimeout(() => setLoadingState('idle'), 3000);
    }
  };

  const handleClearCache = () => {
    clearAllCovers();
    bookCoverService.clearCache();
  };

  const getLoadingStateIcon = () => {
    switch (loadingState) {
      case 'loading':
        return <RefreshCw className="w-4 h-4 animate-spin" />;
      case 'success':
        return <CheckCircle className="w-4 h-4 text-green-500" />;
      case 'error':
        return <AlertCircle className="w-4 h-4 text-red-500" />;
      default:
        return <RefreshCw className="w-4 h-4" />;
    }
  };

  const renderAdminControls = () => (
    <div className="bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl p-4 mb-6">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-white flex items-center space-x-2">
          <Settings className="w-5 h-5" />
          <span>Cover Management</span>
        </h3>
        <div className="flex items-center space-x-2">
          {isOnline ? (
            <Wifi className="w-4 h-4 text-green-400" />
          ) : (
            <WifiOff className="w-4 h-4 text-red-400" />
          )}
          <span className="text-sm text-white/70">
            {isOnline ? 'Online' : 'Offline'}
          </span>
        </div>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        <button
          onClick={handleRefreshAll}
          disabled={isLoading || loadingState === 'loading'}
          className="flex items-center justify-center space-x-2 bg-amber-500 hover:bg-amber-600 disabled:bg-amber-500/50 text-white px-3 py-2 rounded-lg text-sm font-medium transition-all duration-200"
        >
          {getLoadingStateIcon()}
          <span>Refresh All</span>
        </button>

        <button
          onClick={handlePreloadAll}
          disabled={isLoading || loadingState === 'loading'}
          className="flex items-center justify-center space-x-2 bg-blue-500 hover:bg-blue-600 disabled:bg-blue-500/50 text-white px-3 py-2 rounded-lg text-sm font-medium transition-all duration-200"
        >
          <Download className="w-4 h-4" />
          <span>Preload All</span>
        </button>

        <button
          onClick={handleClearCache}
          className="flex items-center justify-center space-x-2 bg-red-500 hover:bg-red-600 text-white px-3 py-2 rounded-lg text-sm font-medium transition-all duration-200"
        >
          <Trash2 className="w-4 h-4" />
          <span>Clear Cache</span>
        </button>

        <button
          onClick={() => setShowCacheStats(!showCacheStats)}
          className="flex items-center justify-center space-x-2 bg-purple-500 hover:bg-purple-600 text-white px-3 py-2 rounded-lg text-sm font-medium transition-all duration-200"
        >
          <BarChart3 className="w-4 h-4" />
          <span>Stats</span>
        </button>
      </div>
    </div>
  );

  const renderCacheStats = () => (
    <div className="bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl p-4 mb-6">
      <h3 className="text-lg font-semibold text-white mb-4 flex items-center space-x-2">
        <BarChart3 className="w-5 h-5" />
        <span>Cache Statistics</span>
      </h3>

      {cacheStats && (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="bg-white/5 rounded-lg p-3">
            <div className="flex items-center space-x-2 mb-1">
              <HardDrive className="w-4 h-4 text-blue-400" />
              <span className="text-sm text-white/70">Total Covers</span>
            </div>
            <div className="text-2xl font-bold text-white">{cacheStats.total}</div>
          </div>

          <div className="bg-white/5 rounded-lg p-3">
            <div className="flex items-center space-x-2 mb-1">
              <Zap className="w-4 h-4 text-green-400" />
              <span className="text-sm text-white/70">Cached</span>
            </div>
            <div className="text-2xl font-bold text-white">{cacheStats.cached}</div>
          </div>

          <div className="bg-white/5 rounded-lg p-3">
            <div className="flex items-center space-x-2 mb-1">
              <Clock className="w-4 h-4 text-yellow-400" />
              <span className="text-sm text-white/70">Loading</span>
            </div>
            <div className="text-2xl font-bold text-white">{cacheStats.loading}</div>
          </div>

          <div className="bg-white/5 rounded-lg p-3">
            <div className="flex items-center space-x-2 mb-1">
              <AlertCircle className="w-4 h-4 text-red-400" />
              <span className="text-sm text-white/70">Errors</span>
            </div>
            <div className="text-2xl font-bold text-white">{cacheStats.errors}</div>
          </div>
        </div>
      )}

      {cacheStats && (
        <div className="mt-4 bg-white/5 rounded-lg p-3">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm text-white/70">Cache Hit Rate</span>
            <span className="text-sm font-medium text-white">{cacheStats.hitRate.toFixed(1)}%</span>
          </div>
          <div className="w-full bg-white/20 rounded-full h-2">
            <div 
              className="bg-gradient-to-r from-green-400 to-blue-500 h-2 rounded-full transition-all duration-500"
              style={{ width: `${Math.min(cacheStats.hitRate, 100)}%` }}
            />
          </div>
        </div>
      )}
    </div>
  );

  const renderCoverGrid = () => (
    <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
      {books.map((book, index) => (
        <div key={book.id || `${book.title}-${book.author}-${index}`} className="relative">
          <BookCover
            title={book.title}
            author={book.author}
            size={size}
            showTitle={true}
            showAuthor={true}
            priority={index < 8 ? 'high' : 'low'}
            onLoad={(coverData) => onCoverLoad?.(book.id || book.title, coverData)}
            onError={(error) => onCoverError?.(book.id || book.title, error)}
            lazy={index >= 4}
          />
          
          {isAdminMode && (
            <div className="absolute top-2 right-2 bg-black/50 rounded-lg p-1">
              <span className="text-xs text-white">
                {coverState[`${book.title.toLowerCase().replace(/[^a-z0-9]/g, '')}-${book.author.toLowerCase().replace(/[^a-z0-9]/g, '')}`]?.source || 'pending'}
              </span>
            </div>
          )}
        </div>
      ))}
    </div>
  );

  return (
    <div className={className}>
      {/* Admin Controls */}
      {showAdminControls && (
        <div className="mb-6">
          <button
            onClick={() => setIsAdminMode(!isAdminMode)}
            className="flex items-center space-x-2 bg-white/10 hover:bg-white/20 text-white px-4 py-2 rounded-lg transition-all duration-200"
          >
            <Settings className="w-4 h-4" />
            <span>{isAdminMode ? 'Hide' : 'Show'} Admin Controls</span>
          </button>
        </div>
      )}

      {/* Admin Panel */}
      {isAdminMode && renderAdminControls()}

      {/* Cache Statistics */}
      {showCacheStats && renderCacheStats()}

      {/* Cover Grid */}
      {renderCoverGrid()}

      {/* Loading Indicator */}
      {isLoading && (
        <div className="fixed bottom-4 right-4 bg-white/10 backdrop-blur-sm border border-white/20 rounded-lg p-3 flex items-center space-x-2">
          <RefreshCw className="w-4 h-4 animate-spin text-white" />
          <span className="text-sm text-white">Loading covers...</span>
        </div>
      )}
    </div>
  );
};

export default BookCoverManager;
