import React, { useState, useEffect, useRef, useCallback } from 'react';
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

export const BookCover: React.FC<BookCoverProps> = ({
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
  lazy = true
}) => {

  const [coverData, setCoverData] = useState<BookCoverData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [imageLoaded, setImageLoaded] = useState(false);
  const [showPlaceholder, setShowPlaceholder] = useState(false);
  
  const imgRef = useRef<HTMLImageElement>(null);
  const observerRef = useRef<IntersectionObserver | null>(null);

  const loadCover = useCallback(async () => {
    if (!title || !author) return;

    setLoading(true);
    setError(null);

    try {
      const result = await bookCoverService.getBookCover(title, author);
      
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
    } finally {
      setLoading(false);
    }
  }, [title, author, onLoad, onError]);

  // Intersection Observer for lazy loading
  useEffect(() => {
    if (!lazy || priority === 'high') {
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
        rootMargin: '50px',
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
    };
  }, [loadCover, lazy, priority]);

  const handleImageLoad = () => {
    setImageLoaded(true);
    setShowPlaceholder(false);
  };

  const handleImageError = () => {
    console.log('Image failed to load for:', title, 'by', author);
    setError('Failed to load image (CORS or network issue)');
    setShowPlaceholder(true);
    setImageLoaded(false);
  };

  const renderPlaceholder = () => (
    <div className={`${sizeClasses[size]} bg-gradient-to-br from-slate-700 to-slate-800 rounded-lg flex flex-col items-center justify-center border border-white/10 p-2 text-center shadow-lg`}>
      <BookOpen className="w-8 h-8 text-white/50 mb-3" />
      <div className="text-sm text-white/70 font-medium leading-tight mb-1">
        {title.length > 18 ? title.substring(0, 18) + '...' : title}
      </div>
      <div className="text-xs text-white/50 leading-tight">
        by {author.length > 15 ? author.substring(0, 15) + '...' : author}
      </div>
    </div>
  );

  const renderError = () => (
    <div className={`${sizeClasses[size]} bg-gradient-to-br from-red-900/20 to-red-800/20 rounded-lg flex flex-col items-center justify-center border border-red-500/20 p-2 text-center`}>
      <AlertCircle className="w-4 h-4 text-red-400 mb-1" />
      <div className="text-xs text-red-300 font-medium leading-tight">
        {title.length > 18 ? title.substring(0, 18) + '...' : title}
      </div>
      <div className="text-xs text-red-400 leading-tight">
        Cover unavailable
      </div>
    </div>
  );

  const renderSkeleton = () => (
    <div className={`${sizeClasses[size]} bg-gradient-to-br from-slate-600 to-slate-700 rounded-lg animate-pulse flex items-center justify-center`}>
      <Loader2 className="w-6 h-6 text-white/50 animate-spin" />
    </div>
  );

  const renderCover = () => {
    if (loading && !coverData) {
      return renderSkeleton();
    }

    if (error && !coverData) {
      return renderError();
    }

    if (!coverData) {
      return renderPlaceholder();
    }

    return (
      <div className={`${sizeClasses[size]} relative group overflow-hidden rounded-lg shadow-lg transition-all duration-300 hover:shadow-xl`}>
        {/* Progressive loading: Show low-quality placeholder first */}
        {showPlaceholder && (
          <div className="absolute inset-0 bg-gradient-to-br from-slate-700 to-slate-800 flex items-center justify-center">
            <BookOpen className="w-6 h-6 text-white/50" />
          </div>
        )}
        
        {/* Main cover image */}
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
      </div>
    );
  };

  return (
    <div className={`flex flex-col ${className}`}>
      {renderCover()}
      
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
};

// Book Cover Grid Component for displaying multiple covers efficiently
export interface BookCoverGridProps {
  books: Array<{ title: string; author: string; id?: string }>;
  size?: 'sm' | 'md' | 'lg' | 'xl';
  columns?: number;
  className?: string;
  showTitles?: boolean;
  showAuthors?: boolean;
  onCoverLoad?: (bookId: string, coverData: BookCoverData) => void;
  onCoverError?: (bookId: string, error: string) => void;
}

export const BookCoverGrid: React.FC<BookCoverGridProps> = ({
  books,
  size = 'md',
  columns = 4,
  className = '',
  showTitles = false,
  showAuthors = false,
  onCoverLoad,
  onCoverError
}) => {
  const gridCols = {
    2: 'grid-cols-2',
    3: 'grid-cols-3',
    4: 'grid-cols-4',
    5: 'grid-cols-5',
    6: 'grid-cols-6'
  };

  // Preload covers for visible books
  useEffect(() => {
    if (books.length > 0) {
      const bookData = books.map(book => ({ title: book.title, author: book.author }));
      bookCoverService.preloadCovers(bookData).catch(console.warn);
    }
  }, [books]);

  return (
    <div className={`grid gap-4 ${gridCols[columns as keyof typeof gridCols] || 'grid-cols-4'} ${className}`}>
      {books.map((book, index) => (
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
        />
      ))}
    </div>
  );
};

export default BookCover;
