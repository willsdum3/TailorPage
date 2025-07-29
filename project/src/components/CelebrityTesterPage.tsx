import React, { useState } from 'react';
import { 
  ArrowLeft, 
  Brain, 
  Book, 
  ShoppingCart, 
  ExternalLink, 
  Star,
  Sparkles,
  ChevronDown,
  ChevronUp,
  TrendingUp,
  Heart,
  Users,
  Lightbulb,
  Target,
  Zap,
  Shield,
  Globe,
  Palette,
  Music,
  Camera
} from 'lucide-react';
import { celebrities } from '../data/celebrities';
import { CelebrityProfile } from '../data/celebrities';
import Logo from './Logo';
import BookCover from './BookCover';
import { useScrollToTop } from '../hooks/useScrollToTop';

interface CelebrityTesterPageProps {
  onBack: () => void;
  hasCompletedQuiz: boolean;
}

const CelebrityTesterPage: React.FC<CelebrityTesterPageProps> = ({ onBack, hasCompletedQuiz }) => {
  const [selectedCelebrity, setSelectedCelebrity] = useState<CelebrityProfile | null>(null);
  const [expandedPersonality, setExpandedPersonality] = useState(false);

  // Scroll to top when selected celebrity changes
  useScrollToTop([selectedCelebrity?.id]);

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
        icon: Users,
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
        icon: Lightbulb,
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

  if (selectedCelebrity) {
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
              onClick={() => setSelectedCelebrity(null)}
              className="mb-8 bg-white/10 backdrop-blur-sm border border-white/20 hover:bg-white/20 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105 inline-flex items-center space-x-2"
            >
              <ArrowLeft className="w-4 h-4" />
              <span>Back to Celebrities</span>
            </button>
            
            <div className="flex items-center justify-center space-x-6 mb-8">
              <div className="w-32 h-32 rounded-2xl overflow-hidden border-4 border-amber-400/50 shadow-xl bg-white/5">
                <img
                  src={selectedCelebrity.imageUrl}
                  alt={selectedCelebrity.name}
                  className="w-full h-full object-cover"
                />
              </div>
              <div className="text-left">
                <h1 className="text-4xl md:text-5xl font-bold text-white mb-2">
                  {selectedCelebrity.name}
                </h1>
                <p className="text-xl text-amber-400 font-medium mb-2">{selectedCelebrity.profession}</p>
                <p className="text-white/70 max-w-md">{selectedCelebrity.bio}</p>
              </div>
            </div>
          </div>

          {/* Personality Profile */}
          <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 mb-8">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-3xl font-bold text-white flex items-center space-x-3">
                <Brain className="w-8 h-8 text-amber-400" />
                <span>Personality Profile</span>
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
              {Object.entries(selectedCelebrity.personalityScores).map(([trait, score]) => {
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

          {/* Book Recommendations */}
          <div className="mb-8">
            <div className="text-center mb-8">
              <div className="inline-flex items-center space-x-2 bg-white/10 backdrop-blur-sm border border-white/20 rounded-full px-4 py-2 mb-4">
                <Sparkles className="w-4 h-4 text-amber-400" />
                <span className="text-sm font-medium text-white/80">AI-Generated Recommendations</span>
              </div>
              <h2 className="text-3xl font-bold text-white mb-4">
                <h2 className="text-3xl font-bold text-white">Want Your Own Personalised Recommendations?</h2>
              </h2>
              <p className="text-white/70 max-w-2xl mx-auto">
                Just like these celebrities, you have a unique personality that influences your reading preferences. Take our quiz to discover books perfectly tailored to you!
              </p>
            </div>

            <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
              {selectedCelebrity.bookRecommendations.map((book, index) => (
                <div key={index} className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6 hover:bg-white/15 transition-all duration-300 transform hover:scale-105 group">
                  <div className="flex items-start justify-between mb-4">
                    <div className="flex-1">
                      <span className="inline-block bg-gradient-to-r from-amber-500 to-orange-600 text-white px-3 py-1 rounded-full text-sm font-medium mb-3">
                        {book.genre}
                      </span>
                      
                      <h3 className="text-xl font-bold text-white mb-2 group-hover:text-amber-400 transition-colors duration-300">
                        {book.title}
                      </h3>
                      <p className="text-white/70 font-medium mb-3">by {book.author}</p>
                    </div>
                    <BookCover
                      bookId={`${selectedCelebrity.id}-${index}`}
                      title={book.title}
                      author={book.author}
                      size="md"
                      className="flex-shrink-0 ml-4"
                      genre={book.genre}
                      description={book.description}
                      amazonLink={book.amazonLink}
                    />
                  </div>
                  
                  <p className="text-white/70 mb-4 leading-relaxed text-sm">
                    {book.description}
                  </p>
                  
                  <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-4 mb-6">
                    <p className="text-sm text-white/80">
                      <span className="font-medium text-amber-400">Why this fits:</span> {book.reason}
                    </p>
                  </div>
                  
                  <a
                    href={book.amazonLink}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white px-4 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105 inline-flex items-center justify-center space-x-2 w-full group"
                  >
                    <Book className="w-4 h-4" />
                    <span>View on Amazon</span>
                  </a>
                </div>
              ))}
            </div>
          </div>

          {/* Back to List */}
          <div className="text-center">
            <button
              onClick={() => setSelectedCelebrity(null)}
              className="bg-white/10 backdrop-blur-sm border border-white/20 hover:bg-white/20 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-300 transform hover:scale-105 inline-flex items-center space-x-2"
            >
              <ArrowLeft className="w-5 h-5" />
              <span>Explore More Celebrities</span>
            </button>
          </div>
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
            <Star className="w-4 h-4 text-amber-400" />
            <span className="text-sm font-medium text-white/80">Celebrity Personality Analysis</span>
          </div>
          
          <h1 className="text-5xl md:text-6xl font-bold text-white mb-6 leading-tight">
            Celebrity
            <span className="block bg-gradient-to-r from-amber-400 to-orange-500 bg-clip-text text-transparent">
              Book Tester
            </span>
          </h1>
          
          <p className="text-xl text-white/70 mb-8 max-w-3xl mx-auto leading-relaxed">
            Discover what books would perfectly match famous personalities based on their psychological profiles. See how our AI analyses celebrity traits to recommend their ideal reads.
          </p>
        </div>

        {/* Celebrity Grid */}
        <div className="grid gap-8 md:grid-cols-2 lg:grid-cols-5 mb-16">
          {celebrities.map((celebrity) => (
            <div 
              key={celebrity.id} 
              onClick={() => setSelectedCelebrity(celebrity)}
              className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6 hover:bg-white/15 transition-all duration-300 transform hover:scale-105 cursor-pointer group"
            >
              <div className="text-center">
                <div className="w-24 h-24 rounded-xl overflow-hidden mx-auto mb-4 border-2 border-white/20 group-hover:border-amber-400/50 transition-colors duration-300 shadow-lg bg-white/5">
                  <img
                    src={celebrity.imageUrl}
                    alt={celebrity.name}
                    className="w-full h-full object-cover"
                  />
                </div>
                
                <h3 className="text-xl font-bold text-white mb-2 group-hover:text-amber-400 transition-colors duration-300">
                  {celebrity.name}
                </h3>
                <p className="text-amber-400 font-medium text-sm mb-3">{celebrity.profession}</p>
                
                <p className="text-white/70 text-sm mb-4 leading-relaxed line-clamp-3">
                  {celebrity.bio}
                </p>
                
                <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-3 mb-4">
                  <div className="text-xs text-white/60 mb-2">Personality Highlights:</div>
                  <div className="flex flex-wrap gap-1">
                    {Object.entries(celebrity.personalityScores)
                      .filter(([_, score]) => score >= 4)
                      .slice(0, 3)
                      .map(([trait, score]) => (
                        <span key={trait} className="bg-amber-400/20 text-amber-300 px-2 py-1 rounded-lg text-xs font-medium">
                          {trait.charAt(0).toUpperCase() + trait.slice(1)} ({score})
                        </span>
                      ))
                    }
                  </div>
                </div>
                
                <div className="text-center">
                  <span className="text-white/60 text-sm">
                    {celebrity.bookRecommendations.length} book recommendations
                  </span>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Bottom CTA */}
        <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 text-center">
          {hasCompletedQuiz ? (
            <>
              <div className="mb-8">
                <div className="inline-flex items-center space-x-2 mb-4">
                  <Sparkles className="w-6 h-6 text-amber-400" />
                  <h2 className="text-3xl font-bold text-white">Enjoying Tailor Page?</h2>
                </div>
                <p className="text-white/70 mb-8 max-w-2xl mx-auto">
                  Share the app with your friends on social media!
                </p>
                <div className="flex flex-wrap justify-center gap-4">
                  <a href="https://www.facebook.com/sharer/sharer.php?u=https://your-app-url.com" target="_blank" rel="noopener noreferrer" className="flex items-center space-x-3 px-6 py-3 rounded-xl font-semibold bg-white/10 hover:bg-blue-500/20 transition-all duration-300 transform hover:scale-105 border border-white/20 hover:border-blue-400/30">
                    <img src="/facebooklogo5.jpg" alt="Facebook" className="w-8 h-8 rounded-md object-cover" />
                    <span>Facebook</span>
                  </a>
                  <a href="https://twitter.com/intent/tweet?url=https://your-app-url.com&text=Check%20out%20Tailor%20Page%20for%20personalized%20book%20recommendations!" target="_blank" rel="noopener noreferrer" className="flex items-center space-x-3 px-6 py-3 rounded-xl font-semibold bg-white/10 hover:bg-black/20 transition-all duration-300 transform hover:scale-105 border border-white/20 hover:border-gray-400/30">
                    <img src="/xlogo2.jpg" alt="X" className="w-8 h-8 rounded-md object-cover" />
                    <span>X</span>
                  </a>
                  <a href="https://www.linkedin.com/sharing/share-offsite/?url=https://your-app-url.com" target="_blank" rel="noopener noreferrer" className="flex items-center space-x-3 px-6 py-3 rounded-xl font-semibold bg-white/10 hover:bg-blue-600/20 transition-all duration-300 transform hover:scale-105 border border-white/20 hover:border-blue-500/30">
                    <img src="/linkedinlogo3.jpg" alt="LinkedIn" className="w-8 h-8 rounded-md object-cover" />
                    <span>LinkedIn</span>
                  </a>
                  <a href="https://reddit.com/submit?url=https://your-app-url.com&title=Check%20out%20Tailor%20Page%20for%20personalized%20book%20recommendations!" target="_blank" rel="noopener noreferrer" className="flex items-center space-x-3 px-6 py-3 rounded-xl font-semibold bg-white/10 hover:bg-orange-500/20 transition-all duration-300 transform hover:scale-105 border border-white/20 hover:border-orange-400/30">
                    <img src="/Redditlogo5.png" alt="Reddit" className="w-8 h-8 rounded-md object-cover" />
                    <span>Reddit</span>
                  </a>
                  <a href="https://api.whatsapp.com/send?text=Check%20out%20Tailor%20Page%20for%20personalized%20book%20recommendations!%20https://your-app-url.com" target="_blank" rel="noopener noreferrer" className="flex items-center space-x-3 px-6 py-3 rounded-xl font-semibold bg-white/10 hover:bg-green-500/20 transition-all duration-300 transform hover:scale-105 border border-white/20 hover:border-green-400/30">
                    <img src="/whatsapplogo3.jpg" alt="WhatsApp" className="w-8 h-8 rounded-md object-cover" />
                    <span>WhatsApp</span>
                  </a>
                  <a href="https://www.instagram.com/" target="_blank" rel="noopener noreferrer" className="flex items-center space-x-3 px-6 py-3 rounded-xl font-semibold bg-white/10 hover:bg-pink-500/20 transition-all duration-300 transform hover:scale-105 border border-white/20 hover:border-pink-400/30">
                    <img src="/instagramlogo3.jpg" alt="Instagram" className="w-8 h-8 rounded-md object-cover" />
                    <span>Instagram</span>
                  </a>
                </div>
              </div>
            </>
          ) : (
            <>
              <div className="mb-8">
                <div className="inline-flex items-center space-x-2 mb-4">
                  <Sparkles className="w-6 h-6 text-amber-400" />
                  <h2 className="text-3xl font-bold text-white">Want Your Own Personalised Recommendations?</h2>
                </div>
                <p className="text-white/70 mb-8 max-w-2xl mx-auto">
                  Just like these celebrities, you have a unique personality that influences your reading preferences. Take our quiz to discover books perfectly tailored to you!
                </p>
              </div>
              <button
                onClick={onBack}
                className="bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-300 transform hover:scale-105 hover:shadow-2xl inline-flex items-center space-x-2"
              >
                <span>Take Your Personality Quiz</span>
                <ArrowLeft className="w-5 h-5 rotate-180" />
              </button>
            </>
          )}
        </div>
      </div>
    </div>
  );
};

export default CelebrityTesterPage;