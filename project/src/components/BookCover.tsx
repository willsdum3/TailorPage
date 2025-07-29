import React, { useState, useEffect } from 'react';
import { Book } from 'lucide-react';
import { getBookCover } from '../utils/bookCoverService';

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
  hoverable = true
}) => {
  const [coverUrl, setCoverUrl] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [hasError, setHasError] = useState(false);

  useEffect(() => {
    let isMounted = true;

    const loadCover = async () => {
      try {
        setIsLoading(true);
        setHasError(false);
        
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
  }, [bookId, title, author]);

  const handleImageError = () => {
    setHasError(true);
    setCoverUrl(null);
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

  // Show fallback
  if (showFallback) {
    return (
      <div className={`${className} relative group`}>
        <div 
          className={`${sizeClasses[size]} rounded-md bg-gradient-to-br from-amber-400 to-orange-600 flex items-center justify-center shadow-lg ${hoverable ? 'cursor-pointer transition-all duration-300' : ''}`}
        >
          <Book className="w-6 h-6 text-white" />
        </div>
        
        {/* Expanded Fallback on Hover */}
        {hoverable && (
          <div className="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-4 opacity-0 group-hover:opacity-100 transition-all duration-300 pointer-events-none z-50 scale-0 group-hover:scale-100 origin-bottom">
            <div className="w-48 h-60 rounded-xl bg-gradient-to-br from-amber-400 to-orange-600 flex items-center justify-center shadow-2xl border-2 border-white/20">
              <Book className="w-16 h-16 text-white" />
            </div>
            {/* Arrow */}
            <div className="w-0 h-0 border-l-6 border-r-6 border-t-6 border-transparent border-t-white/20 mx-auto mt-1"></div>
          </div>
        )}
      </div>
    );
  }

  // Show nothing if no fallback
  return null;
};

export default BookCover; 