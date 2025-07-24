import React from 'react';
import { Book, Users, Heart, Brain, Star, ArrowRight, Sparkles, Target, Zap, BookOpen } from 'lucide-react';
import Logo from './Logo';

interface WelcomePageProps {
  onStartQuiz: () => void;
  onLearnMore: () => void;
  hasQuizProgress?: boolean;
  isLoggedIn?: boolean;
  hasCompletedQuiz?: boolean;
  onGenerateNewBooks?: () => void;
}

const WelcomePage: React.FC<WelcomePageProps> = ({ onStartQuiz, onLearnMore, hasQuizProgress = false, isLoggedIn = false, hasCompletedQuiz = false, onGenerateNewBooks }) => {
  return (
    <div className="min-h-screen flex items-center justify-center p-4 relative overflow-hidden">
      {/* Background Elements */}
      <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900" />
      <div className="absolute top-20 left-20 w-72 h-72 bg-purple-500/10 rounded-full blur-3xl" />
      <div className="absolute bottom-20 right-20 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl" />
      
      <div className="max-w-7xl mx-auto relative z-10">
        <div className="grid lg:grid-cols-2 gap-16 items-center">
          {/* Left Content */}
          <div className="text-left">
            <div className="mb-8">
              <div className="mb-8">
                <Logo size="lg" showText={true} />
              </div>
              
              <div className="inline-flex items-center space-x-2 bg-white/10 backdrop-blur-sm border border-white/20 rounded-full px-4 py-2 mb-6">
                <Sparkles className="w-4 h-4 text-amber-400" />
                <span className="text-sm font-medium text-white/80">AI-Powered Recommendations</span>
              </div>
              
              <h1 className="text-5xl lg:text-6xl font-bold text-white mb-6 leading-tight">
                Discover Your
                <span className="block bg-gradient-to-r from-amber-400 to-orange-500 bg-clip-text text-transparent">
                  Perfect Books
                </span>
              </h1>
              
              <p className="text-xl text-white/70 mb-8 leading-relaxed max-w-lg">
                Get personalised book recommendations tailored to your unique personality through our advanced AI-powered quiz system.
              </p>
            </div>

            {/* Stats */}
            <div className="grid grid-cols-3 gap-8 mb-12">
              <div>
                <div className="text-3xl font-bold text-white mb-1">10K+</div>
                <div className="text-sm text-white/70">Books analyzed</div>
              </div>
              <div>
                <div className="text-3xl font-bold text-white mb-1">95%</div>
                <div className="text-sm text-white/70">Match accuracy</div>
              </div>
            </div>

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
              ) : (
                <button
                  onClick={onStartQuiz}
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

        {/* How It Works Section */}
        <div className="mt-24">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-white mb-4">How It Works</h2>
            <p className="text-xl text-white/70 max-w-2xl mx-auto">
              Three simple steps to discover books perfectly matched to your personality
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            <div className="text-center group">
              <div className="relative mb-6">
                <div className="w-16 h-16 bg-gradient-to-r from-amber-500 to-orange-600 rounded-2xl flex items-center justify-center mx-auto mb-4 group-hover:scale-110 transition-transform duration-300">
                  <span className="text-2xl font-bold text-white">50</span>
                </div>
                <div className="absolute top-8 left-1/2 w-full h-0.5 bg-gradient-to-r from-transparent via-white/20 to-transparent hidden md:block" />
              </div>
              <h3 className="text-xl font-bold text-white mb-3">Complete Assessment</h3>
              <p className="text-white/70 leading-relaxed">
                Answer 50 carefully crafted statements across 10 personality dimensions in just 5-7 minutes
              </p>
            </div>

            <div className="text-center group">
              <div className="relative mb-6">
                <div className="w-16 h-16 bg-gradient-to-r from-purple-500 to-pink-600 rounded-2xl flex items-center justify-center mx-auto mb-4 group-hover:scale-110 transition-transform duration-300">
                  <Brain className="w-8 h-8 text-white" />
                </div>
                <div className="absolute top-8 left-1/2 w-full h-0.5 bg-gradient-to-r from-transparent via-white/20 to-transparent hidden md:block" />
              </div>
              <h3 className="text-xl font-bold text-white mb-3">Advanced AI Analysis</h3>
              <p className="text-white/70 leading-relaxed">
                Our sophisticated AI analyses your responses across 10 dimensions to create a comprehensive personality profile
              </p>
            </div>

            <div className="text-center group">
              <div className="relative mb-6">
                <div className="w-16 h-16 bg-gradient-to-r from-green-500 to-teal-600 rounded-2xl flex items-center justify-center mx-auto mb-4 group-hover:scale-110 transition-transform duration-300">
                  <BookOpen className="w-8 h-8 text-white" />
                </div>
              </div>
              <h3 className="text-xl font-bold text-white mb-3">Personalised Matches</h3>
              <p className="text-white/70 leading-relaxed">
                Receive 6 carefully selected book recommendations with detailed explanations of why each matches your unique personality
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default WelcomePage;