import React from 'react';
import { ArrowLeft, Construction, Sparkles, Brain, Target, User, Heart, Shield, Zap, Users, Eye, ChevronDown, ChevronUp, Book, ArrowRight, Star } from 'lucide-react';
import { PersonalityProfile, BookRecommendation, FavoriteBook } from '../types';
import { getBookRecommendations } from '../utils/bookRecommendations';
import Logo from './Logo';
import { analyzePersonality } from '../utils/personalityAnalysis';
import StrengthsDetailPage from './StrengthsDetailPage';
import GrowthAreasDetailPage from './GrowthAreasDetailPage';
import FavoritesPage from './FavoritesPage';

interface PlaceholderPageProps {
  title: string;
  description: string;
  onBack: () => void;
  profile?: PersonalityProfile | null;
  onStartQuiz?: () => void;
  onNewRecommendations?: (recommendations: BookRecommendation[]) => void;
  onNavigate?: (page: string) => void;
  favorites?: FavoriteBook[];
  onRemoveFavorite?: (bookId: string) => void;
}

const PlaceholderPage: React.FC<PlaceholderPageProps> = ({ title, description, onBack, profile, onStartQuiz, onNewRecommendations, onNavigate, favorites = [], onRemoveFavorite }) => {
  const [expandedPersonality, setExpandedPersonality] = React.useState(false);
  const [isGenerating, setIsGenerating] = React.useState(false);
  const [currentPage, setCurrentPage] = React.useState<'profile' | 'strengths' | 'growth'>('profile');
  const [activeTab, setActiveTab] = React.useState<'personality' | 'insights' | 'favourites' | 'settings'>('personality');

  const getTraitIcon = (traitName: string) => {
    switch (traitName) {
      case 'Openness to Experience':
        return Brain;
      case 'Conscientiousness':
        return Target;
      case 'Extraversion':
        return Users;
      case 'Agreeableness':
        return Heart;
      case 'Emotional Stability':
        return Shield;
      default:
        return Brain;
    }
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

  const handleNavigateToStrengths = () => {
    setCurrentPage('strengths');
  };

  const handleNavigateToGrowth = () => {
    setCurrentPage('growth');
  };

  const handleBackToProfile = () => {
    setCurrentPage('profile');
  };

  const handleNavigateToFavourites = () => {
    if (onNavigate) {
      onNavigate('favourites');
    }
  };

  // If we have a profile, show the personality analysis
  if (profile) {
    const personalityAnalysis = analyzePersonality(profile);
    
    // Render different pages based on currentPage state
    if (currentPage === 'strengths') {
      return <StrengthsDetailPage profile={profile} onBack={handleBackToProfile} />;
    }
    
    if (currentPage === 'growth') {
      return <GrowthAreasDetailPage profile={profile} onBack={handleBackToProfile} />;
    }
    
    return (
      <div className="min-h-screen relative overflow-hidden">
        {/* Background Elements */}
        <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900" />
        
        <div className="max-w-6xl mx-auto relative z-10 pt-32 pb-8 px-4">
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
              Your detailed personality breakdown and personalized reading insights.
            </p>
          </div>

          {/* Tab Navigation */}
          <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-2 mb-8">
            <div className="flex space-x-1">
              <button
                onClick={() => setActiveTab('personality')}
                className={`flex-1 px-4 py-3 rounded-xl font-medium transition-all duration-300 ${
                  activeTab === 'personality'
                    ? 'bg-white/20 text-white shadow-lg'
                    : 'text-white/70 hover:text-white hover:bg-white/5'
                }`}
              >
                Personality
              </button>
              <button
                onClick={() => setActiveTab('insights')}
                className={`flex-1 px-4 py-3 rounded-xl font-medium transition-all duration-300 ${
                  activeTab === 'insights'
                    ? 'bg-white/20 text-white shadow-lg'
                    : 'text-white/70 hover:text-white hover:bg-white/5'
                }`}
              >
                Key Insights
              </button>
              <button
                onClick={() => setActiveTab('favourites')}
                className={`flex-1 px-4 py-3 rounded-xl font-medium transition-all duration-300 ${
                  activeTab === 'favourites'
                    ? 'bg-white/20 text-white shadow-lg'
                    : 'text-white/70 hover:text-white hover:bg-white/5'
                }`}
              >
                Favourites
              </button>
              <button
                onClick={() => setActiveTab('settings')}
                className={`flex-1 px-4 py-3 rounded-xl font-medium transition-all duration-300 ${
                  activeTab === 'settings'
                    ? 'bg-white/20 text-white shadow-lg'
                    : 'text-white/70 hover:text-white hover:bg-white/5'
                }`}
              >
                Settings
              </button>
            </div>
          </div>

          {/* Tab Content */}
          {activeTab === 'personality' && (
            <>
              {/* Personality Profile */}
              <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 mb-8">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-3xl font-bold text-white flex items-center space-x-3">
                <Brain className="w-8 h-8 text-amber-400" />
                <span>Personality Breakdown</span>
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
              {(() => {
                // Define custom order for the first 4 traits
                const traitOrder = ['Openness to Experience', 'Conscientiousness', 'Extraversion', 'Agreeableness'];
                const orderedTraits = traitOrder.map(traitName => 
                  personalityAnalysis.find(trait => trait.name === traitName)
                ).filter((trait): trait is NonNullable<typeof trait> => trait !== undefined);
                
                return (
                  <>
                    {orderedTraits.map((trait) => {
                      const IconComponent = getTraitIcon(trait.name);
                      
                      return (
                        <div key={trait.name} className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-4">
                          <div className="flex items-center space-x-3 mb-3">
                            <div className={`w-10 h-10 bg-gradient-to-r ${trait.color} rounded-lg flex items-center justify-center`}>
                              <IconComponent className="w-5 h-5 text-white" />
                            </div>
                            <div className="flex-1">
                              <h3 className="font-semibold text-white">{trait.name}</h3>
                              <div className="flex items-center space-x-2">
                                <div className="flex-1 bg-white/20 rounded-full h-2">
                                  <div 
                                    className={`bg-gradient-to-r ${trait.color} h-2 rounded-full transition-all duration-500`}
                                    style={{ width: `${trait.percentage}%` }}
                                  />
                                </div>
                                <span className="text-white/80 text-sm font-medium">{trait.score}/25</span>
                              </div>
                            </div>
                          </div>
                          
                          {expandedPersonality && (
                            <div className="mt-3 pt-3 border-t border-white/10">
                              <p className="text-white/70 text-sm mb-2">{trait.description}</p>
                              <div className="mb-3">
                                <p className="text-white/60 text-xs mb-1">
                                  <span className="font-medium text-amber-400">Level:</span> {trait.level}
                                </p>
                                <p className="text-white/60 text-xs mb-2">
                                  <span className="font-medium text-amber-400">Strengths:</span> {trait.strengths.join(', ')}
                                </p>
                                <p className="text-white/60 text-xs">
                                  <span className="font-medium text-amber-400">Reading Preferences:</span> {trait.readingPreferences.join(', ')}
                                </p>
                              </div>
                            </div>
                          )}
                        </div>
                      );
                    })}
                    
                    {/* Emotional Stability at bottom center */}
                    {(() => {
                      const emotionalStabilityTrait = personalityAnalysis.find(trait => trait.name === 'Emotional Stability');
                      if (!emotionalStabilityTrait) return null;
                      
                      const IconComponent = getTraitIcon(emotionalStabilityTrait.name);
                      
                      return (
                        <div key="emotionalStability" className="md:col-span-2 flex justify-center">
                          <div className="w-full max-w-md bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6 transform scale-105">
                          <div className="flex items-center space-x-3 mb-3">
                            <div className={`w-10 h-10 bg-gradient-to-r ${emotionalStabilityTrait.color} rounded-lg flex items-center justify-center`}>
                              <IconComponent className="w-5 h-5 text-white" />
                            </div>
                            <div className="flex-1">
                              <h3 className="font-semibold text-white">{emotionalStabilityTrait.name}</h3>
                              <div className="flex items-center space-x-2">
                                <div className="flex-1 bg-white/20 rounded-full h-2">
                                  <div 
                                    className={`bg-gradient-to-r ${emotionalStabilityTrait.color} h-2 rounded-full transition-all duration-500`}
                                    style={{ width: `${emotionalStabilityTrait.percentage}%` }}
                                  />
                                </div>
                                <span className="text-white/80 text-sm font-medium">{emotionalStabilityTrait.score}/25</span>
                              </div>
                            </div>
                          </div>
                          
                          {expandedPersonality && (
                            <div className="mt-3 pt-3 border-t border-white/10">
                              <p className="text-white/70 text-sm mb-2">{emotionalStabilityTrait.description}</p>
                              <div className="mb-3">
                                <p className="text-white/60 text-xs mb-1">
                                  <span className="font-medium text-amber-400">Level:</span> {emotionalStabilityTrait.level}
                                </p>
                                <p className="text-white/60 text-xs mb-2">
                                  <span className="font-medium text-amber-400">Strengths:</span> {emotionalStabilityTrait.strengths.join(', ')}
                                </p>
                                <p className="text-white/60 text-xs">
                                  <span className="font-medium text-amber-400">Reading Preferences:</span> {emotionalStabilityTrait.readingPreferences.join(', ')}
                                </p>
                              </div>
                            </div>
                          )}
                        </div>
                      </div>
                    );
                  })()}
                  </>
                );
              })()}
            </div>
          </div>

          {/* Insights Section */}
          <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 mb-8">
            <h2 className="text-3xl font-bold text-white mb-6 flex items-center space-x-3">
              <Sparkles className="w-8 h-8 text-amber-400" />
              <span>Key Insights</span>
            </h2>
            
            <div className="grid md:grid-cols-3 gap-6">
              <button 
                onClick={handleNavigateToStrengths}
                className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6 hover:bg-white/10 transition-all duration-300 text-left group"
              >
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-xl font-semibold text-white">Your Strengths</h3>
                  <ArrowRight className="w-5 h-5 text-white/60 group-hover:text-amber-400 transition-colors duration-300" />
                </div>
                <div className="space-y-3">
                  {(() => {
                    // Get top traits by score (only traits tied for highest scores, max 3)
                    const sortedTraits = [...personalityAnalysis].sort((a, b) => b.score - a.score);
                    const highestScore = sortedTraits[0]?.score || 0;
                    const topTraits = sortedTraits
                      .filter(trait => trait.score === highestScore)
                      .slice(0, 3); // Limit to top 3 even if more are tied
                    
                    return topTraits.map((trait) => (
                      <div key={trait.name} className="flex items-center space-x-3">
                        <div className="w-2 h-2 bg-green-400 rounded-full"></div>
                        <span className="text-white/80">{trait.name}</span>
                        <span className="text-green-400 text-sm font-medium">({trait.score}/25)</span>
                      </div>
                    ));
                  })()}
                </div>
                <p className="text-white/60 text-sm mt-4">Click to explore your unique strengths and how to leverage them</p>
              </button>
              
              <button 
                onClick={handleNavigateToGrowth}
                className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6 hover:bg-white/10 transition-all duration-300 text-left group"
              >
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-xl font-semibold text-white">Growth Areas</h3>
                  <ArrowRight className="w-5 h-5 text-white/60 group-hover:text-amber-400 transition-colors duration-300" />
                </div>
                <div className="space-y-3">
                  {(() => {
                    // Get lowest-scoring traits (only traits tied for lowest scores, max 3)
                    const sortedTraits = [...personalityAnalysis].sort((a, b) => a.score - b.score);
                    const lowestScore = sortedTraits[0]?.score || 0;
                    const lowestTraits = sortedTraits
                      .filter(trait => trait.score === lowestScore)
                      .slice(0, 3); // Limit to top 3 even if more are tied
                    
                    return lowestTraits.map((trait) => (
                      <div key={trait.name} className="flex items-center space-x-3">
                        <div className="w-2 h-2 bg-amber-400 rounded-full"></div>
                        <span className="text-white/80">{trait.name}</span>
                        <span className="text-amber-400 text-sm font-medium">({trait.score}/25)</span>
                      </div>
                    ));
                  })()}
                  {/* Show universal growth areas if no specific low traits */}
                  {(() => {
                    const sortedTraits = [...personalityAnalysis].sort((a, b) => a.score - b.score);
                    const lowestScore = sortedTraits[0]?.score || 0;
                    const lowestTraits = sortedTraits.filter(trait => trait.score === lowestScore);
                    return lowestTraits.length === 0;
                  })() && (
                    <>
                      <div className="flex items-center space-x-3">
                        <div className="w-2 h-2 bg-amber-400 rounded-full"></div>
                        <span className="text-white/80">Sleep Quality</span>
                        <span className="text-amber-400 text-sm font-medium">Universal</span>
                      </div>
                      <div className="flex items-center space-x-3">
                        <div className="w-2 h-2 bg-amber-400 rounded-full"></div>
                        <span className="text-white/80">Physical Activity</span>
                        <span className="text-amber-400 text-sm font-medium">Universal</span>
                      </div>
                      <div className="flex items-center space-x-3">
                        <div className="w-2 h-2 bg-amber-400 rounded-full"></div>
                        <span className="text-white/80">Social Connections</span>
                        <span className="text-amber-400 text-sm font-medium">Universal</span>
                      </div>
                    </>
                  )}
                </div>
                <p className="text-white/60 text-sm mt-4">Click to discover personalized growth strategies and universal improvement tips</p>
              </button>

              <button 
                onClick={handleNavigateToFavourites}
                className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6 hover:bg-white/10 transition-all duration-300 text-left group"
              >
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-xl font-semibold text-white">Favourites</h3>
                  <ArrowRight className="w-5 h-5 text-white/60 group-hover:text-amber-400 transition-colors duration-300" />
                </div>
                <div className="space-y-3">
                  <div className="flex items-center space-x-3">
                    <div className="w-2 h-2 bg-pink-400 rounded-full"></div>
                    <span className="text-white/80">Saved Books</span>
                    <span className="text-pink-400 text-sm font-medium">Personal</span>
                  </div>
                  <div className="flex items-center space-x-3">
                    <div className="w-2 h-2 bg-pink-400 rounded-full"></div>
                    <span className="text-white/80">Reading List</span>
                    <span className="text-pink-400 text-sm font-medium">Curated</span>
                  </div>
                  <div className="flex items-center space-x-3">
                    <div className="w-2 h-2 bg-pink-400 rounded-full"></div>
                    <span className="text-white/80">Bookmarks</span>
                    <span className="text-pink-400 text-sm font-medium">Organized</span>
                  </div>
                </div>
                <p className="text-white/60 text-sm mt-4">Access your saved books and personalized reading collection</p>
              </button>
            </div>
          </div>
            </>
          )}

          {activeTab === 'insights' && (
            <>
              {/* Insights Section */}
              <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 mb-8">
                <h2 className="text-3xl font-bold text-white mb-6 flex items-center space-x-3">
                  <Sparkles className="w-8 h-8 text-amber-400" />
                  <span>Key Insights</span>
                </h2>
                
                <div className="grid md:grid-cols-2 gap-6">
                  <button 
                    onClick={handleNavigateToStrengths}
                    className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6 hover:bg-white/10 transition-all duration-300 text-left group"
                  >
                    <div className="flex items-center justify-between mb-4">
                      <h3 className="text-xl font-semibold text-white">Your Strengths</h3>
                      <ArrowRight className="w-5 h-5 text-white/60 group-hover:text-amber-400 transition-colors duration-300" />
                    </div>
                    <div className="space-y-3">
                      {(() => {
                        // Get top traits by score (only traits tied for highest scores, max 3)
                        const sortedTraits = [...personalityAnalysis].sort((a, b) => b.score - a.score);
                        const highestScore = sortedTraits[0]?.score || 0;
                        const topTraits = sortedTraits
                          .filter(trait => trait.score === highestScore)
                          .slice(0, 3); // Limit to top 3 even if more are tied
                        
                        return topTraits.map((trait) => (
                          <div key={trait.name} className="flex items-center space-x-3">
                            <div className="w-2 h-2 bg-green-400 rounded-full"></div>
                            <span className="text-white/80">{trait.name}</span>
                            <span className="text-green-400 text-sm font-medium">({trait.score}/25)</span>
                          </div>
                        ));
                      })()}
                    </div>
                    <p className="text-white/60 text-sm mt-4">Click to explore your unique strengths and how to leverage them</p>
                  </button>
                  
                  <button 
                    onClick={handleNavigateToGrowth}
                    className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6 hover:bg-white/10 transition-all duration-300 text-left group"
                  >
                    <div className="flex items-center justify-between mb-4">
                      <h3 className="text-xl font-semibold text-white">Growth Areas</h3>
                      <ArrowRight className="w-5 h-5 text-white/60 group-hover:text-amber-400 transition-colors duration-300" />
                    </div>
                    <div className="space-y-3">
                      {(() => {
                        // Get lowest-scoring traits (only traits tied for lowest scores, max 3)
                        const sortedTraits = [...personalityAnalysis].sort((a, b) => a.score - b.score);
                        const lowestScore = sortedTraits[0]?.score || 0;
                        const lowestTraits = sortedTraits
                          .filter(trait => trait.score === lowestScore)
                          .slice(0, 3); // Limit to top 3 even if more are tied
                        
                        return lowestTraits.map((trait) => (
                          <div key={trait.name} className="flex items-center space-x-3">
                            <div className="w-2 h-2 bg-amber-400 rounded-full"></div>
                            <span className="text-white/80">{trait.name}</span>
                            <span className="text-amber-400 text-sm font-medium">({trait.score}/25)</span>
                          </div>
                        ));
                      })()}
                      {/* Show universal growth areas if no specific low traits */}
                      {(() => {
                        const sortedTraits = [...personalityAnalysis].sort((a, b) => a.score - b.score);
                        const lowestScore = sortedTraits[0]?.score || 0;
                        const lowestTraits = sortedTraits.filter(trait => trait.score === lowestScore);
                        return lowestTraits.length === 0;
                      })() && (
                        <>
                          <div className="flex items-center space-x-3">
                            <div className="w-2 h-2 bg-amber-400 rounded-full"></div>
                            <span className="text-white/80">Sleep Quality</span>
                            <span className="text-amber-400 text-sm font-medium">Universal</span>
                          </div>
                          <div className="flex items-center space-x-3">
                            <div className="w-2 h-2 bg-amber-400 rounded-full"></div>
                            <span className="text-white/80">Physical Activity</span>
                            <span className="text-amber-400 text-sm font-medium">Universal</span>
                          </div>
                          <div className="flex items-center space-x-3">
                            <div className="w-2 h-2 bg-amber-400 rounded-full"></div>
                            <span className="text-white/80">Social Connections</span>
                            <span className="text-amber-400 text-sm font-medium">Universal</span>
                          </div>
                        </>
                      )}
                    </div>
                    <p className="text-white/60 text-sm mt-4">Click to discover personalized growth strategies and universal improvement tips</p>
                  </button>
                </div>
              </div>
            </>
          )}

          {activeTab === 'favourites' && (
            <FavoritesPage
              favorites={favorites}
              onRemoveFavorite={onRemoveFavorite || (() => {})}
              onBack={onBack}
              hasCompletedQuiz={!!profile}
              onStartQuiz={onStartQuiz}
              onGenerateNewBooks={handleGenerateNewBooks}
            />
          )}

          {activeTab === 'settings' && (
            <>
              {/* Settings Section */}
              <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 mb-8">
                <h2 className="text-3xl font-bold text-white mb-6 flex items-center space-x-3">
                  <User className="w-8 h-8 text-blue-400" />
                  <span>Settings</span>
                </h2>
                
                <div className="space-y-6">
                  <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6">
                    <h3 className="text-xl font-semibold text-white mb-4">Account Settings</h3>
                    <div className="space-y-4">
                      <div className="flex items-center justify-between">
                        <span className="text-white/80">Email Notifications</span>
                        <div className="w-12 h-6 bg-white/20 rounded-full relative">
                          <div className="w-5 h-5 bg-white rounded-full absolute top-0.5 left-0.5 transition-transform duration-300"></div>
                        </div>
                      </div>
                      <div className="flex items-center justify-between">
                        <span className="text-white/80">Book Recommendations</span>
                        <div className="w-12 h-6 bg-amber-500 rounded-full relative">
                          <div className="w-5 h-5 bg-white rounded-full absolute top-0.5 right-0.5 transition-transform duration-300"></div>
                        </div>
                      </div>
                    </div>
                  </div>
                  
                  <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6">
                    <h3 className="text-xl font-semibold text-white mb-4">Privacy</h3>
                    <div className="space-y-4">
                      <div className="flex items-center justify-between">
                        <span className="text-white/80">Profile Visibility</span>
                        <select className="bg-white/10 border border-white/20 rounded-lg px-3 py-2 text-white">
                          <option>Public</option>
                          <option>Private</option>
                        </select>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </>
          )}

          {/* Call to Action - Always visible */}
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
                onClick={onStartQuiz || onBack}
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
          
          <h1 className="text-4xl md:text-5xl font-bold text-white mb-8 leading-tight">
            <span className="text-white">Create Your </span>
            <span className="bg-gradient-to-r from-amber-400 to-orange-500 bg-clip-text text-transparent">
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
                  Our sophisticated algorithm analyses 5 personality dimensions to understand your reading preferences and psychological profile.
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
                <span className="text-2xl font-bold text-white">25</span>
              </div>
              <h3 className="text-lg font-bold text-white mb-2">Take the Quiz</h3>
              <p className="text-white/70 text-sm">
                Answer 25 carefully crafted questions about your personality, preferences, and lifestyle in just 3-5 minutes.
              </p>
            </div>
            
            <div className="text-center">
              <div className="w-16 h-16 bg-gradient-to-r from-purple-500 to-pink-600 rounded-2xl flex items-center justify-center mx-auto mb-4">
                <Brain className="w-8 h-8 text-white" />
              </div>
              <h3 className="text-lg font-bold text-white mb-2">AI Analysis</h3>
              <p className="text-white/70 text-sm">
                Our AI analyses your responses across 5 personality dimensions to create your unique reading profile.
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
                <div className="text-2xl font-bold text-white mb-1">3-5 min</div>
                <div className="text-sm text-white/70">Quick & Easy</div>
              </div>
              <div className="bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl p-4">
                <div className="text-2xl font-bold text-white mb-1">100%</div>
                <div className="text-sm text-white/70">Free Forever</div>
              </div>
            </div>
            
            <button
              onClick={onStartQuiz || onBack}
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