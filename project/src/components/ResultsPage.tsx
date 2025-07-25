import React from 'react';
import { Book, ShoppingCart, RotateCcw, ExternalLink, Share2, MessageCircle, Star, Sparkles, Home } from 'lucide-react';
import { PersonalityProfile, BookRecommendation, FavoriteBook, User } from '../types';

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

  const shareText = "Tailor Page recommended me these books based on my personality!";
  const shareUrl = window.location.href;
  
  const handleShare = (platform: string) => {
    const bookTitles = recommendations.slice(0, 3).map(book => `"${book.title}"`).join(', ');
    const fullShareText = `${shareText} ${bookTitles} and more! Check it out: ${shareUrl}`;
    
    let url = '';
    
    switch (platform) {
      case 'twitter':
        url = `https://twitter.com/intent/tweet?text=${encodeURIComponent(fullShareText)}`;
        break;
      case 'facebook':
        url = `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(shareUrl)}&quote=${encodeURIComponent(shareText)}`;
        break;
      case 'reddit':
        url = `https://reddit.com/submit?url=${encodeURIComponent(shareUrl)}&title=${encodeURIComponent(shareText)}`;
        break;
      case 'whatsapp':
        url = `https://wa.me/?text=${encodeURIComponent(fullShareText)}`;
        break;
      case 'instagram':
        navigator.clipboard.writeText(fullShareText).then(() => {
          alert('Text copied to clipboard! You can now paste it in your Instagram story or post.');
        });
        return;
    }
    
    if (url) {
      window.open(url, '_blank', 'width=600,height=400');
    }
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
        <div className="text-center mb-16">
          <div className="absolute top-0 left-0">
            <button
              onClick={onHome}
              className="bg-white/10 backdrop-blur-sm border border-white/20 hover:bg-white/20 text-white p-3 rounded-xl transition-all duration-300 transform hover:scale-105"
              title="Go to Home"
            >
              <Home className="w-5 h-5" />
            </button>
          </div>

          <div className="inline-flex items-center space-x-2 bg-white/10 backdrop-blur-sm border border-white/20 rounded-full px-4 py-2 mb-6">
            <Sparkles className="w-4 h-4 text-amber-400" />
            <span className="text-sm font-medium text-white/80">Personalised Results</span>
          </div>
          
          <h1 className="text-5xl md:text-6xl font-bold text-white mb-6 leading-tight">
            Your Perfect
            <span className="block bg-gradient-to-r from-amber-400 to-orange-500 bg-clip-text text-transparent">
              Reading List
            </span>
          </h1>
          
          <p className="text-xl text-white/70 mb-8 max-w-4xl mx-auto leading-relaxed">
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
                <Book className="w-6 h-6 text-amber-400 flex-shrink-0 ml-4" />
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
              <button
                onClick={() => handleShare('twitter')}
                className="bg-blue-500 hover:bg-blue-600 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105 inline-flex items-center space-x-2"
              >
                <Share2 className="w-4 h-4" />
                <span>X (Twitter)</span>
              </button>
              <button
                onClick={() => handleShare('facebook')}
                className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105 inline-flex items-center space-x-2"
              >
                <Share2 className="w-4 h-4" />
                <span>Facebook</span>
              </button>
              <button
                onClick={() => handleShare('instagram')}
                className="bg-gradient-to-r from-purple-500 to-pink-500 hover:from-purple-600 hover:to-pink-600 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105 inline-flex items-center space-x-2"
              >
                <Share2 className="w-4 h-4" />
                <span>Instagram</span>
              </button>
              <button
                onClick={() => handleShare('whatsapp')}
                className="bg-green-500 hover:bg-green-600 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105 inline-flex items-center space-x-2"
              >
                <MessageCircle className="w-4 h-4" />
                <span>WhatsApp</span>
              </button>
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
      <div className="mt-12 text-center">
        <h2 className="text-2xl font-bold text-white mb-4">Share your results!</h2>
        <div className="flex flex-wrap justify-center gap-4">
          <a href={`https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(window.location.href)}`} target="_blank" rel="noopener noreferrer" className="flex items-center space-x-2 px-4 py-2 rounded-xl font-semibold bg-white/10 hover:bg-blue-100">
            <img src="/FBlogo.png" alt="Facebook" className="w-6 h-6" />
            <span>Facebook</span>
          </a>
          <a href={`https://twitter.com/intent/tweet?url=${encodeURIComponent(window.location.href)}&text=${encodeURIComponent('Tailor Page recommended me these books based on my personality!')}`} target="_blank" rel="noopener noreferrer" className="flex items-center space-x-2 px-4 py-2 rounded-xl font-semibold bg-white/10 hover:bg-black/10">
            <img src="/xlogo.png" alt="X" className="w-6 h-6" />
            <span>X</span>
          </a>
          <a href={`https://www.linkedin.com/sharing/share-offsite/?url=${encodeURIComponent(window.location.href)}`} target="_blank" rel="noopener noreferrer" className="flex items-center space-x-2 px-4 py-2 rounded-xl font-semibold bg-white/10 hover:bg-blue-900/10">
            <img src="/linkedinlogo.png" alt="LinkedIn" className="w-6 h-6" />
            <span>LinkedIn</span>
          </a>
          <a href={`https://reddit.com/submit?url=${encodeURIComponent(window.location.href)}&title=${encodeURIComponent('Tailor Page recommended me these books based on my personality!')}`} target="_blank" rel="noopener noreferrer" className="flex items-center space-x-2 px-4 py-2 rounded-xl font-semibold bg-white/10 hover:bg-orange-100">
            <img src="/redditlogo.jfif" alt="Reddit" className="w-6 h-6" />
            <span>Reddit</span>
          </a>
          <a href={`https://api.whatsapp.com/send?text=${encodeURIComponent('Tailor Page recommended me these books based on my personality! ' + window.location.href)}`} target="_blank" rel="noopener noreferrer" className="flex items-center space-x-2 px-4 py-2 rounded-xl font-semibold bg-white/10 hover:bg-green-100">
            <img src="/whatsapplogo.jfif" alt="WhatsApp" className="w-6 h-6" />
            <span>WhatsApp</span>
          </a>
          <a href="https://www.instagram.com/" target="_blank" rel="noopener noreferrer" className="flex items-center space-x-2 px-4 py-2 rounded-xl font-semibold bg-white/10 hover:bg-pink-100">
            <img src="/instagramlogo.jfif" alt="Instagram" className="w-6 h-6" />
            <span>Instagram</span>
          </a>
        </div>
      </div>
    </div>
  );
};

export default ResultsPage;