import React from 'react';
import { Book, Users, Heart, Brain, Star, ArrowRight, Sparkles, Target, Zap, BookOpen, UserCheck } from 'lucide-react';
import Logo from './Logo';

interface WelcomePageProps {
  onStartQuiz: () => void;
  onResumeQuiz: () => void;
  onLearnMore: () => void;
  hasQuizProgress?: boolean;
  isLoggedIn?: boolean;
  hasCompletedQuiz?: boolean;
  onGenerateNewBooks?: () => void;
  onSignIn?: () => void;
  onSignUp?: () => void;
  onAuthPrompt?: (mode: 'login' | 'signup', feature?: string) => void;
  onNavigateToProfile?: () => void;
  user?: {
    id: string;
    name: string;
    username: string;
    email: string;
    imageUrl?: string;
  } | null;
}

const WelcomePage: React.FC<WelcomePageProps> = ({ 
  onStartQuiz, 
  onResumeQuiz, 
  onLearnMore, 
  hasQuizProgress = false, 
  isLoggedIn = false, 
  hasCompletedQuiz = false, 
  onGenerateNewBooks,
  onSignIn,
  onSignUp,
  onAuthPrompt,
  onNavigateToProfile,
  user
}) => {
  // Debug logging to understand the state
  console.log('WelcomePage render - isLoggedIn:', isLoggedIn, 'hasCompletedQuiz:', hasCompletedQuiz, 'hasQuizProgress:', hasQuizProgress);
  console.log('WelcomePage user data:', user);
  console.log('WelcomePage user imageUrl:', user?.imageUrl);
  return (
    <div className="min-h-screen flex items-center justify-center p-4 relative overflow-hidden">
      {/* Background Elements */}
      <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900" />
      <div className="absolute top-20 left-20 w-72 h-72 bg-purple-500/10 rounded-full blur-3xl" />
      <div className="absolute bottom-20 right-20 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl" />
      
      {/* Top Center Profile Picture or Sign In Button */}
      <div className="absolute top-6 left-1/2 transform -translate-x-1/2 z-20">
        {isLoggedIn && user ? (
          <div className="flex items-center space-x-3">
            <div className="relative">
              {user.imageUrl ? (
                <img
                  src={user.imageUrl}
                  alt={`${user.name}'s profile`}
                  className="w-12 h-12 rounded-full border-2 border-white/20 object-cover"
                />
              ) : (
                <div className="w-12 h-12 rounded-full bg-gradient-to-r from-amber-500 to-orange-600 flex items-center justify-center border-2 border-white/20">
                  <span className="text-white font-semibold text-lg">
                    {user.name.charAt(0).toUpperCase()}
                  </span>
                </div>
              )}
            </div>
            <div className="text-white">
              <div className="font-semibold text-sm">{user.name}</div>
              {onNavigateToProfile ? (
                <button
                  onClick={onNavigateToProfile}
                  className="text-xs text-white/70 hover:text-amber-300 transition-colors duration-200 cursor-pointer"
                  title="Click to view your profile"
                >
                  @{user.username}
                </button>
              ) : (
                <div className="text-xs text-white/70">@{user.username}</div>
              )}
            </div>
          </div>
        ) : (
          <button
            onClick={onSignIn}
            className="bg-white/10 hover:bg-white/20 backdrop-blur-sm border border-white/20 text-white px-6 py-3 rounded-xl font-semibold text-base transition-all duration-300 transform hover:scale-105"
          >
            Sign In
          </button>
        )}
      </div>
      
      <div className="max-w-7xl mx-auto relative z-10">
        <div className="grid lg:grid-cols-2 gap-16 items-center">
          {/* Left Content */}
          <div className="text-left">
            <div className="mb-8">
              <div className="mb-8">
                <Logo size="lg" showText={true} />
              </div>
              
              <h1 className="text-4xl lg:text-6xl xl:text-7xl font-bold text-white mb-8 leading-tight tracking-tight">
                <span className="block mb-2">Discover Your</span>
                <span className="bg-gradient-to-r from-amber-400 via-orange-500 to-amber-500 bg-clip-text text-transparent drop-shadow-sm">Perfect Books</span>
              </h1>
              
              <p className="text-lg lg:text-xl text-white/80 mb-10 leading-relaxed max-w-2xl font-medium">
                Get personalized book recommendations tailored to your unique personality through our advanced AI-powered quiz system.
              </p>
            </div>

            {/* Stats */}
            {/* Removed stats section */}

            {/* CTA Buttons */}
            <div className="flex flex-col sm:flex-row gap-4">
              {isLoggedIn && hasCompletedQuiz && onGenerateNewBooks ? (
                <button
                  onClick={onGenerateNewBooks}
                  className="bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-300 transform hover:scale-105 hover:shadow-2xl inline-flex items-center justify-center space-x-2 group"
                >
                  <span>Generate New Books</span>
                  <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
                </button>
              ) : hasCompletedQuiz && !isLoggedIn ? (
                <button
                  onClick={() => onAuthPrompt?.('login', 'access profile')}
                  className="bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-600 hover:to-purple-700 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-300 transform hover:scale-105 hover:shadow-2xl inline-flex items-center justify-center space-x-2 group"
                >
                  <UserCheck className="w-5 h-5" />
                  <span>View Profile</span>
                </button>
              ) : (
                <button
                  onClick={hasQuizProgress ? onResumeQuiz : onStartQuiz}
                  className="bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-300 transform hover:scale-105 hover:shadow-2xl inline-flex items-center justify-center space-x-2 group"
                >
                  <span>{hasQuizProgress ? 'Resume Quiz' : 'Start Discovery'}</span>
                  <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
                </button>
              )}
              <button
                onClick={onLearnMore}
                className="bg-white/10 hover:bg-white/20 backdrop-blur-sm border border-white/20 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-300 transform hover:scale-105"
              >
                Learn More
              </button>
            </div>
          </div>

          {/* Right Content - Feature Cards */}
          <div className="relative">
            <div className="grid gap-6">
              {/* Main Feature Card */}
              <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 hover:bg-white/15 transition-all duration-300 transform hover:scale-105">
                <div className="flex items-center space-x-4 mb-6">
                  <div className="w-12 h-12 bg-gradient-to-r from-amber-500 to-orange-600 rounded-xl flex items-center justify-center">
                    <Brain className="w-6 h-6 text-white" />
                  </div>
                  <div>
                    <h3 className="text-xl font-bold text-white">Smart Algorithm</h3>
                    <p className="text-white/70">AI-powered personality analysis</p>
                  </div>
                </div>
                <p className="text-white/70 leading-relaxed">
                  Our advanced algorithm analyses your personality traits to recommend books that perfectly match your reading preferences and interests.
                </p>
              </div>

              {/* Secondary Feature Cards */}
              <div className="grid grid-cols-2 gap-4">
                <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-xl p-6 hover:bg-white/15 transition-all duration-300">
                  <Target className="w-8 h-8 text-amber-400 mb-4" />
                  <h4 className="font-semibold text-white mb-2">Personalised</h4>
                  <p className="text-sm text-white/70">Tailored to your unique taste</p>
                </div>
                
                <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-xl p-6 hover:bg-white/15 transition-all duration-300">
                  <Zap className="w-8 h-8 text-amber-400 mb-4" />
                  <h4 className="font-semibold text-white mb-2">Instant</h4>
                  <p className="text-sm text-white/70">Get results in seconds</p>
                </div>
              </div>
            </div>

            {/* Floating Elements */}
            <div className="absolute -top-4 -right-4 w-20 h-20 bg-gradient-to-r from-purple-500/20 to-pink-500/20 rounded-full blur-xl" />
            <div className="absolute -bottom-8 -left-8 w-32 h-32 bg-gradient-to-r from-blue-500/20 to-cyan-500/20 rounded-full blur-xl" />
          </div>
        </div>


      </div>
    </div>
  );
};

export default WelcomePage;