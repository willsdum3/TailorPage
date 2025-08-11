import React from 'react';
import { Book, ShoppingCart, ExternalLink, Star, Home, ArrowLeft } from 'lucide-react';
import { PersonalityProfile, BookRecommendation, FavoriteBook, User } from '../types';
import { BookCover } from './BookCover';

import { useScrollToTopInstant } from '../hooks/useScrollToTop';

interface GeneratedRecommendationsPageProps {
  profile: PersonalityProfile;
  recommendations: BookRecommendation[];
  onHome: () => void;
  favorites: FavoriteBook[];
  onToggleFavorite: (book: BookRecommendation) => void;
  user: User | null;
  onLoginRequired: () => void;
}

const GeneratedRecommendationsPage: React.FC<GeneratedRecommendationsPageProps> = ({
  profile,
  recommendations,
  onHome,
  favorites,
  onToggleFavorite,
  user,
  onLoginRequired
}) => {
  const isBookFavorited = (bookId: string) => {
    // Find the book in recommendations to get title and author
    const book = recommendations.find(rec => rec.id === bookId);
    if (!book) return false;
    
    // Check if this book is favorited by comparing title and author
    const isFavorited = favorites.some(fav => 
      fav.title.toLowerCase() === book.title.toLowerCase() && 
      fav.author.toLowerCase() === book.author.toLowerCase()
    );
    
    console.log(`isBookFavorited for ${book.title}:`, isFavorited, 'favorites count:', favorites.length);
    return isFavorited;
  };

  // Scroll to top when component mounts
  useScrollToTopInstant([]);

  const handleToggleFavorite = (book: BookRecommendation) => {
    if (!user) {
      onLoginRequired();
      return;
    }
    onToggleFavorite(book);
  };

  return (
    <div className="min-h-screen py-8 px-4 relative overflow-hidden">
      {/* Background Elements */}
      <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900" />
      <div className="absolute top-20 left-20 w-72 h-72 bg-purple-500/10 rounded-full blur-3xl" />
      <div className="absolute bottom-20 right-20 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl" />
      <div className="max-w-7xl mx-auto relative z-10">
        {/* Header */}
        <div className="text-center mb-16 relative">
          <div className="absolute top-0 left-0">
            <button
              onClick={onHome}
              className="bg-white/10 backdrop-blur-sm border border-white/20 hover:bg-white/20 text-white p-3 rounded-xl transition-all duration-300 transform hover:scale-105"
              title="Go to Home"
            >
              <Home className="w-5 h-5" />
            </button>
          </div>
          <div className="inline-flex items-center space-x-2 bg-white/10 backdrop-blur-sm border border-white/20 rounded-full px-4 py-2 mb-6 mt-6">
            <Star className="w-4 h-4 text-amber-400" />
            <span className="text-sm font-medium text-white/80">Fresh Recommendations</span>
          </div>
          <h1 className="text-5xl md:text-6xl font-bold text-white mb-6 leading-tight">
            Your New <span className="bg-gradient-to-r from-amber-400 to-orange-500 bg-clip-text text-transparent">Book Picks</span>
          </h1>
          <p className="text-xl text-white/70 mb-8 max-w-4xl mx-auto leading-relaxed">
            Here are 6 new books tailored to your personality profile. Save your favourites!
          </p>
        </div>
        {/* Book Recommendations Grid */}
        <div className="grid gap-12 md:grid-cols-2 xl:grid-cols-3 mb-16">
          {recommendations.map((book) => (
            <div key={book.id} className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6 hover:bg-white/15 transition-all duration-300 transform hover:scale-105 group">
              {/* Book Cover */}
              <div className="flex justify-center mb-4">
                <BookCover
                  title={book.title}
                  author={book.author}
                  size="lg"
                  priority="high"
                  lazy={false}
                />
              </div>
              
              <div className="flex items-start justify-between mb-4">
                <div className="flex-1">
                  <div className="flex items-center justify-between mb-3">
                    <span className="inline-block bg-gradient-to-r from-amber-500 to-orange-600 text-white px-3 py-1 rounded-full text-sm font-medium">
                      {book.genre}
                    </span>
                    <button
                      onClick={() => handleToggleFavorite(book)}
                      className={`p-2 rounded-full transition-all duration-300 transform hover:scale-110 ${
                        isBookFavorited(book.id)
                          ? 'text-amber-400 hover:text-amber-300 bg-amber-400/10'
                          : 'text-white/40 hover:text-amber-400 hover:bg-amber-400/10'
                      }`}
                      title={
                        !user
                          ? 'Login to add to favorites'
                          : isBookFavorited(book.id)
                            ? 'Remove from favorites'
                            : 'Add to favorites'
                      }
                    >
                      <Star
                        className={`w-5 h-5 ${isBookFavorited(book.id) ? 'fill-current' : ''}`}
                      />
                    </button>
                  </div>
                  <h3 className="text-xl font-bold text-white mb-2 group-hover:text-amber-400 transition-colors duration-300">
                    {book.title}
                  </h3>
                  <p className="text-white/70 font-medium mb-3">by {book.author}</p>
                </div>

              </div>
              <p className="text-white/70 mb-4 leading-relaxed">
                {book.description}
              </p>
              <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-4 mb-6">
                <p className="text-sm text-white/80">
                  <span className="font-medium text-amber-400">Why this book:</span> {book.reason}
                </p>
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
      </div>
    </div>
  );
};

export default GeneratedRecommendationsPage; 