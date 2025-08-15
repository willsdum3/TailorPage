import React, { useState, useEffect, useRef, useCallback, useMemo } from 'react';
import { BookCoverData, bookCoverService } from '../services/bookCoverService';
import { Loader2, BookOpen, AlertCircle } from 'lucide-react';

export interface BookCoverProps {
  title: string;
  author: string;
  size?: 'sm' | 'md' | 'lg' | 'xl';
  className?: string;
  showTitle?: boolean;
  showAuthor?: boolean;
  priority?: 'high' | 'low';
  onLoad?: (coverData: BookCoverData) => void;
  onError?: (error: string) => void;
  fallbackCover?: string;
  lazy?: boolean;
  preload?: boolean;
  onClick?: () => void;
  clickable?: boolean;
}

const sizeClasses = {
  sm: 'w-16 h-24',
  md: 'w-24 h-36',
  lg: 'w-32 h-48',
  xl: 'w-40 h-60'
};

const textSizes = {
  sm: 'text-xs',
  md: 'text-sm',
  lg: 'text-base',
  xl: 'text-lg'
};

// Performance optimization: Memoized placeholder component
const PlaceholderCover = React.memo<{ title: string; author: string; size: keyof typeof sizeClasses }>(
  ({ title, author, size }) => (
    <div className={`${sizeClasses[size]} bg-gradient-to-br from-slate-700 to-slate-800 rounded-lg flex flex-col items-center justify-center border border-white/10 p-2 text-center shadow-lg`}>
      <BookOpen className="w-8 h-8 text-white/50 mb-3" />
      <div className="text-sm text-white/70 font-medium leading-tight mb-1">
        {title.length > 18 ? title.substring(0, 18) + '...' : title}
      </div>
      <div className="text-xs text-white/50 leading-tight">
        by {author.length > 15 ? author.substring(0, 15) + '...' : author}
      </div>
    </div>
  )
);

// Performance optimization: Memoized error component
const ErrorCover = React.memo<{ title: string; size: keyof typeof sizeClasses }>(
  ({ title, size }) => (
    <div className={`${sizeClasses[size]} bg-gradient-to-br from-red-900/20 to-red-800/20 rounded-lg flex flex-col items-center justify-center border border-red-500/20 p-2 text-center`}>
      <AlertCircle className="w-4 h-4 text-red-400 mb-1" />
      <div className="text-xs text-red-300 font-medium leading-tight">
        {title.length > 18 ? title.substring(0, 18) + '...' : title}
      </div>
      <div className="text-xs text-red-400 leading-tight">
        Cover unavailable
      </div>
    </div>
  )
);

// Performance optimization: Memoized skeleton component
const SkeletonCover = React.memo<{ size: keyof typeof sizeClasses }>(
  ({ size }) => (
    <div className={`${sizeClasses[size]} bg-gradient-to-br from-slate-600 to-slate-700 rounded-lg animate-pulse flex items-center justify-center`}>
      <Loader2 className="w-6 h-6 text-white/50 animate-spin" />
    </div>
  )
);

export const BookCover: React.FC<BookCoverProps> = React.memo(({
  title,
  author,
  size = 'md',
  className = '',
  showTitle = false,
  showAuthor = false,
  priority = 'low',
  onLoad,
  onError,
  fallbackCover,
  lazy = true,
  preload = false,
  onClick,
  clickable = false
}) => {
  const [coverData, setCoverData] = useState<BookCoverData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [imageLoaded, setImageLoaded] = useState(false);
  const [showPlaceholder, setShowPlaceholder] = useState(false);
  const [retryCount, setRetryCount] = useState(0);
  
  const imgRef = useRef<HTMLImageElement>(null);
  const observerRef = useRef<IntersectionObserver | null>(null);
  const loadTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  // Memoize cache key to prevent unnecessary re-renders
  const cacheKey = useMemo(() => `${title}-${author}`, [title, author]);

  const loadCover = useCallback(async () => {
    if (!title || !author) return;

    setLoading(true);
    setError(null);

    try {
      // Add timeout for better UX
      const timeoutPromise = new Promise<never>((_, reject) => {
        loadTimeoutRef.current = setTimeout(() => reject(new Error('Request timeout')), 15000);
      });

      const result = await Promise.race([
        bookCoverService.getBookCover(title, author),
        timeoutPromise
      ]);
      
      if (loadTimeoutRef.current) {
        clearTimeout(loadTimeoutRef.current);
        loadTimeoutRef.current = null;
      }
      
      if (result.success && result.data) {
        setCoverData(result.data);
        onLoad?.(result.data);
      } else {
        throw new Error(result.error || 'Failed to load cover');
      }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error';
      console.log('BookCover error for:', title, 'by', author, ':', errorMessage);
      setError(errorMessage);
      onError?.(errorMessage);
      setShowPlaceholder(true);
      
      // Retry logic for transient errors
      if (retryCount < 2 && (errorMessage.includes('timeout') || errorMessage.includes('network'))) {
        setRetryCount(prev => prev + 1);
        setTimeout(() => loadCover(), 1000 * (retryCount + 1));
      }
    } finally {
      setLoading(false);
    }
  }, [title, author, onLoad, onError, retryCount]);

  // Preload logic
  useEffect(() => {
    if (preload && priority === 'high') {
      loadCover();
    }
  }, [preload, priority, loadCover]);

  // Intersection Observer for lazy loading with improved performance
  useEffect(() => {
    if (!lazy || priority === 'high' || preload) {
      loadCover();
      return;
    }

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            loadCover();
            observer.unobserve(entry.target);
          }
        });
      },
      {
        rootMargin: '100px', // Increased margin for better preloading
        threshold: 0.1
      }
    );

    observerRef.current = observer;

    if (imgRef.current) {
      observer.observe(imgRef.current);
    }

    return () => {
      if (observerRef.current) {
        observerRef.current.disconnect();
      }
      if (loadTimeoutRef.current) {
        clearTimeout(loadTimeoutRef.current);
      }
    };
  }, [loadCover, lazy, priority, preload]);

  const handleImageLoad = useCallback(() => {
    setImageLoaded(true);
    setShowPlaceholder(false);
  }, []);

  const handleImageError = useCallback(() => {
    console.log('Image failed to load for:', title, 'by', author);
    setError('Failed to load image (CORS or network issue)');
    setShowPlaceholder(true);
    setImageLoaded(false);
  }, [title, author]);

  // Memoized render functions for better performance
  const renderCover = useMemo(() => {
    if (loading && !coverData) {
      return <SkeletonCover size={size} />;
    }

    if (error && !coverData) {
      return <ErrorCover title={title} size={size} />;
    }

    if (!coverData) {
      return <PlaceholderCover title={title} author={author} size={size} />;
    }

    return (
      <div 
        className={`${sizeClasses[size]} relative group overflow-hidden rounded-lg shadow-lg transition-all duration-300 hover:shadow-xl ${
          clickable ? 'cursor-pointer hover:scale-105' : ''
        }`}
        onClick={clickable && onClick ? onClick : undefined}
        role={clickable ? 'button' : undefined}
        tabIndex={clickable ? 0 : undefined}
        onKeyDown={clickable && onClick ? (e) => {
          if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault();
            onClick();
          }
        } : undefined}
      >
        {/* Progressive loading: Show low-quality placeholder first */}
        {showPlaceholder && (
          <div className="absolute inset-0 bg-gradient-to-br from-slate-700 to-slate-800 flex items-center justify-center">
            <BookOpen className="w-6 h-6 text-white/50" />
          </div>
        )}
        
        {/* Main cover image with optimized loading */}
        <img
          ref={imgRef}
          src={coverData.coverUrl}
          alt={`Cover of ${title} by ${author}`}
          className={`w-full h-full object-cover transition-opacity duration-300 ${
            imageLoaded ? 'opacity-100' : 'opacity-0'
          }`}
          onLoad={handleImageLoad}
          onError={handleImageError}
          loading={lazy ? 'lazy' : 'eager'}
          decoding="async"
          fetchPriority={priority === 'high' ? 'high' : 'auto'}
        />
        
        {/* Loading overlay */}
        {loading && (
          <div className="absolute inset-0 bg-black/20 flex items-center justify-center">
            <Loader2 className="w-4 h-4 text-white animate-spin" />
          </div>
        )}
        
        {/* Quality indicator */}
        {coverData.quality === 'high' && (
          <div className="absolute top-1 right-1 bg-green-500 text-white text-xs px-1 py-0.5 rounded opacity-0 group-hover:opacity-100 transition-opacity duration-200">
            HD
          </div>
        )}
        
        {/* Source indicator */}
        <div className="absolute bottom-1 left-1 bg-black/50 text-white text-xs px-1 py-0.5 rounded opacity-0 group-hover:opacity-100 transition-opacity duration-200">
          {coverData.source}
        </div>
        
        {/* Click indicator for clickable covers */}
        {clickable && (
          <div className="absolute inset-0 bg-black/0 group-hover:bg-black/20 transition-all duration-200 flex items-center justify-center">
            <div className="opacity-0 group-hover:opacity-100 transition-opacity duration-200 bg-white/20 backdrop-blur-sm rounded-full p-2">
              <BookOpen className="w-4 h-4 text-white" />
            </div>
          </div>
        )}
      </div>
    );
  }, [loading, coverData, error, title, author, size, showPlaceholder, imageLoaded, lazy, priority, handleImageLoad, handleImageError]);

  return (
    <div className={`flex flex-col ${className}`}>
      {renderCover}
      
      {/* Title and Author */}
      {(showTitle || showAuthor) && (
        <div className="mt-2 text-center">
          {showTitle && (
            <h3 className={`font-semibold text-white line-clamp-2 ${textSizes[size]}`}>
              {title}
            </h3>
          )}
          {showAuthor && (
            <p className={`text-white/70 mt-1 line-clamp-1 ${textSizes[size]}`}>
              by {author}
            </p>
          )}
        </div>
      )}
    </div>
  );
});

BookCover.displayName = 'BookCover';

// Enhanced Book Cover Grid Component with virtual scrolling support
export interface BookCoverGridProps {
  books: Array<{ title: string; author: string; id?: string }>;
  size?: 'sm' | 'md' | 'lg' | 'xl';
  columns?: number;
  className?: string;
  showTitles?: boolean;
  showAuthors?: boolean;
  onCoverLoad?: (bookId: string, coverData: BookCoverData) => void;
  onCoverError?: (bookId: string, error: string) => void;
  virtualScroll?: boolean;
  pageSize?: number;
}

export const BookCoverGrid: React.FC<BookCoverGridProps> = React.memo(({
  books,
  size = 'md',
  columns = 4,
  className = '',
  showTitles = false,
  showAuthors = false,
  onCoverLoad,
  onCoverError,
  virtualScroll = false,
  pageSize = 20
}) => {
  const [visibleBooks, setVisibleBooks] = useState(books.slice(0, pageSize));
  const [currentPage, setCurrentPage] = useState(1);

  const gridCols = {
    2: 'grid-cols-2',
    3: 'grid-cols-3',
    4: 'grid-cols-4',
    5: 'grid-cols-5',
    6: 'grid-cols-6'
  };

  // Optimized preloading with batching
  useEffect(() => {
    if (books.length > 0) {
      const bookData = books.slice(0, 12).map(book => ({ title: book.title, author: book.author }));
      bookCoverService.preloadCovers(bookData).catch(console.warn);
    }
  }, [books]);

  // Virtual scrolling implementation
  useEffect(() => {
    if (!virtualScroll) {
      setVisibleBooks(books);
      return;
    }

    const startIndex = (currentPage - 1) * pageSize;
    const endIndex = startIndex + pageSize;
    setVisibleBooks(books.slice(startIndex, endIndex));
  }, [books, currentPage, pageSize, virtualScroll]);

  const loadMoreBooks = useCallback(() => {
    if (virtualScroll && currentPage * pageSize < books.length) {
      setCurrentPage(prev => prev + 1);
    }
  }, [virtualScroll, currentPage, pageSize, books.length]);

  return (
    <div className="space-y-4">
      <div className={`grid gap-4 ${gridCols[columns as keyof typeof gridCols] || 'grid-cols-4'} ${className}`}>
        {visibleBooks.map((book, index) => (
          <BookCover
            key={book.id || `${book.title}-${book.author}-${index}`}
            title={book.title}
            author={book.author}
            size={size}
            showTitle={showTitles}
            showAuthor={showAuthors}
            priority={index < 8 ? 'high' : 'low'} // Prioritize first 8 covers
            onLoad={(coverData) => onCoverLoad?.(book.id || book.title, coverData)}
            onError={(error) => onCoverError?.(book.id || book.title, error)}
            lazy={index >= 4} // Lazy load after first 4
            preload={index < 4} // Preload first 4
          />
        ))}
      </div>
      
      {/* Load more button for virtual scrolling */}
      {virtualScroll && currentPage * pageSize < books.length && (
        <div className="flex justify-center mt-6">
          <button
            onClick={loadMoreBooks}
            className="px-6 py-2 bg-gradient-to-r from-amber-500 to-orange-600 text-white rounded-lg hover:from-amber-600 hover:to-orange-700 transition-all duration-300"
          >
            Load More Books
          </button>
        </div>
      )}
    </div>
  );
});

BookCoverGrid.displayName = 'BookCoverGrid';

export default BookCover;
