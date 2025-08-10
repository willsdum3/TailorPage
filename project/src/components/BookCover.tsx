import React, { useState, useEffect } from 'react';
import { Book } from 'lucide-react';
import { getBookCover, getBulletproofFallbacks } from '../utils/bookCoverService';

interface BookCoverProps {
  bookId: string;
  title: string;
  author: string;
  size?: 'sm' | 'md' | 'lg' | 'xl';
  className?: string;
  genre?: string;
  description?: string;
  amazonLink?: string;
  coverImage?: string;
  hoverable?: boolean;
}

const sizeClasses = {
  sm: 'w-16 h-24',
  md: 'w-20 h-32',
  lg: 'w-32 h-48',
  xl: 'w-40 h-60'
};

export const BookCover: React.FC<BookCoverProps> = ({
  bookId,
  title,
  author,
  size = 'md',
  className = '',
  genre,
  description,
  amazonLink,
  coverImage,
  hoverable = false
}) => {
  const [coverUrl, setCoverUrl] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [hasError, setHasError] = useState(false);
  const [apiKeyMissing, setApiKeyMissing] = useState(false);
  const [fallbackIndex, setFallbackIndex] = useState(0);
  const [fallbackUrls, setFallbackUrls] = useState<string[]>([]);

  useEffect(() => {
    let isMounted = true;

    const loadCover = async () => {
      try {
        setIsLoading(true);
        setHasError(false);
        setApiKeyMissing(false);
        setFallbackIndex(0);

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
          setApiKeyMissing(true);
        }

        // Fetch cover from service (guaranteed to return a URL)
        const url = await getBookCover(bookId, title, author);

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

  // Clear cover URL when bookId changes
  useEffect(() => {
    setCoverUrl(null);
    setHasError(false);
    setApiKeyMissing(false);
    setFallbackIndex(0);
    setFallbackUrls([]);
    setIsLoading(true);
  }, [bookId]);

  const handleImageError = () => {
    // Generate bulletproof fallback URLs if not already generated
    if (fallbackUrls.length === 0) {
      const urls = getBulletproofFallbacks(title, author);
      setFallbackUrls(urls);
    }

    // Try next bulletproof fallback URL
    if (fallbackIndex < fallbackUrls.length) {
      const nextUrl = fallbackUrls[fallbackIndex];
      setCoverUrl(nextUrl);
      setFallbackIndex(prev => prev + 1);
      setHasError(false);
    } else {
      // All bulletproof fallbacks failed (should never happen)
      setHasError(true);
    }
  };

  const handleImageLoad = () => {
    setIsLoading(false);
    setHasError(false);
  };

  // Show loading state
  if (isLoading) {
    return (
      <div className={`${className} relative group`}>
        <div
          className={`${sizeClasses[size]} rounded-md overflow-hidden shadow-lg bg-gradient-to-br from-amber-500/20 to-orange-600/20 border border-white/20 flex items-center justify-center animate-pulse`}
        >
          <div className="text-center p-2">
            <Book className="w-6 h-8 text-amber-400 mx-auto mb-1 animate-pulse" />
            <div className="text-xs text-white/80 font-medium leading-tight">
              Loading...
            </div>
          </div>
        </div>
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
            loading="lazy"
            crossOrigin="anonymous"
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

  // Show bulletproof fallback when image fails to load
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
              Using Bulletproof Fallbacks
            </div>
          )}
          {!apiKeyMissing && hasError && (
            <div className="text-xs text-red-400/80 mt-1">
              {fallbackIndex > 0 ? `Fallback ${fallbackIndex} Failed` : 'Image Load Error'}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}; 