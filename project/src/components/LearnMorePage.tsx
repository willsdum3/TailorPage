import React from 'react';
import { ArrowLeft, Brain, Target, Zap, BookOpen, Users, Star, CheckCircle, Lightbulb, TrendingUp, Heart, Sparkles } from 'lucide-react';
import Logo from './Logo';

interface LearnMorePageProps {
  onBack: () => void;
  onStartQuiz?: () => void;
}

const LearnMorePage: React.FC<LearnMorePageProps> = ({ onBack, onStartQuiz }) => {
  return (
    <div className="min-h-screen py-8 px-4 relative overflow-hidden">
      {/* Background Elements */}
      <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900" />
      <div className="absolute top-20 left-20 w-72 h-72 bg-purple-500/10 rounded-full blur-3xl" />
      <div className="absolute bottom-20 right-20 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl" />
      
      <div className="max-w-6xl mx-auto relative z-10">
        {/* Header */}
        <div className="text-center mb-16">
          <div className="mb-8">
            <Logo size="lg" showText={true} />
          </div>
          <button
            onClick={onBack}
            className="mb-8 bg-white/10 backdrop-blur-sm border border-white/20 hover:bg-white/20 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105 inline-flex items-center space-x-2"
          >
            <ArrowLeft className="w-4 h-4" />
            <span>Back to Home</span>
          </button>
          
          <div className="inline-flex items-center space-x-2 bg-white/10 backdrop-blur-sm border border-white/20 rounded-full px-4 py-2 mb-6">
            <Lightbulb className="w-4 h-4 text-amber-400" />
            <span className="text-sm font-medium text-white/80">How It Works</span>
          </div>
          
          <h1 className="text-5xl md:text-6xl font-bold text-white mb-6 leading-tight">
            The Science Behind <span className="bg-gradient-to-r from-amber-400 to-orange-500 bg-clip-text text-transparent">Perfect Matches</span>
          </h1>
          
          <p className="text-xl text-white/70 mb-8 max-w-4xl mx-auto leading-relaxed">
            Discover how our advanced AI system analyses your personality to recommend books that perfectly align with your reading preferences and psychological profile.
          </p>
        </div>

        {/* Main Content */}
        <div className="space-y-16">
          {/* AI Matching System */}
          <section className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8">
            <div className="flex items-center space-x-4 mb-8">
              <div className="w-12 h-12 bg-gradient-to-r from-amber-500 to-orange-600 rounded-xl flex items-center justify-center">
                <Target className="w-6 h-6 text-white" />
              </div>
              <h2 className="text-3xl font-bold text-white">Advanced Matching Algorithm</h2>
            </div>
            
            <div className="grid md:grid-cols-2 gap-8">
              <div>
                <h3 className="text-xl font-semibold text-white mb-4">Comprehensive Personality Mapping</h3>
                <p className="text-white/70 mb-6 leading-relaxed">
                  Our proprietary algorithm analyses your responses across all 5 personality dimensions to create a detailed psychological profile, then matches you with books based on:
                </p>
                
                <div className="space-y-3">
                  <div className="flex items-center space-x-3">
                    <CheckCircle className="w-5 h-5 text-green-400 flex-shrink-0" />
                    <span className="text-white/80">Thematic preferences based on core values and motivations</span>
                  </div>
                  <div className="flex items-center space-x-3">
                    <CheckCircle className="w-5 h-5 text-green-400 flex-shrink-0" />
                    <span className="text-white/80">Narrative complexity matching cognitive and lifestyle preferences</span>
                  </div>
                  <div className="flex items-center space-x-3">
                    <CheckCircle className="w-5 h-5 text-green-400 flex-shrink-0" />
                    <span className="text-white/80">Emotional resonance with character types and social dynamics</span>
                  </div>
                  <div className="flex items-center space-x-3">
                    <CheckCircle className="w-5 h-5 text-green-400 flex-shrink-0" />
                    <span className="text-white/80">Genre preferences aligned with psychological needs and traits</span>
                  </div>
                  <div className="flex items-center space-x-3">
                    <CheckCircle className="w-5 h-5 text-green-400 flex-shrink-0" />
                    <span className="text-white/80">Self-expression comfort level matching narrative styles</span>
                  </div>
                </div>
              </div>
              
              <div>
                <h3 className="text-xl font-semibold text-white mb-4">Precision Scoring System</h3>
                <p className="text-white/70 mb-6 leading-relaxed">
                  Each book in our database is scored across multiple criteria to ensure perfect personality-book matching:
                </p>
                
                <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-4 mb-4">
                  <h4 className="font-semibold text-amber-400 mb-3">Genre-Based Scoring</h4>
                  <div className="space-y-2 text-sm text-white/70">
                    <div>• <strong>Literary Fiction:</strong> High openness + self-expression</div>
                    <div>• <strong>Fantasy/Sci-Fi:</strong> High openness + low conscientiousness</div>
                    <div>• <strong>Self-Help:</strong> High conscientiousness + rational thinking</div>
                    <div>• <strong>Thrillers:</strong> High emotional stability + openness</div>
                  </div>
                </div>
                
                <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-4">
                  <h4 className="font-semibold text-amber-400 mb-3">Personality Adjustments</h4>
                  <div className="space-y-2 text-sm text-white/70">
                    <div>• <strong>Introverts:</strong> Character-driven, introspective books</div>
                    <div>• <strong>Extraverts:</strong> Action-packed, social themes</div>
                    <div>• <strong>High Agreeableness:</strong> Empathetic, socially conscious content</div>
                    <div>• <strong>High Openness:</strong> Experimental, diverse genres</div>
                  </div>
                </div>
              </div>
            </div>
          </section>

          {/* How to Use the Platform */}
          <section>
            <div className="text-center mb-12">
              <h2 className="text-4xl font-bold text-white mb-4">How to Use Tailor Page</h2>
              <p className="text-xl text-white/70 max-w-3xl mx-auto">
                Follow these simple steps to discover your perfect reading matches
              </p>
            </div>

            <div className="grid md:grid-cols-3 gap-8">
              <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6 text-center group hover:bg-white/15 transition-all duration-300">
                <div className="w-16 h-16 bg-gradient-to-r from-blue-500 to-purple-600 rounded-2xl flex items-center justify-center mx-auto mb-6 group-hover:scale-110 transition-transform duration-300">
                  <span className="text-2xl font-bold text-white">25</span>
                </div>
                <h3 className="text-xl font-bold text-white mb-4">Complete 25-Statement Assessment</h3>
                <p className="text-white/70 leading-relaxed mb-4">
                  Answer 25 carefully crafted statements designed by psychology experts to create a comprehensive personality profile across 5 key dimensions.
                </p>
                <div className="text-sm text-amber-400 font-medium">~3-5 minutes</div>
              </div>

              <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6 text-center group hover:bg-white/15 transition-all duration-300">
                <div className="w-16 h-16 bg-gradient-to-r from-purple-500 to-pink-600 rounded-2xl flex items-center justify-center mx-auto mb-6 group-hover:scale-110 transition-transform duration-300">
                  <Brain className="w-8 h-8 text-white" />
                </div>
                <h3 className="text-xl font-bold text-white mb-4">Advanced AI Analysis</h3>
                <p className="text-white/70 leading-relaxed mb-4">
                  Our sophisticated AI analyses your responses across 5 personality dimensions and matches them with our curated database of over 100 books.
                </p>
                <div className="text-sm text-amber-400 font-medium">Instant results</div>
              </div>

              <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6 text-center group hover:bg-white/15 transition-all duration-300">
                <div className="w-16 h-16 bg-gradient-to-r from-green-500 to-teal-600 rounded-2xl flex items-center justify-center mx-auto mb-6 group-hover:scale-110 transition-transform duration-300">
                  <BookOpen className="w-8 h-8 text-white" />
                </div>
                <h3 className="text-xl font-bold text-white mb-4">Get Personalized Recommendations</h3>
                <h3 className="text-xl font-bold text-white mb-4">Get Personalised Recommendations</h3>
                <p className="text-white/70 leading-relaxed mb-4">
                  Receive 6 carefully selected book recommendations with detailed explanations of why each book matches your personality.
                </p>
                <div className="text-sm text-amber-400 font-medium">Tailored for you</div>
              </div>
            </div>
          </section>

          {/* Features Overview */}
          <section className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8">
            <div className="text-center mb-12">
              <h2 className="text-4xl font-bold text-white mb-4">Platform Features</h2>
              <p className="text-xl text-white/70">
                Everything you need for the perfect book discovery experience
              </p>
            </div>

            <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
              <div className="text-center group">
                <div className="w-12 h-12 bg-gradient-to-r from-amber-500 to-orange-600 rounded-xl flex items-center justify-center mx-auto mb-4 group-hover:scale-110 transition-transform duration-300">
                  <Heart className="w-6 h-6 text-white" />
                </div>
                <h3 className="font-semibold text-white mb-2">Favourites System</h3>
                <p className="text-sm text-white/70">Save and organise your favourite book recommendations</p>
              </div>

              <div className="text-center group">
                <div className="w-12 h-12 bg-gradient-to-r from-blue-500 to-purple-600 rounded-xl flex items-center justify-center mx-auto mb-4 group-hover:scale-110 transition-transform duration-300">
                  <Users className="w-6 h-6 text-white" />
                </div>
                <h3 className="font-semibold text-white mb-2">Social Sharing</h3>
                <p className="text-sm text-white/70">Share your results and inspire friends to discover new books</p>
              </div>

              <div className="text-center group">
                <div className="w-12 h-12 bg-gradient-to-r from-green-500 to-teal-600 rounded-xl flex items-center justify-center mx-auto mb-4 group-hover:scale-110 transition-transform duration-300">
                  <TrendingUp className="w-6 h-6 text-white" />
                </div>
                <h3 className="font-semibold text-white mb-2">Trending Content</h3>
                <p className="text-sm text-white/70">Explore what's popular and discover trending authors</p>
              </div>

              <div className="text-center group">
                <div className="w-12 h-12 bg-gradient-to-r from-purple-500 to-pink-600 rounded-xl flex items-center justify-center mx-auto mb-4 group-hover:scale-110 transition-transform duration-300">
                  <Star className="w-6 h-6 text-white" />
                </div>
                <h3 className="font-semibold text-white mb-2">Celebrity Tester</h3>
                <p className="text-sm text-white/70">Test your knowledge about celebrities and their reading habits</p>
              </div>
            </div>
          </section>

          {/* Why It Works */}
          <section>
            <div className="text-center mb-12">
              <h2 className="text-4xl font-bold text-white mb-4">Why Our Recommendations Work</h2>
              <p className="text-xl text-white/70 max-w-3xl mx-auto">
                The psychology and data science behind successful book matching
              </p>
            </div>

            <div className="grid md:grid-cols-2 gap-8">
              <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6">
                <div className="flex items-center space-x-3 mb-4">
                  <Target className="w-8 h-8 text-amber-400" />
                  <h3 className="text-xl font-semibold text-white">Multi-Dimensional Compatibility</h3>
                </div>
                <p className="text-white/70 leading-relaxed mb-4">
                  Books that align with multiple aspects of your personality create deeper emotional connections and more satisfying reading experiences. Our 5-dimension system ensures comprehensive compatibility.
                </p>
                <div className="text-sm text-amber-400 font-medium">97% user satisfaction rate</div>
              </div>

              <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6">
                <div className="flex items-center space-x-3 mb-4">
                  <Zap className="w-8 h-8 text-amber-400" />
                  <h3 className="text-xl font-semibold text-white">Advanced Machine Learning</h3>
                </div>
                <p className="text-white/70 leading-relaxed mb-4">
                  Our AI system uses advanced machine learning algorithms trained on thousands of personality-book pairings, continuously improving accuracy through user feedback and reading patterns.
                </p>
                <div className="text-sm text-amber-400 font-medium">100+ books analyzed</div>
              </div>
            </div>
          </section>

          {/* Call to Action */}
          <section className="bg-gradient-to-r from-amber-500/20 to-orange-600/20 backdrop-blur-xl border border-amber-500/30 rounded-2xl p-8 text-center">
            <div className="mb-8">
              <div className="inline-flex items-center space-x-2 mb-4">
                <Sparkles className="w-6 h-6 text-amber-400" />
                <h2 className="text-3xl font-bold text-white">Ready to Discover Your Perfect Books?</h2>
              </div>
              <p className="text-xl text-white/80 mb-8 max-w-2xl mx-auto">
                Join thousands of readers who have found their next favourite book through our AI-powered recommendation system.
              </p>
            </div>

            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <button
                onClick={onStartQuiz || onBack}
                className="bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-300 transform hover:scale-105 hover:shadow-2xl inline-flex items-center justify-center space-x-2"
              >
                <span>Start Your Journey</span>
                <ArrowLeft className="w-5 h-5 rotate-180" />
              </button>
            </div>
          </section>
        </div>
      </div>
    </div>
  );
};

export default LearnMorePage;