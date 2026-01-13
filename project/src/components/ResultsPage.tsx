import React, { useState } from 'react';
import { 
  RotateCcw, 
  Star, 
  Book, 
  ShoppingCart, 
  ExternalLink,
  Home,
  Heart,
  Sparkles
} from 'lucide-react';
import { PersonalityProfile, BookRecommendation, FavoriteBook, User } from '../types';
import Logo from './Logo';

import AmazonLink from './AmazonLink';
import { useScrollToTopInstant } from '../hooks/useScrollToTop';
import { isBookFavorited } from '../utils/favoritesUtils';
import { BookCover } from './BookCover';
import BookSummaryModal, { BookSummaryData } from './BookSummaryModal';
import { bookInfoService } from '../services/bookInfoService';

interface ResultsPageProps {
  profile: PersonalityProfile;
  recommendations: BookRecommendation[];
  onRetakeQuiz: () => void;
  onHome: () => void;
  favorites: FavoriteBook[];
  onToggleFavorite: (book: BookRecommendation) => void;
  user: User | null;
  onLoginRequired: () => void;
  onAuthPrompt?: (mode: 'login' | 'signup', feature?: string) => void;
}

const ResultsPage = ({
  profile,
  recommendations,
  onRetakeQuiz,
  onHome,
  favorites,
  onToggleFavorite,
  user,
  onLoginRequired,
  onAuthPrompt
}: ResultsPageProps) => {
  // Scroll to top when component mounts
  useScrollToTopInstant([]);
  
  // Debug logging
  console.log('🔍 ResultsPage render - Debug info:');
  console.log('📊 Profile:', profile);
  console.log('📚 Recommendations count:', recommendations?.length || 0);
  console.log('❤️ Favorites count:', favorites?.length || 0);
  console.log('👤 User:', user);
  
  // Book summary modal state
  const [selectedBook, setSelectedBook] = useState<BookSummaryData | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isLoadingBookInfo, setIsLoadingBookInfo] = useState(false);

  const checkIfBookFavorited = (bookId: string) => {
    // Find the book in recommendations to get title and author
    const book = recommendations.find(rec => rec.id === bookId);
    if (!book) return false;
    
    // Check if this book is favorited using the utility function
    const isFavorited = isBookFavorited(favorites, book.title, book.author);
    
    console.log(`isBookFavorited for ${book.title}:`, isFavorited, 'favorites count:', favorites.length);
    return isFavorited;
  };

  const handleToggleFavorite = (book: BookRecommendation) => {
    console.log('ResultsPage handleToggleFavorite called with book:', book);
    console.log('Current user:', user);
    
    if (!user) {
      console.log('No user found, calling onLoginRequired');
      onLoginRequired();
      return;
    }
    
    console.log('Calling onToggleFavorite with book:', book);
    onToggleFavorite(book);
  };

  const handleBookCoverClick = async (book: BookRecommendation) => {
    setIsLoadingBookInfo(true);
    setIsModalOpen(true);
    
    try {
      const bookInfo = await bookInfoService.getBookInfo(book.title, book.author);
      setSelectedBook(bookInfo);
    } catch (error) {
      console.error('Error fetching book info:', error);
      // Set basic book info as fallback
      setSelectedBook({
        title: book.title,
        author: book.author,
        description: book.description,
        genre: book.genre,
        amazonLink: book.amazonLink
      });
    } finally {
      setIsLoadingBookInfo(false);
    }
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setSelectedBook(null);
  };

  const handleAddToFavoritesFromModal = (book: BookSummaryData) => {
    // Convert BookSummaryData to BookRecommendation format
    const bookRecommendation: BookRecommendation = {
      id: `${book.title}-${book.author}`,
      title: book.title,
      author: book.author,
      description: book.description || '',
      genre: book.genre || 'Fiction',
      reason: 'Added from book summary',
      amazonLink: book.amazonLink || ''
    };
    
    onToggleFavorite(bookRecommendation);
  };

  // Check if we have the required data to render
  if (!profile) {
    console.error('❌ ResultsPage: No personality profile provided');
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900">
        <div className="text-center text-white">
          <h1 className="text-2xl font-bold mb-4">Loading Results...</h1>
          <p>Please wait while we process your quiz results.</p>
        </div>
      </div>
    );
  }

  if (!recommendations || recommendations.length === 0) {
    console.error('❌ ResultsPage: No recommendations provided');
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900">
        <div className="text-center text-white">
          <h1 className="text-2xl font-bold mb-4">No Recommendations Found</h1>
          <p>We couldn't generate recommendations based on your quiz results.</p>
          <button
            onClick={onRetakeQuiz}
            className="mt-4 bg-gradient-to-r from-amber-500 to-orange-600 text-white px-6 py-3 rounded-xl font-medium"
          >
            Retake Quiz
          </button>
        </div>
      </div>
    );
  }

  // Calculate recommended genres based on personality profile (memoized)
  const recommendedGenres = React.useMemo(() => {
    const genreScores: { genre: string; score: number }[] = [];

    // Calculate scores for each genre category using the same logic as book scoring
    const genres = [
      { name: 'Literary Fiction', score: profile.openness * 2.5 + profile.agreeableness * 1.5 + profile.conscientiousness * 0.5 },
      { name: 'Fantasy', score: profile.openness * 2.2 + (25 - profile.conscientiousness) * 0.8 + profile.extraversion * 0.5 },
      { name: 'Science Fiction', score: profile.openness * 2.0 + profile.conscientiousness * 1.5 + (25 - profile.conscientiousness) * 0.5 },
      { name: 'Self-Help', score: profile.conscientiousness * 2.5 + profile.emotionalStability * 1.8 + profile.openness * 0.7 },
      { name: 'Biography', score: profile.agreeableness * 1.5 + profile.openness * 1.2 + profile.extraversion * 1.0 + profile.conscientiousness * 0.8 },
      { name: 'Psychological Thriller', score: profile.openness * 1.5 + profile.emotionalStability * 1.8 + profile.conscientiousness * 1.2 },
      { name: 'Dystopian Fiction', score: profile.openness * 1.8 + profile.conscientiousness * 1.5 + profile.emotionalStability * 1.2 },
      { name: 'History', score: profile.openness * 1.5 + profile.conscientiousness * 1.8 + profile.emotionalStability * 2.0 },
      { name: 'Mystery', score: profile.conscientiousness * 1.5 + profile.openness * 1.2 + profile.emotionalStability * 1.0 + profile.agreeableness * 1.3 },
      { name: 'Romance', score: profile.agreeableness * 2.0 + profile.extraversion * 1.5 + profile.emotionalStability * 1.2 },
      { name: 'Young Adult', score: profile.extraversion * 1.8 + profile.openness * 1.5 + profile.agreeableness * 1.2 },
      { name: 'Thriller', score: profile.emotionalStability * 2.0 + profile.openness * 1.3 + profile.conscientiousness * 1.0 },
      { name: 'Philosophy', score: profile.openness * 2.5 + profile.agreeableness * 1.5 + profile.conscientiousness * 0.5 },
      { name: 'Contemporary Fiction', score: profile.agreeableness * 2.0 + profile.extraversion * 1.5 + profile.emotionalStability * 1.2 },
    ];

    // Apply personality trait adjustments
    genres.forEach(genre => {
      let adjustedScore = genre.score;

      // High openness adjustments
      if (profile.openness >= 20) {
        if (['Science Fiction', 'Fantasy', 'Philosophy', 'Literary Fiction'].includes(genre.name)) {
          adjustedScore += 3;
        }
      } else if (profile.openness <= 8) {
        if (['Romance', 'Contemporary Fiction', 'Mystery'].includes(genre.name)) {
          adjustedScore += 2;
        }
      }

      // High conscientiousness adjustments
      if (profile.conscientiousness >= 20) {
        if (['Self-Help', 'Biography', 'History'].includes(genre.name)) {
          adjustedScore += 3;
        }
      } else if (profile.conscientiousness <= 8) {
        if (['Fantasy', 'Romance', 'Thriller'].includes(genre.name)) {
          adjustedScore += 2;
        }
      }

      // High extraversion adjustments
      if (profile.extraversion >= 20) {
        if (['Romance', 'Contemporary Fiction', 'Biography'].includes(genre.name)) {
          adjustedScore += 2;
        }
      } else if (profile.extraversion <= 8) {
        if (['Literary Fiction', 'Philosophy', 'Science Fiction'].includes(genre.name)) {
          adjustedScore += 2;
        }
      }

      // High agreeableness adjustments
      if (profile.agreeableness >= 20) {
        if (['Romance', 'Contemporary Fiction', 'Self-Help'].includes(genre.name)) {
          adjustedScore += 2;
        }
      } else if (profile.agreeableness <= 8) {
        if (['Thriller', 'Dystopian Fiction'].includes(genre.name)) {
          adjustedScore += 2;
        }
      }

      // High emotional stability adjustments
      if (profile.emotionalStability >= 20) {
        if (['Thriller', 'Psychological Thriller', 'Dystopian Fiction'].includes(genre.name)) {
          adjustedScore += 2;
        }
      } else if (profile.emotionalStability <= 12) {
        if (['Romance', 'Contemporary Fiction', 'Self-Help', 'Biography'].includes(genre.name)) {
          adjustedScore += 2;
        }
      }

      genreScores.push({ genre: genre.name, score: adjustedScore });
    });

    // Sort by score and get top genres (those with scores above a threshold)
    genreScores.sort((a, b) => b.score - a.score);
    
    // Get top genres - take genres that are within 85% of the top score
    const topScore = genreScores[0]?.score || 0;
    const threshold = topScore * 0.85;
    const topGenres = genreScores
      .filter(g => g.score >= threshold)
      .slice(0, 3) // Limit to top 3 genres
      .map(g => g.genre);

    return topGenres.length > 0 ? topGenres : ['Contemporary Fiction']; // Fallback genre
  }, [profile]);

  return (
    <div className="min-h-screen py-8 px-4 relative overflow-hidden">
      {/* Background Elements */}
      <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900" />
      <div className="absolute top-20 left-20 w-72 h-72 bg-purple-500/10 rounded-full blur-3xl" />
      <div className="absolute bottom-20 right-20 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl" />
      
      {/* Home Button - Top Left */}
      <button
        onClick={onHome}
        className="fixed top-6 left-6 z-50 bg-white/10 backdrop-blur-md border border-white/20 hover:bg-white/20 text-white p-3 rounded-xl transition-all duration-300 transform hover:scale-105"
        aria-label="Go to Home"
      >
        <Home className="w-6 h-6" />
      </button>
      
      <div className="max-w-7xl mx-auto relative z-10">
        {/* Header */}
        <div className="text-center mb-16 pt-12">
          <div className="inline-flex items-center space-x-2 bg-white/10 backdrop-blur-sm border border-white/20 rounded-full px-4 py-2 mb-10">
            <Sparkles className="w-4 h-4 text-amber-400" />
            <span className="text-sm font-medium text-white/90">Personalised Results</span>
          </div>
          
          <div className="mb-10">
            <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold mb-4 leading-tight">
              <span className="text-white">Your Perfect </span>
              <span className="text-amber-400 drop-shadow-lg">Reading List</span>
            </h1>
          </div>
          
          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center mb-16">
            <button
              onClick={onRetakeQuiz}
              className="bg-white/10 hover:bg-white/20 backdrop-blur-sm border border-white/20 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-300 transform hover:scale-105 inline-flex items-center space-x-2"
            >
              <RotateCcw className="w-5 h-5" />
              <span>Retake Quiz</span>
            </button>
          </div>
        </div>

        {/* Genre Recommendations */}
        <div className="text-center mb-8">
          <p className="text-lg md:text-xl text-white/90 max-w-4xl mx-auto leading-relaxed font-medium">
            Based on your results,{' '}
            {recommendedGenres.map((genre, index) => {
              const colors = ['text-amber-400', 'text-blue-400', 'text-purple-400'];
              const colorClass = colors[index % colors.length];
              
              if (recommendedGenres.length === 1) {
                return <span key={genre} className={`font-bold ${colorClass}`}>{genre}</span>;
              } else if (index === recommendedGenres.length - 1) {
                return (
                  <React.Fragment key={genre}>
                    {' and '}
                    <span className={`font-bold ${colorClass}`}>{genre}</span>
                  </React.Fragment>
                );
              } else {
                return (
                  <React.Fragment key={genre}>
                    <span className={`font-bold ${colorClass}`}>{genre}</span>
                    {index < recommendedGenres.length - 2 && ', '}
                  </React.Fragment>
                );
              }
            })}{' '}
            themed books are likely to interest you the most.
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
                  clickable={true}
                  onClick={() => handleBookCoverClick(book)}
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
                        checkIfBookFavorited(book.id)
                          ? 'text-amber-400 hover:text-amber-300 bg-amber-400/10'
                          : 'text-white/40 hover:text-amber-400 hover:bg-amber-400/10'
                      }`}
                      title={
                        !user 
                          ? 'Login to add to favorites'
                          : checkIfBookFavorited(book.id) 
                            ? 'Remove from favorites' 
                            : 'Add to favorites'
                      }
                    >
                      <Star 
                        className={`w-5 h-5 ${checkIfBookFavorited(book.id) ? 'fill-current' : ''}`}
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
              
              <AmazonLink
                title={book.title}
                author={book.author}
                originalLink={book.amazonLink}
                className="w-full"
              />
            </div>
          ))}
        </div>

        {/* Sign-up encouragement for non-authenticated users */}
        {!user && (
          <div className="bg-gradient-to-r from-blue-500/20 to-purple-500/20 backdrop-blur-sm border border-blue-500/30 rounded-2xl p-8 mb-16 max-w-4xl mx-auto">
            <div className="text-center">
              <div className="flex justify-center mb-4">
                <div className="w-16 h-16 bg-gradient-to-r from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
                  <Sparkles className="w-8 h-8 text-white" />
                </div>
              </div>
              <h3 className="text-2xl font-bold text-white mb-4">
                Unlock Your Detailed Personality Breakdown
              </h3>
              <p className="text-white/80 mb-6 text-lg leading-relaxed">
                Sign in to access your complete personality analysis, save your favorite books, and get personalized recommendations in your profile.
              </p>
              <div className="flex justify-center">
                <button
                  onClick={() => onAuthPrompt?.('login', 'detailed personality breakdown')}
                  className="bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-600 hover:to-purple-700 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-300 transform hover:scale-105 hover:shadow-2xl inline-flex items-center justify-center space-x-2"
                >
                  <span>Sign In</span>
                  <Star className="w-5 h-5" />
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Share Section */}
        <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 text-center">
          <div className="mb-8">
            <h2 className="text-3xl font-bold text-white mb-4">Share Your Results</h2>
            <p className="text-white/70 mb-8 max-w-2xl mx-auto">
              Let your friends discover their perfect books too! Share your personalized recommendations and inspire others to find their next great read.
            </p>
            
            <div className="flex flex-wrap justify-center gap-4 mb-8">
              <a href={`https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(window.location.href)}`} target="_blank" rel="noopener noreferrer" className="flex items-center space-x-3 px-6 py-3 rounded-xl font-semibold bg-white/10 hover:bg-blue-500/20 transition-all duration-300 transform hover:scale-105 border border-white/20 hover:border-blue-400/30">
                <img src="/facebooklogo5.jpg" alt="Facebook" className="w-8 h-8 rounded-md object-cover" />
                <span>Facebook</span>
              </a>
              <a href={`https://twitter.com/intent/tweet?url=${encodeURIComponent(window.location.href)}&text=${encodeURIComponent('Tailor Page recommended me these books based on my personality!')}`} target="_blank" rel="noopener noreferrer" className="flex items-center space-x-3 px-6 py-3 rounded-xl font-semibold bg-white/10 hover:bg-black/20 transition-all duration-300 transform hover:scale-105 border border-white/20 hover:border-gray-400/30">
                <img src="/xlogo2.jpg" alt="X" className="w-8 h-8 rounded-md object-cover" />
                <span>X</span>
              </a>
              <a href={`https://www.linkedin.com/sharing/share-offsite/?url=${encodeURIComponent(window.location.href)}`} target="_blank" rel="noopener noreferrer" className="flex items-center space-x-3 px-6 py-3 rounded-xl font-semibold bg-white/10 hover:bg-blue-600/20 transition-all duration-300 transform hover:scale-105 border border-white/20 hover:border-blue-500/30">
                <img src="/linkedinlogo3.jpg" alt="LinkedIn" className="w-8 h-8 rounded-md object-cover" />
                <span>LinkedIn</span>
              </a>
              <a href={`https://reddit.com/submit?url=${encodeURIComponent(window.location.href)}&title=${encodeURIComponent('Tailor Page recommended me these books based on my personality!')}`} target="_blank" rel="noopener noreferrer" className="flex items-center space-x-3 px-6 py-3 rounded-xl font-semibold bg-white/10 hover:bg-orange-500/20 transition-all duration-300 transform hover:scale-105 border border-white/20 hover:border-orange-400/30">
                <img src="/Redditlogo5.png" alt="Reddit" className="w-8 h-8 rounded-md object-cover" />
                <span>Reddit</span>
              </a>
              <a href={`https://api.whatsapp.com/send?text=${encodeURIComponent('Tailor Page recommended me these books based on my personality! ' + window.location.href)}`} target="_blank" rel="noopener noreferrer" className="flex items-center space-x-3 px-6 py-3 rounded-xl font-semibold bg-white/10 hover:bg-green-500/20 transition-all duration-300 transform hover:scale-105 border border-white/20 hover:border-green-400/30">
                <img src="/whatsapplogo3.jpg" alt="WhatsApp" className="w-8 h-8 rounded-md object-cover" />
                <span>WhatsApp</span>
              </a>
              <a href="https://www.instagram.com/" target="_blank" rel="noopener noreferrer" className="flex items-center space-x-3 px-6 py-3 rounded-xl font-semibold bg-white/10 hover:bg-pink-500/20 transition-all duration-300 transform hover:scale-105 border border-white/20 hover:border-pink-400/30">
                <img src="/instagramlogo3.jpg" alt="Instagram" className="w-8 h-8 rounded-md object-cover" />
                <span>Instagram</span>
              </a>
            </div>
          </div>
          
          <div className="border-t border-white/10 pt-8">
            <h3 className="text-2xl font-bold text-white mb-4">Ready for More?</h3>
            <p className="text-white/70 mb-6">
              Discover even more personalized recommendations by taking the quiz again or exploring different aspects of your reading personality.
            </p>
            <button
              onClick={onRetakeQuiz}
              className="bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-300 transform hover:scale-105 hover:shadow-2xl inline-flex items-center space-x-2"
            >
              <RotateCcw className="w-5 h-5" />
              <span>Take Quiz Again</span>
            </button>
          </div>
        </div>
      </div>

      {/* Book Summary Modal */}
      {selectedBook && (
        <BookSummaryModal
          book={selectedBook}
          isOpen={isModalOpen}
          onClose={handleCloseModal}
          onAddToFavorites={handleAddToFavoritesFromModal}
          isFavorited={checkIfBookFavorited(`${selectedBook.title}-${selectedBook.author}`)}
          user={user}
          onLoginRequired={onLoginRequired}
        />
      )}
    </div>
  );
};

export default ResultsPage;