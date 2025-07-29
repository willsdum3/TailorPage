import React from 'react';
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
import BookCover from './BookCover';
import { useScrollToTopInstant } from '../hooks/useScrollToTop';

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

  const isBookFavorited = (bookId: string) => {
    return favorites.some(fav => fav.id === bookId);
  };

  const handleToggleFavorite = (book: BookRecommendation) => {
    if (!user) {
      onLoginRequired();
      return;
    }
    onToggleFavorite(book);
  };

  const getPersonalityDescription = (profile: PersonalityProfile) => {
    let description = "Based on your responses, you are ";
    
    if (profile.extraversion >= 20) {
      description += "outgoing and energetic, ";
    } else {
      description += "thoughtful and reflective, ";
    }
    
    if (profile.openness >= 20) {
      description += "curious about new experiences, ";
    } else {
      description += "comfortable with familiar routines, ";
    }
    
    if (profile.agreeableness >= 20) {
      description += "empathetic and cooperative, ";
    } else {
      description += "independent and assertive, ";
    }
    
    if (profile.conscientiousness >= 20) {
      description += "organized and methodical, ";
      description += "organised and methodical, ";
    } else {
      description += "spontaneous and flexible, ";
    }
    
    if (profile.emotionalStability >= 20) {
      description += "and emotionally resilient.";
    } else {
      description += "and emotionally sensitive.";
    }
    
    return description;
  };

  return (
    <div className="min-h-screen py-8 px-4 relative overflow-hidden">
      {/* Background Elements */}
      <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900" />
      <div className="absolute top-20 left-20 w-72 h-72 bg-purple-500/10 rounded-full blur-3xl" />
      <div className="absolute bottom-20 right-20 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl" />
      
      <div className="max-w-7xl mx-auto relative z-10">
        {/* Header */}
        <div className="text-center mb-16 pt-12">
          <div className="absolute top-0 left-0">
            <button
              onClick={onHome}
              className="bg-white/10 backdrop-blur-sm border border-white/20 hover:bg-white/20 text-white p-3 rounded-xl transition-all duration-300 transform hover:scale-105"
              title="Go to Home"
            >
              <Home className="w-5 h-5" />
            </button>
          </div>

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
            {getPersonalityDescription(profile)}
          </p>
          
          <button
            onClick={onRetakeQuiz}
            className="bg-white/10 backdrop-blur-sm border border-white/20 hover:bg-white/20 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105 inline-flex items-center space-x-2"
          >
            <RotateCcw className="w-4 h-4" />
            <span>Retake Quiz</span>
          </button>
        </div>

        {/* Book Recommendations Grid */}
        <div className="grid gap-8 md:grid-cols-2 lg:grid-cols-3 mb-16">
          {recommendations.map((book) => (
            <div key={book.id} className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6 hover:bg-white/15 transition-all duration-300 transform hover:scale-105 group">
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
    </div>
  );
};

export default ResultsPage;