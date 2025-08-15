import React, { useState, useEffect } from 'react';
import { X, BookOpen, Star, Calendar, User, ExternalLink, Heart } from 'lucide-react';
import { BookCover } from './BookCover';
import AmazonLink from './AmazonLink';

export interface BookSummaryData {
  title: string;
  author: string;
  description?: string;
  genre?: string;
  publishedYear?: number;
  rating?: number;
  reviewCount?: number;
  pageCount?: number;
  isbn?: string;
  publisher?: string;
  language?: string;
  amazonLink?: string;
}

interface BookSummaryModalProps {
  book: BookSummaryData;
  isOpen: boolean;
  onClose: () => void;
  onAddToFavorites?: (book: BookSummaryData) => void;
  isFavorited?: boolean;
  user?: any;
  onLoginRequired?: () => void;
}

export const BookSummaryModal: React.FC<BookSummaryModalProps> = ({
  book,
  isOpen,
  onClose,
  onAddToFavorites,
  isFavorited = false,
  user,
  onLoginRequired
}) => {
  const [isLoading, setIsLoading] = useState(false);

  // Close modal on escape key
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        onClose();
      }
    };

    if (isOpen) {
      document.addEventListener('keydown', handleEscape);
      document.body.style.overflow = 'hidden'; // Prevent background scrolling
    }

    return () => {
      document.removeEventListener('keydown', handleEscape);
      document.body.style.overflow = 'unset';
    };
  }, [isOpen, onClose]);

  const handleAddToFavorites = () => {
    if (!user) {
      onLoginRequired?.();
      return;
    }
    
    if (onAddToFavorites) {
      setIsLoading(true);
      onAddToFavorites(book);
      setIsLoading(false);
    }
  };

  const handleBackdropClick = (e: React.MouseEvent) => {
    if (e.target === e.currentTarget) {
      onClose();
    }
  };

  if (!isOpen) return null;

  return (
    <div 
      className="fixed inset-0 z-[9999] flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm"
      onClick={handleBackdropClick}
    >
      <div className="bg-gradient-to-br from-gray-900 to-black border border-white/20 rounded-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto shadow-2xl">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-white/10">
          <div className="flex items-center space-x-3">
            <BookOpen className="w-6 h-6 text-amber-400" />
            <h2 className="text-xl font-bold text-white">Book Summary</h2>
          </div>
          <button
            onClick={onClose}
            className="p-2 rounded-full text-white/60 hover:text-white hover:bg-white/10 transition-all duration-200"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6">
          <div className="flex flex-col lg:flex-row gap-6">
            {/* Book Cover */}
            <div className="flex-shrink-0">
              <BookCover
                title={book.title}
                author={book.author}
                size="lg"
                priority="high"
                lazy={false}
              />
            </div>

            {/* Book Details */}
            <div className="flex-1 space-y-4">
              {/* Title and Author */}
              <div>
                <h3 className="text-2xl font-bold text-white mb-2 leading-tight">
                  {book.title}
                </h3>
                <p className="text-lg text-white/70 font-medium">
                  by {book.author}
                </p>
              </div>

              {/* Rating */}
              {book.rating && (
                <div className="flex items-center space-x-2">
                  <div className="flex items-center space-x-1">
                    {[...Array(5)].map((_, i) => (
                      <Star
                        key={i}
                        className={`w-4 h-4 ${
                          i < Math.floor(book.rating!) 
                            ? 'text-amber-400 fill-current' 
                            : 'text-white/30'
                        }`}
                      />
                    ))}
                  </div>
                  <span className="text-white/80 font-medium">{book.rating}</span>
                  {book.reviewCount && (
                    <span className="text-white/60 text-sm">
                      ({book.reviewCount.toLocaleString()} reviews)
                    </span>
                  )}
                </div>
              )}

              {/* Genre */}
              {book.genre && (
                <div className="flex items-center space-x-2">
                  <span className="inline-block bg-gradient-to-r from-amber-500 to-orange-600 text-white px-3 py-1 rounded-full text-sm font-medium">
                    {book.genre}
                  </span>
                </div>
              )}

              {/* Book Details */}
              <div className="grid grid-cols-2 gap-4 text-sm">
                {book.publishedYear && (
                  <div className="flex items-center space-x-2 text-white/70">
                    <Calendar className="w-4 h-4" />
                    <span>Published {book.publishedYear}</span>
                  </div>
                )}
                {book.pageCount && (
                  <div className="flex items-center space-x-2 text-white/70">
                    <BookOpen className="w-4 h-4" />
                    <span>{book.pageCount} pages</span>
                  </div>
                )}
                {book.publisher && (
                  <div className="flex items-center space-x-2 text-white/70">
                    <User className="w-4 h-4" />
                    <span>{book.publisher}</span>
                  </div>
                )}
                {book.language && (
                  <div className="flex items-center space-x-2 text-white/70">
                    <span className="text-amber-400">Language:</span>
                    <span>{book.language}</span>
                  </div>
                )}
              </div>

              {/* Description */}
              {book.description && (
                <div>
                  <h4 className="text-white font-semibold mb-2">About this book</h4>
                  <p className="text-white/80 leading-relaxed">
                    {book.description}
                  </p>
                </div>
              )}

              {/* Action Buttons */}
              <div className="flex flex-wrap gap-3 pt-4">
                {/* Add to Favorites */}
                {onAddToFavorites && (
                  <button
                    onClick={handleAddToFavorites}
                    disabled={isLoading}
                    className={`flex items-center space-x-2 px-4 py-2 rounded-lg font-medium transition-all duration-300 ${
                      isFavorited
                        ? 'bg-amber-500 text-white hover:bg-amber-600'
                        : 'bg-white/10 text-white hover:bg-white/20 border border-white/20'
                    }`}
                  >
                    <Heart className={`w-4 h-4 ${isFavorited ? 'fill-current' : ''}`} />
                    <span>
                      {isLoading 
                        ? 'Adding...' 
                        : isFavorited 
                          ? 'In Favorites' 
                          : 'Add to Favorites'
                      }
                    </span>
                  </button>
                )}

                {/* Buy on Amazon */}
                {book.amazonLink && (
                  <AmazonLink
                    title={book.title}
                    author={book.author}
                    originalLink={book.amazonLink}
                    className="flex items-center space-x-2 px-4 py-2 bg-gradient-to-r from-orange-500 to-red-600 text-white rounded-lg font-medium hover:from-orange-600 hover:to-red-700 transition-all duration-300"
                  >
                    <ExternalLink className="w-4 h-4" />
                    <span>Buy on Amazon</span>
                  </AmazonLink>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default BookSummaryModal;
