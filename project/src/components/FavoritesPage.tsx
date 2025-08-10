import React from 'react';
import { Book, ShoppingCart, ExternalLink, Trash2, ArrowLeft, Heart, Sparkles, Home } from 'lucide-react';
import { FavoriteBook, User } from '../types';
import { BookCover } from './BookCover';
import { useScrollToTopInstant } from '../hooks/useScrollToTop';

interface FavoritesPageProps {
  favorites: FavoriteBook[];
  onRemoveFavorite: (bookId: string) => void;
  onBack: () => void;
  hasCompletedQuiz?: boolean;
  onStartQuiz?: () => void;
  onGenerateNewBooks?: () => void;
}

const FavoritesPage: React.FC<FavoritesPageProps> = ({ favorites, onRemoveFavorite, onBack, hasCompletedQuiz = false, onStartQuiz, onGenerateNewBooks }) => {
  
  // Scroll to top when component mounts
  useScrollToTopInstant([]);

  if (favorites.length === 0) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4 relative overflow-hidden">
        {/* Background Elements */}
        <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900" />
        <div className="absolute top-20 left-20 w-72 h-72 bg-purple-500/10 rounded-full blur-3xl" />
        <div className="absolute bottom-20 right-20 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl" />
        
        <div className="max-w-2xl mx-auto text-center relative z-10">
          {/* Home Button */}
          <div className="absolute top-0 right-0">
            <button
              onClick={onBack}
              className="bg-white/10 backdrop-blur-sm border border-white/20 hover:bg-white/20 text-white p-3 rounded-xl transition-all duration-300 transform hover:scale-105"
              title="Go to Home"
            >
              <Home className="w-5 h-5" />
            </button>
          </div>
          
          <div className="mb-8">
            <div className="inline-flex items-center justify-center w-20 h-20 bg-gradient-to-r from-amber-500 to-orange-600 rounded-2xl mb-6">
              <Heart className="w-10 h-10 text-white" />
            </div>
            <h1 className="text-4xl md:text-5xl font-bold text-white mb-6 leading-tight">
              Your <span className="bg-gradient-to-r from-amber-400 to-orange-500 bg-clip-text text-transparent">Favourites</span>
            </h1>
            <p className="text-xl text-white/70 mb-8">
              You haven't added any books to your favorites yet.
            </p>
          </div>

          {hasCompletedQuiz ? (
            <>
              <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 mb-8">
                <h2 className="text-2xl font-bold text-white mb-4">Generate New Recommendations</h2>
                <p className="text-white/70 mb-6 leading-relaxed">
                  You've completed the quiz! Generate new book recommendations to discover more books that match your personality and start building your favorites collection.
                </p>
                <div className="flex items-center justify-center space-x-2 text-amber-400">
                  <Sparkles className="w-5 h-5" />
                  <span className="text-sm font-medium">Get fresh recommendations tailored to you</span>
                </div>
              </div>

              <button
                onClick={onGenerateNewBooks || onBack}
                className="bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-300 transform hover:scale-105 hover:shadow-2xl inline-flex items-center space-x-2"
              >
                <ArrowLeft className="w-5 h-5" />
                <span>Generate New Books</span>
              </button>
            </>
          ) : (
            <>
              <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 mb-8">
                <h2 className="text-2xl font-bold text-white mb-4">Start Building Your Collection</h2>
                <p className="text-white/70 mb-6 leading-relaxed">
                  Take the personality quiz to get personalised book recommendations, then save your favourites by clicking the star icon next to any book.
                </p>
                <div className="flex items-center justify-center space-x-2 text-amber-400">
                  <Sparkles className="w-5 h-5" />
                  <span className="text-sm font-medium">Discover books tailored just for you</span>
                </div>
              </div>

              <button
                onClick={onStartQuiz || onBack}
                className="bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-300 transform hover:scale-105 hover:shadow-2xl inline-flex items-center space-x-2"
              >
                <ArrowLeft className="w-5 h-5" />
                <span>Start Quiz</span>
              </button>
            </>
          )}
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen py-8 px-4 relative overflow-hidden">
      {/* Background Elements */}
      <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900" />
      <div className="absolute top-20 left-20 w-72 h-72 bg-purple-500/10 rounded-full blur-3xl" />
      <div className="absolute bottom-20 right-20 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl" />
      
      <div className="max-w-7xl mx-auto relative z-10">
        {/* Header */}
      {/* Home Button - Top Left */}
      <button
        onClick={onBack}
        className="fixed top-6 left-6 z-50 bg-white/10 backdrop-blur-md border border-white/20 hover:bg-white/20 text-white p-3 rounded-xl transition-all duration-300 transform hover:scale-105"
        aria-label="Go to Home"
      >
        <Home className="w-6 h-6" />
      </button>

        <div className="text-center mb-16">

          <div className="inline-flex items-center space-x-2 bg-white/10 backdrop-blur-sm border border-white/20 rounded-full px-4 py-2 mb-6">
            <Heart className="w-4 h-4 text-amber-400" />
            <span className="text-sm font-medium text-white/80">Your Collection</span>
          </div>
          
          <h1 className="text-5xl md:text-6xl font-bold text-white mb-6 leading-tight">
            Your <span className="bg-gradient-to-r from-amber-400 to-orange-500 bg-clip-text text-transparent">Favourites</span>
          </h1>
          
          <p className="text-xl text-white/70 mb-8">
            {favorites.length} book{favorites.length !== 1 ? 's' : ''} saved to your personal collection
          </p>
        </div>

        {/* Favorites Grid */}
        <div className="grid gap-12 md:grid-cols-2 xl:grid-cols-3 mb-16">
          {favorites.map((book, index) => (
            <div key={`${book.id}-${book.title}-${book.author}`} className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6 hover:bg-white/15 transition-all duration-300 transform hover:scale-105 group">
              <div className="flex items-start justify-between mb-4">
                <div className="flex-1">
                  <div className="flex items-center justify-between mb-3">
                    <span className="inline-block bg-gradient-to-r from-amber-500 to-orange-600 text-white px-3 py-1 rounded-full text-sm font-medium">
                      {book.genre}
                    </span>
                    <button
                      onClick={() => {
                        console.log('Remove button clicked for book:', book.title, 'by', book.author, 'with ID:', book.id);
                        onRemoveFavorite(book.id);
                      }}
                      className="p-2 rounded-full text-red-400 hover:text-red-300 hover:bg-red-400/10 transition-all duration-300 transform hover:scale-110"
                      title="Remove from favorites"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                  
                  <h3 className="text-xl font-bold text-white mb-2 group-hover:text-amber-400 transition-colors duration-300">
                    {book.title}
                  </h3>
                  <p className="text-white/70 font-medium mb-3">by {book.author}</p>
                </div>
                <BookCover 
                  bookId={book.id}
                  title={book.title}
                  author={book.author}
                  size="md"
                  className="flex-shrink-0 ml-4"
                  genre={book.genre}
                  description={book.description}
                  amazonLink={book.amazonLink}
                />
              </div>
              
              <p className="text-white/70 mb-4 leading-relaxed">
                {book.description}
              </p>
              
              <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-4 mb-4">
                <p className="text-sm text-white/80">
                  <span className="font-medium text-amber-400">Why this book:</span> {book.reason}
                </p>
              </div>

              <div className="flex items-center justify-between text-xs text-white/50 mb-4">
                <span>Added: {new Date(book.dateAdded).toLocaleDateString()}</span>
              </div>
              
              <a
                href={book.amazonLink}
                target="_blank"
                rel="noopener noreferrer"
                className="bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white px-4 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105 inline-flex items-center justify-center space-x-2 w-full group"
              >
                <ShoppingCart className="w-4 h-4" />
                <span>Buy on Amazon</span>
                <ExternalLink className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
              </a>
            </div>
          ))}
        </div>

        {/* Bottom CTA */}
        <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 text-center">
          {hasCompletedQuiz ? (
            <>
              <h2 className="text-3xl font-bold text-white mb-4">Keep Discovering</h2>
              <p className="text-white/70 mb-8 max-w-2xl mx-auto">
                Generate new book recommendations to discover more books that match your personality and expand your reading horizons!
              </p>
              <button
                onClick={onGenerateNewBooks || onBack}
                className="bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-300 transform hover:scale-105 hover:shadow-2xl inline-flex items-center space-x-2"
              >
                <ArrowLeft className="w-5 h-5" />
                <span>Generate New Books</span>
              </button>
            </>
          ) : (
            <>
              <h2 className="text-3xl font-bold text-white mb-4">Keep Discovering</h2>
              <p className="text-white/70 mb-8 max-w-2xl mx-auto">
                Take the quiz again to discover more books that match your personality and expand your reading horizons!
              </p>
              <button
                onClick={onBack}
                className="bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-300 transform hover:scale-105 hover:shadow-2xl inline-flex items-center space-x-2"
              >
                <ArrowLeft className="w-5 h-5" />
                <span>Take Quiz Again</span>
              </button>
            </>
          )}
        </div>
      </div>
    </div>
  );
};

export default FavoritesPage;