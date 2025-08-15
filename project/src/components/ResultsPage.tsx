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
}

const ResultsPage = ({
  profile,
  recommendations,
  onRetakeQuiz,
  onHome,
  favorites,
  onToggleFavorite,
  user,
  onLoginRequired
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

  // Create a simple personality description
  const getPersonalityDescription = () => {
    const traits = [];
    if (profile.extraversion >= 16) traits.push('outgoing and energetic');
    if (profile.openness >= 16) traits.push('curious about new experiences');
    if (profile.agreeableness >= 16) traits.push('empathetic and cooperative');
    if (profile.conscientiousness >= 16) traits.push('organized and methodical');
    if (profile.emotionalStability >= 16) traits.push('emotionally stable');
    
    if (traits.length > 0) {
      return `a ${traits.join(', ')} individual with diverse reading interests.`;
    }
    
    return `a balanced individual with diverse interests and adaptable reading preferences.`;
  };

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
            <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold text-white mb-4 leading-tight">
              Your Perfect
            </h1>
            <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold text-amber-400 mb-4 leading-tight drop-shadow-lg">
              Reading List
            </h1>
          </div>
          
          <p className="text-lg md:text-xl text-white/90 mb-12 max-w-4xl mx-auto leading-relaxed font-medium">
            Based on your responses, you are {getPersonalityDescription()}.
          </p>
          
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