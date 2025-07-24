import React from 'react';
import { ArrowLeft, Construction, Sparkles, Brain, Target, User, Heart, Shield, Zap, Users, Eye, ChevronDown, ChevronUp, Book } from 'lucide-react';
import { PersonalityProfile, BookRecommendation } from '../types';
import { getBookRecommendations } from '../utils/bookRecommendations';
import Logo from './Logo';

interface PlaceholderPageProps {
  title: string;
  description: string;
  onBack: () => void;
  profile?: PersonalityProfile | null;
  onNewRecommendations?: (recommendations: BookRecommendation[]) => void;
}

const PlaceholderPage: React.FC<PlaceholderPageProps> = ({ title, description, onBack, profile, onNewRecommendations }) => {
  const [expandedPersonality, setExpandedPersonality] = React.useState(false);
  const [isGenerating, setIsGenerating] = React.useState(false);

  const getPersonalityTraitInfo = (trait: string, score: number) => {
    const traitInfo = {
      openness: {
        name: 'Openness to Experience',
        icon: Brain,
        description: 'Enjoys trying new things and creative activities',
        lowDesc: 'Prefers familiar experiences and routines',
        highDesc: 'Highly adventurous and open to new experiences'
      },
      conscientiousness: {
        name: 'Conscientiousness',
        icon: Target,
        description: 'Plans ahead and stays organized',
        lowDesc: 'More spontaneous and flexible approach',
        highDesc: 'Highly organized and methodical'
      },
      extraversion: {
        name: 'Extraversion',
        icon: User,
        description: 'Enjoys social interaction and being around people',
        lowDesc: 'More introverted, prefers solitude and reflection',
        highDesc: 'Very extroverted, energized by social interaction'
      },
      agreeableness: {
        name: 'Agreeableness',
        icon: Heart,
        description: 'Considers others\' perspectives and avoids conflict',
        lowDesc: 'More independent and assertive',
        highDesc: 'Highly empathetic and considerate'
      },
      emotionalStability: {
        name: 'Emotional Stability',
        icon: Shield,
        description: 'Stays calm under pressure and bounces back from setbacks',
        lowDesc: 'More emotionally reactive to stress',
        highDesc: 'Exceptionally calm and composed'
      },
      rationalThinking: {
        name: 'Rational Thinking',
        icon: Brain,
        description: 'Relies on logic and analysis when making decisions',
        lowDesc: 'More intuitive and emotion-based decision making',
        highDesc: 'Highly analytical and logical approach'
      },
      coreValues: {
        name: 'Core Values & Motivation',
        icon: Heart,
        description: 'Driven by personal values and meaningful goals',
        lowDesc: 'More pragmatic and flexible in values',
        highDesc: 'Strongly principled and value-driven'
      },
      lifestyle: {
        name: 'Lifestyle Preferences',
        icon: Zap,
        description: 'Prefers fast-paced, busy lifestyle with variety',
        lowDesc: 'Prefers calm, predictable, routine-based lifestyle',
        highDesc: 'Enjoys fast-paced, dynamic, and varied lifestyle'
      },
      socialStyle: {
        name: 'Social Style',
        icon: Users,
        description: 'Adapts behavior and makes decisions quickly in social settings',
        lowDesc: 'More consistent, thoughtful social approach',
        highDesc: 'Highly adaptable and quick in social situations'
      },
      selfExpression: {
        name: 'Self-Expression',
        icon: Eye,
        description: 'Comfortable expressing opinions and being vulnerable',
        lowDesc: 'More reserved and private in self-expression',
        highDesc: 'Very open and authentic in self-expression'
      }
    };

    return traitInfo[trait as keyof typeof traitInfo];
  };

  const getScoreColor = (score: number) => {
    if (score <= 15) return 'from-red-500 to-red-600';
    if (score <= 18) return 'from-yellow-500 to-orange-500';
    if (score <= 21) return 'from-blue-500 to-blue-600';
    return 'from-green-500 to-green-600';
  };

  const getScoreDescription = (score: number) => {
    if (score <= 15) return 'Low';
    if (score <= 18) return 'Moderate';
    if (score <= 21) return 'High';
    return 'Very High';
  };

  const getPersonalityDescription = (profile: PersonalityProfile) => {
    let description = "Based on your personality assessment, you are ";
    
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

  const handleGenerateNewBooks = async () => {
    if (!profile || !onNewRecommendations) return;
    
    setIsGenerating(true);
    
    // Simulate API call delay for better UX
    await new Promise(resolve => setTimeout(resolve, 1500));
    
    // Generate new recommendations
    const newRecommendations = getBookRecommendations(profile);
    onNewRecommendations(newRecommendations);
    
    setIsGenerating(false);
  };

  // If we have a profile, show the personality analysis
  if (profile) {
    return (
      <div className="min-h-screen py-8 px-4 relative overflow-hidden">
        {/* Background Elements */}
        <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900" />
        <div className="absolute top-20 left-20 w-72 h-72 bg-purple-500/10 rounded-full blur-3xl" />
        <div className="absolute bottom-20 right-20 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl" />
        
        <div className="max-w-6xl mx-auto relative z-10">
          {/* Header */}
          <div className="text-center mb-12">
            <button
              onClick={onBack}
              className="mb-8 bg-white/10 backdrop-blur-sm border border-white/20 hover:bg-white/20 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105 inline-flex items-center space-x-2"
            >
              <ArrowLeft className="w-4 h-4" />
              <span>Back to Home</span>
            </button>
            
            <div className="mb-8">
              <Logo size="lg" showText={true} />
            </div>
            
            <div className="inline-flex items-center space-x-2 bg-white/10 backdrop-blur-sm border border-white/20 rounded-full px-4 py-2 mb-6">
              <Brain className="w-4 h-4 text-amber-400" />
              <span className="text-sm font-medium text-white/80">Your Personality Analysis</span>
            </div>
            
            <h1 className="text-5xl md:text-6xl font-bold text-white mb-6 leading-tight">
              Your
              <span className="block bg-gradient-to-r from-amber-400 to-orange-500 bg-clip-text text-transparent">
                Profile
              </span>
            </h1>
            
            <p className="text-xl text-white/70 mb-8 max-w-4xl mx-auto leading-relaxed">
              Take our personality quiz to unlock your personalised reading profile and discover books that perfectly match who you are.
            </p>
          </div>

          {/* Personality Profile */}
          <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 mb-8">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-3xl font-bold text-white flex items-center space-x-3">
                <Brain className="w-8 h-8 text-amber-400" />
                <span>Detailed Personality Breakdown</span>
              </h2>
              <button
                onClick={() => setExpandedPersonality(!expandedPersonality)}
                className="bg-white/10 hover:bg-white/20 text-white px-4 py-2 rounded-xl transition-all duration-300 flex items-center space-x-2"
              >
                <span>{expandedPersonality ? 'Show Less' : 'Show Details'}</span>
                {expandedPersonality ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
              </button>
            </div>

            <div className="grid md:grid-cols-2 gap-6">
              {Object.entries(profile).map(([trait, score]) => {
                const traitInfo = getPersonalityTraitInfo(trait, score);
                if (!traitInfo) return null;
                
                const IconComponent = traitInfo.icon;
                
                return (
                  <div key={trait} className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-4">
                    <div className="flex items-center space-x-3 mb-3">
                      <div className={`w-10 h-10 bg-gradient-to-r ${getScoreColor(score)} rounded-lg flex items-center justify-center`}>
                        <IconComponent className="w-5 h-5 text-white" />
                      </div>
                      <div className="flex-1">
                        <h3 className="font-semibold text-white">{traitInfo.name}</h3>
                        <div className="flex items-center space-x-2">
                          <div className="flex-1 bg-white/20 rounded-full h-2">
                            <div 
                              className={`bg-gradient-to-r ${getScoreColor(score)} h-2 rounded-full transition-all duration-500`}
                              style={{ width: `${(score / 25) * 100}%` }}
                            />
                          </div>
                          <span className="text-white/80 text-sm font-medium">{score}/25</span>
                        </div>
                      </div>
                    </div>
                    
                    {expandedPersonality && (
                      <div className="mt-3 pt-3 border-t border-white/10">
                        <p className="text-white/70 text-sm mb-2">{traitInfo.description}</p>
                        <p className="text-white/60 text-xs">
                          <span className="font-medium text-amber-400">{getScoreDescription(score)}:</span>{' '}
                          {score <= 12 ? traitInfo.lowDesc : traitInfo.highDesc}
                        </p>
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </div>

          {/* Insights Section */}
          <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 mb-8">
            <h2 className="text-3xl font-bold text-white mb-6 flex items-center space-x-3">
              <Sparkles className="w-8 h-8 text-amber-400" />
              <span>Key Insights</span>
            </h2>
            
            <div className="grid md:grid-cols-2 gap-6">
              <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6">
                <h3 className="text-xl font-semibold text-white mb-4">Your Strengths</h3>
                <div className="space-y-3">
                  {Object.entries(profile)
                    .filter(([_, score]) => score >= 20)
                    .slice(0, 3)
                    .map(([trait, score]) => {
                      const traitInfo = getPersonalityTraitInfo(trait, score);
                      if (!traitInfo) return null;
                      return (
                        <div key={trait} className="flex items-center space-x-3">
                          <div className="w-2 h-2 bg-green-400 rounded-full"></div>
                          <span className="text-white/80">{traitInfo.name}</span>
                          <span className="text-green-400 text-sm font-medium">({score}/25)</span>
                        </div>
                      );
                    })}
                </div>
              </div>
              
              <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6">
                <h3 className="text-xl font-semibold text-white mb-4">Growth Areas</h3>
                <div className="space-y-3">
                  {Object.entries(profile)
                    .filter(([_, score]) => score <= 15)
                    .slice(0, 3)
                    .map(([trait, score]) => {
                      const traitInfo = getPersonalityTraitInfo(trait, score);
                      if (!traitInfo) return null;
                      return (
                        <div key={trait} className="flex items-center space-x-3">
                          <div className="w-2 h-2 bg-amber-400 rounded-full"></div>
                          <span className="text-white/80">{traitInfo.name}</span>
                          <span className="text-amber-400 text-sm font-medium">({score}/25)</span>
                        </div>
                      );
                    })}
                </div>
              </div>
            </div>
          </div>

          {/* Call to Action */}
          <div className="grid md:grid-cols-2 gap-6">
            <div className="bg-gradient-to-r from-amber-500/20 to-orange-600/20 backdrop-blur-xl border border-amber-500/30 rounded-2xl p-8 text-center">
              <div className="mb-6">
                <Sparkles className="w-12 h-12 text-amber-400 mx-auto mb-4" />
                <h2 className="text-2xl font-bold text-white mb-3">Get New Book Recommendations</h2>
                <p className="text-white/80 mb-6">
                  Generate 6 fresh book recommendations perfectly matched to your personality profile.
                </p>
              </div>
              
              <button
                onClick={handleGenerateNewBooks}
                disabled={isGenerating || !onNewRecommendations}
                className="bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 disabled:from-amber-500/50 disabled:to-orange-600/50 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-300 transform hover:scale-105 disabled:transform-none disabled:cursor-not-allowed hover:shadow-2xl inline-flex items-center space-x-2"
              >
                {isGenerating ? (
                  <>
                    <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                    <span>Generating...</span>
                  </>
                ) : (
                  <>
                    <Sparkles className="w-5 h-5" />
                    <span>Generate New Books</span>
                  </>
                )}
              </button>
            </div>
            
            <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 text-center">
              <div className="mb-6">
                <Brain className="w-12 h-12 text-blue-400 mx-auto mb-4" />
                <h2 className="text-2xl font-bold text-white mb-3">Retake Personality Quiz</h2>
                <p className="text-white/80 mb-6">
                  Want to update your personality profile? Retake the quiz to get fresh insights.
                </p>
              </div>
              
              <button
                onClick={onBack}
                className="bg-white/10 hover:bg-white/20 backdrop-blur-sm border border-white/20 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-300 transform hover:scale-105 inline-flex items-center space-x-2"
              >
                <Brain className="w-5 h-5" />
                <span>Take Quiz Again</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // Default placeholder content for pages without profile data
  return (
    <div className="min-h-screen flex items-center justify-center p-4 relative overflow-hidden">
      {/* Background Elements */}
      <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900" />
      <div className="absolute top-20 left-20 w-72 h-72 bg-purple-500/10 rounded-full blur-3xl" />
      <div className="absolute bottom-20 right-20 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl" />
      
      <div className="max-w-2xl mx-auto text-center relative z-10">
        {/* Header */}
        <div className="text-center mb-12">
          <button
            onClick={onBack}
            className="mb-8 bg-white/10 backdrop-blur-sm border border-white/20 hover:bg-white/20 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105 inline-flex items-center space-x-2"
          >
            <ArrowLeft className="w-4 h-4" />
            <span>Back to Home</span>
          </button>
          
          <div className="mb-8">
            <Logo size="lg" showText={true} />
          </div>
          
          <div className="inline-flex items-center space-x-2 bg-white/10 backdrop-blur-sm border border-white/20 rounded-full px-4 py-2 mb-6">
            <User className="w-4 h-4 text-amber-400" />
            <span className="text-sm font-medium text-white/80">Your Profile</span>
          </div>
          
          <h1 className="text-5xl md:text-6xl font-bold text-white mb-6 leading-tight">
            Create Your
            <span className="block bg-gradient-to-r from-amber-400 to-orange-500 bg-clip-text text-transparent">
              Reading Profile
            </span>
          </h1>
          
          <p className="text-xl text-white/70 mb-8 max-w-3xl mx-auto leading-relaxed">
            Take our personality quiz to unlock personalised book recommendations and detailed insights about your reading preferences.
          </p>
        </div>

        {/* What is Tailor Page */}
        <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 mb-8 text-left">
          <div className="flex items-center space-x-3 mb-6">
            <Sparkles className="w-8 h-8 text-amber-400" />
            <h2 className="text-3xl font-bold text-white">What is Tailor Page?</h2>
          </div>
          
          <div className="space-y-6">
            <p className="text-white/80 leading-relaxed">
              Tailor Page is an AI-powered book recommendation platform that analyses your unique personality to suggest books you'll truly love. Unlike generic bestseller lists, we create a personalised reading experience just for you.
            </p>
            
            <div className="grid md:grid-cols-2 gap-6">
              <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-4">
                <div className="flex items-center space-x-3 mb-3">
                  <Brain className="w-6 h-6 text-blue-400" />
                  <h3 className="font-semibold text-white">Advanced AI Analysis</h3>
                </div>
                <p className="text-white/70 text-sm">
                  Our sophisticated algorithm analyses 10 personality dimensions to understand your reading preferences and psychological profile.
                </p>
              </div>
              
              <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-4">
                <div className="flex items-center space-x-3 mb-3">
                  <Target className="w-6 h-6 text-green-400" />
                  <h3 className="font-semibold text-white">Personalised Matches</h3>
                </div>
                <p className="text-white/70 text-sm">
                  Get 6 carefully selected books with detailed explanations of why each one perfectly matches your unique personality.
                </p>
              </div>
              
              <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-4">
                <div className="flex items-center space-x-3 mb-3">
                  <Heart className="w-6 h-6 text-red-400" />
                  <h3 className="font-semibold text-white">Save Favourites</h3>
                </div>
                <p className="text-white/70 text-sm">
                  Build your personal library by saving books you love and want to read later.
                </p>
              </div>
              
              <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-4">
                <div className="flex items-center space-x-3 mb-3">
                  <Users className="w-6 h-6 text-purple-400" />
                  <h3 className="font-semibold text-white">Share & Discover</h3>
                </div>
                <p className="text-white/70 text-sm">
                  Share your results with friends and explore trending books and authors from around the world.
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* How It Works */}
        <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 mb-8 text-left">
          <div className="flex items-center space-x-3 mb-6">
            <Zap className="w-8 h-8 text-amber-400" />
            <h2 className="text-3xl font-bold text-white">How It Works</h2>
          </div>
          
          <div className="grid md:grid-cols-3 gap-6">
            <div className="text-center">
              <div className="w-16 h-16 bg-gradient-to-r from-amber-500 to-orange-600 rounded-2xl flex items-center justify-center mx-auto mb-4">
                <span className="text-2xl font-bold text-white">50</span>
              </div>
              <h3 className="text-lg font-bold text-white mb-2">Take the Quiz</h3>
              <p className="text-white/70 text-sm">
                Answer 50 carefully crafted questions about your personality, preferences, and lifestyle in just 5-7 minutes.
              </p>
            </div>
            
            <div className="text-center">
              <div className="w-16 h-16 bg-gradient-to-r from-purple-500 to-pink-600 rounded-2xl flex items-center justify-center mx-auto mb-4">
                <Brain className="w-8 h-8 text-white" />
              </div>
              <h3 className="text-lg font-bold text-white mb-2">AI Analysis</h3>
              <p className="text-white/70 text-sm">
                Our AI analyses your responses across 10 personality dimensions to create your unique reading profile.
              </p>
            </div>
            
            <div className="text-center">
              <div className="w-16 h-16 bg-gradient-to-r from-green-500 to-teal-600 rounded-2xl flex items-center justify-center mx-auto mb-4">
                <Book className="w-8 h-8 text-white" />
              </div>
              <h3 className="text-lg font-bold text-white mb-2">Get Books</h3>
              <p className="text-white/70 text-sm">
                Receive personalised book recommendations with detailed explanations of why each book matches you.
              </p>
            </div>
          </div>
        </div>

        {/* Call to Action */}
        <div className="mb-8">
          <div className="bg-gradient-to-r from-amber-500/20 to-orange-600/20 backdrop-blur-xl border border-amber-500/30 rounded-2xl p-8 text-center">
            <div className="mb-6">
              <div className="inline-flex items-center space-x-2 mb-4">
                <Sparkles className="w-6 h-6 text-amber-400" />
                <h2 className="text-3xl font-bold text-white">Ready to Start?</h2>
              </div>
              <p className="text-white/80 mb-8 max-w-2xl mx-auto">
                Take our personality quiz to unlock your personalised reading profile and discover books that perfectly match who you are.
              </p>
            </div>
            
            <div className="grid md:grid-cols-2 gap-4 mb-8">
              <div className="bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl p-4">
                <div className="text-2xl font-bold text-white mb-1">5-7 min</div>
                <div className="text-sm text-white/70">Quick & Easy</div>
              </div>
              <div className="bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl p-4">
                <div className="text-2xl font-bold text-white mb-1">100%</div>
                <div className="text-sm text-white/70">Free Forever</div>
              </div>
            </div>
            
            <button
              onClick={onBack}
              className="bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-300 transform hover:scale-105 hover:shadow-2xl inline-flex items-center space-x-2"
            >
              <Brain className="w-5 h-5" />
              <span>Take Personality Quiz</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default PlaceholderPage;