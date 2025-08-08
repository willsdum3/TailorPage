import React, { useState, useEffect } from 'react';
import { Book } from 'lucide-react';
import { getBookCover } from '../utils/bookCoverService';
import { getGuaranteedCover } from '../utils/bookCoverFallback';

interface BookCoverProps {
  bookId: string;
  title: string;
  author: string;
  size?: 'sm' | 'md' | 'lg';
  className?: string;
  showFallback?: boolean;
  genre?: string;
  description?: string;
  amazonLink?: string;
  hoverable?: boolean;
  coverImage?: string;
}

const sizeClasses = {
  sm: 'w-12 h-16',
  md: 'w-16 h-20',
  lg: 'w-20 h-24'
};

const BookCover: React.FC<BookCoverProps> = ({ 
  bookId, 
  title, 
  author, 
  size = 'md', 
  className = '',
  showFallback = true,
  genre,
  description,
  amazonLink,
  hoverable = true,
  coverImage
}) => {
  const [coverUrl, setCoverUrl] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [hasError, setHasError] = useState(false);
  const [apiKeyMissing, setApiKeyMissing] = useState(false);
  const [retryCount, setRetryCount] = useState(0);

  useEffect(() => {
    let isMounted = true;

    const loadCover = async () => {
      try {
        setIsLoading(true);
        setHasError(false);
        setApiKeyMissing(false);
        
        // If coverImage is provided, use it directly
        if (coverImage) {
          if (isMounted) {
            setCoverUrl(coverImage);
            setIsLoading(false);
          }
          return;
        }
        
        // Check if Google Books API key is configured
        const googleBooksApiKey = import.meta.env.VITE_GOOGLE_BOOKS_API_KEY;
        if (!googleBooksApiKey) {
          console.warn('Google Books API key not configured. Using OpenLibrary fallback only.');
          setApiKeyMissing(true);
        }
        
        // Otherwise, fetch from service with guaranteed fallback
        const url = await getGuaranteedCover(bookId, title, author, getBookCover);
        
        if (isMounted) {
          setCoverUrl(url);
          setIsLoading(false);
        }
      } catch (error) {
        console.error('Error loading book cover:', error);
        if (isMounted) {
          setHasError(true);
          setIsLoading(false);
        }
      }
    };

    loadCover();

    return () => {
      isMounted = false;
    };
  }, [bookId, title, author, coverImage]);

  // Clear cover URL when bookId changes to prevent stale covers
  useEffect(() => {
    setCoverUrl(null);
    setHasError(false);
    setApiKeyMissing(false);
    setIsLoading(true);
    setRetryCount(0); // Reset retry count for new book
  }, [bookId]);

  const handleImageError = () => {
    console.warn(`Image failed to load for: ${title} by ${author}`);
    setHasError(true);
    setCoverUrl(null);
    
    // Retry logic for failed images
    if (retryCount < 2) {
      setTimeout(() => {
        setRetryCount(prev => prev + 1);
        setHasError(false);
        setIsLoading(true);
        // Trigger a re-fetch by clearing the URL
        setCoverUrl(null);
      }, 1000 * (retryCount + 1)); // Exponential backoff
    }
  };

  const handleImageLoad = () => {
    setIsLoading(false);
    setHasError(false);
  };

  // Show loading state
  if (isLoading) {
    return (
      <div className={`${sizeClasses[size]} ${className} rounded-md bg-gradient-to-br from-slate-200 to-slate-300 animate-pulse flex items-center justify-center`}>
        <div className="w-4 h-4 bg-slate-400 rounded animate-pulse" />
      </div>
    );
  }

  // Show cover image
  if (coverUrl && !hasError) {
    return (
      <div className={`${className} relative group`}>
        <div 
          className={`${sizeClasses[size]} rounded-md overflow-hidden shadow-lg bg-white ${hoverable ? 'cursor-pointer transition-all duration-300' : ''}`}
        >
          <img
            src={coverUrl}
            alt={`${title} cover`}
            className="w-full h-full object-cover"
            onError={handleImageError}
            onLoad={handleImageLoad}
          />
        </div>
        
        {/* Expanded Cover on Hover */}
        {hoverable && (
          <div className="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-4 opacity-0 group-hover:opacity-100 transition-all duration-300 pointer-events-none z-50 scale-0 group-hover:scale-100 origin-bottom">
            <div className="w-48 h-60 rounded-xl overflow-hidden shadow-2xl bg-white border-2 border-white/20">
              <img
                src={coverUrl}
                alt={`${title} cover`}
                className="w-full h-full object-cover"
              />
            </div>
            {/* Arrow */}
            <div className="w-0 h-0 border-l-6 border-r-6 border-t-6 border-transparent border-t-white/20 mx-auto mt-1"></div>
          </div>
        )}
      </div>
    );
  }

  // Show fallback when no cover is available or on error
  if (!coverUrl || hasError) {
    return (
      <div className={`${className} relative group`}>
        <div 
          className={`${sizeClasses[size]} rounded-md overflow-hidden shadow-lg bg-gradient-to-br from-amber-500/20 to-orange-600/20 border border-white/20 flex items-center justify-center ${hoverable ? 'cursor-pointer transition-all duration-300' : ''}`}
        >
          <div className="text-center p-2">
            <Book className="w-6 h-8 text-amber-400 mx-auto mb-1" />
            <div className="text-xs text-white/80 font-medium leading-tight">
              {title.split(' ').slice(0, 2).join(' ')}
            </div>
            {apiKeyMissing && (
              <div className="text-xs text-amber-400/80 mt-1">
                Using OpenLibrary
              </div>
            )}
            {!apiKeyMissing && hasError && (
              <div className="text-xs text-red-400/80 mt-1">
                Cover Not Found
              </div>
            )}
            {!apiKeyMissing && !hasError && !coverUrl && (
              <div className="text-xs text-blue-400/80 mt-1">
                Loading...
              </div>
            )}
          </div>
        </div>
      </div>
    );
  }

  // Show nothing if no fallback
  return null;
};

export default BookCover; 