import React, { useState, useEffect } from 'react';
import { Home, ArrowLeft, Construction, Sparkles, Brain, Target, User, Heart, Shield, Zap, Users, Eye, ChevronDown, ChevronUp, Book, ArrowRight, Star, Check, X, Upload, Camera } from 'lucide-react';
import { useUser } from '@clerk/clerk-react';
import { PersonalityProfile, BookRecommendation, FavoriteBook } from '../types';
import { getBookRecommendations } from '../utils/bookRecommendationsOptimized';
import { analyzePersonality } from '../utils/personalityAnalysis';
import StrengthsDetailPage from './StrengthsDetailPage';
import GrowthAreasDetailPage from './GrowthAreasDetailPage';
import FavoritesPage from './FavoritesPage';
import { BookCover } from './BookCover';
import BookSummaryModal, { BookSummaryData } from './BookSummaryModal';
import { bookInfoService } from '../services/bookInfoService';


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
  onLogout?: () => void;
}

const PlaceholderPage: React.FC<PlaceholderPageProps> = ({ title, description, onBack, profile, onStartQuiz, onNewRecommendations, onNavigate, favorites = [], onRemoveFavorite, onLogout }) => {
  // Add global click test
  useEffect(() => {
    const handleGlobalClick = (e: MouseEvent) => {
      console.log('🎯 PLACEHOLDER PAGE GLOBAL CLICK at:', e.clientX, e.clientY, 'target:', e.target);
    };
    
    document.addEventListener('click', handleGlobalClick, true); // Use capture phase
    return () => document.removeEventListener('click', handleGlobalClick, true);
  }, []);
  const { user } = useUser();
  const [expandedPersonality, setExpandedPersonality] = useState(false);
  const [isGenerating, setIsGenerating] = useState(false);
  const [currentPage, setCurrentPage] = useState<'profile' | 'strengths' | 'growth'>('profile');
  const [activeTab, setActiveTab] = useState<'personality' | 'favourites' | 'profile-settings' | 'help'>('personality');
  
  // Book summary modal state
  const [selectedBook, setSelectedBook] = useState<BookSummaryData | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isLoadingBookInfo, setIsLoadingBookInfo] = useState(false);
  
  // Profile Settings State
  const [profileSettings, setProfileSettings] = useState({
    username: user?.username || '',
    email: user?.primaryEmailAddress?.emailAddress || '',
    currentPassword: '',
    newPassword: '',
    confirmPassword: '',
    profilePicture: user?.imageUrl || null
  });
  
  const [profileErrors, setProfileErrors] = useState<Record<string, string>>({});
  const [profileSuccess, setProfileSuccess] = useState<Record<string, string>>({});
  const [isUpdating, setIsUpdating] = useState(false);
  const [isUploadingImage, setIsUploadingImage] = useState(false);

  // Update profile settings when user data changes
  useEffect(() => {
    if (user) {
      setProfileSettings(prev => ({
        ...prev,
        username: user.username || '',
        email: user.primaryEmailAddress?.emailAddress || '',
        profilePicture: user.imageUrl || null
      }));
    }
  }, [user]);

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

  const handleBookCoverClick = async (book: FavoriteBook) => {
    console.log('🎯 PlaceholderPage: Book cover clicked for:', book.title, 'by', book.author);
    console.log('🔍 PlaceholderPage: Setting modal state...');
    setIsLoadingBookInfo(true);
    setIsModalOpen(true);
    console.log('🔍 PlaceholderPage: Modal should be open now');
    
    try {
      const bookInfo = await bookInfoService.getBookInfo(book.title, book.author);
      setSelectedBook(bookInfo);
      console.log('✅ PlaceholderPage: Book info loaded successfully:', bookInfo);
      console.log('🔍 PlaceholderPage: selectedBook set, modal should be visible');
    } catch (error) {
      console.error('❌ PlaceholderPage: Error fetching book info:', error);
      // Set basic book info as fallback
      const fallbackBook = {
        title: book.title,
        author: book.author,
        description: `A book by ${book.author} that you've added to your favorites.`,
        genre: book.genre,
        amazonLink: book.amazonLink
      };
      setSelectedBook(fallbackBook);
      console.log('🔍 PlaceholderPage: Fallback book set:', fallbackBook);
    } finally {
      setIsLoadingBookInfo(false);
    }
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setSelectedBook(null);
  };

  const handleNavigateToFavourites = () => {
    if (onNavigate) {
      onNavigate('favourites');
    }
  };

  // Profile Settings Handlers
  const handleProfileInputChange = (field: string, value: string) => {
    setProfileSettings(prev => ({ ...prev, [field]: value }));
    // Clear errors when user starts typing
    if (profileErrors[field]) {
      setProfileErrors(prev => ({ ...prev, [field]: '' }));
    }
    // Clear success messages
    if (profileSuccess[field]) {
      setProfileSuccess(prev => ({ ...prev, [field]: '' }));
    }
  };

  const validateProfileSettings = (section: 'username' | 'password') => {
    const newErrors: Record<string, string> = {};

    if (section === 'username') {
      if (!profileSettings.username.trim()) {
        newErrors.username = 'Username is required';
      } else if (profileSettings.username.length < 3) {
        newErrors.username = 'Username must be at least 3 characters';
      } else if (!/^[a-zA-Z0-9_]+$/.test(profileSettings.username)) {
        newErrors.username = 'Username can only contain letters, numbers, and underscores';
      }
    }

    if (section === 'password') {
      if (!profileSettings.currentPassword.trim()) {
        newErrors.currentPassword = 'Current password is required';
      }
      if (!profileSettings.newPassword.trim()) {
        newErrors.newPassword = 'New password is required';
      } else if (profileSettings.newPassword.length < 8) {
        newErrors.newPassword = 'Password must be at least 8 characters';
      }
      if (!profileSettings.confirmPassword.trim()) {
        newErrors.confirmPassword = 'Please confirm your new password';
      } else if (profileSettings.newPassword !== profileSettings.confirmPassword) {
        newErrors.confirmPassword = 'Passwords do not match';
      }
    }

    setProfileErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleUpdateUsername = async () => {
    if (!user || !validateProfileSettings('username')) return;

    setIsUpdating(true);
    try {
      await user.update({
        username: profileSettings.username
      });
      
      setProfileSuccess({ username: 'Username updated successfully!' });
      setTimeout(() => setProfileSuccess(prev => ({ ...prev, username: '' })), 3000);
    } catch (error: any) {
      setProfileErrors({ username: error.errors?.[0]?.message || 'Failed to update username' });
    } finally {
      setIsUpdating(false);
    }
  };

  const handleUpdatePassword = async () => {
    if (!user || !validateProfileSettings('password')) return;

    setIsUpdating(true);
    try {
      // For password updates, we need to use a different approach
      // This would typically involve the user's session and password change flow
      // For now, we'll show a message that this feature requires additional setup
      setProfileErrors({ password: 'Password change requires additional security verification. Please use the "Forgot Password" option from the login screen.' });
    } catch (error: any) {
      setProfileErrors({ password: error.errors?.[0]?.message || 'Failed to update password' });
    } finally {
      setIsUpdating(false);
    }
  };

  const handleProfilePictureUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file || !user) return;

    setIsUploadingImage(true);
    try {
      await user.setProfileImage({ file });
      setProfileSettings(prev => ({ ...prev, profilePicture: user.imageUrl }));
      setProfileSuccess({ profilePicture: 'Profile picture updated successfully!' });
      setTimeout(() => setProfileSuccess(prev => ({ ...prev, profilePicture: '' })), 3000);
    } catch (error: any) {
      setProfileErrors({ profilePicture: error.errors?.[0]?.message || 'Failed to upload profile picture' });
    } finally {
      setIsUploadingImage(false);
    }
  };

  const handleRemoveProfilePicture = async () => {
    if (!user) return;

    setIsUploadingImage(true);
    try {
      await user.setProfileImage({ file: null });
      setProfileSettings(prev => ({ ...prev, profilePicture: null }));
      setProfileSuccess({ profilePicture: 'Profile picture removed successfully!' });
      setTimeout(() => setProfileSuccess(prev => ({ ...prev, profilePicture: '' })), 3000);
    } catch (error: any) {
      setProfileErrors({ profilePicture: error.errors?.[0]?.message || 'Failed to remove profile picture' });
    } finally {
      setIsUploadingImage(false);
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
              className="mb-8 bg-white/10 backdrop-blur-sm border border-white/20 hover:bg-white/20 text-white p-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105 inline-flex items-center justify-center"
              aria-label="Go to Home"
            >
              <Home className="w-6 h-6" />
            </button>
            
            <div className="inline-flex items-center space-x-2 bg-white/10 backdrop-blur-sm border border-white/20 rounded-full px-4 py-2 mb-6">
              <Brain className="w-4 h-4 text-amber-400" />
              <span className="text-sm font-medium text-white/80">Your Personality Analysis</span>
            </div>
            
            <h1 className="text-5xl md:text-6xl font-bold text-white mb-6 leading-tight">
              Your <span className="bg-gradient-to-r from-amber-400 to-orange-500 bg-clip-text text-transparent">Profile</span>
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
                 onClick={() => setActiveTab('profile-settings')}
                 className={`flex-1 px-4 py-3 rounded-xl font-medium transition-all duration-300 ${
                   activeTab === 'profile-settings'
                     ? 'bg-white/20 text-white shadow-lg'
                     : 'text-white/70 hover:text-white hover:bg-white/5'
                 }`}
               >
                 Profile Settings
               </button>
               <button
                 onClick={() => setActiveTab('help')}
                 className={`flex-1 px-4 py-3 rounded-xl font-medium transition-all duration-300 ${
                   activeTab === 'help'
                     ? 'bg-white/20 text-white shadow-lg'
                     : 'text-white/70 hover:text-white hover:bg-white/5'
                 }`}
               >
                 Help
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
            <>
              {/* Favourites Section */}
              <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 mb-8">
                <h2 className="text-3xl font-bold text-white mb-6 flex items-center space-x-3">
                  <Star className="w-8 h-8 text-amber-400" />
                  <span>Your Favourites</span>
                </h2>
                
                {favorites.length === 0 ? (
                  <div className="text-center py-12">
                    <Star className="w-16 h-16 text-white/30 mx-auto mb-4" />
                    <h3 className="text-xl font-semibold text-white mb-2">No Favourites Yet</h3>
                    <p className="text-white/60 mb-6">
                      {profile 
                        ? "You haven't saved any books to your favourites yet. Start exploring and save books you love!"
                        : "Complete the personality quiz to get book recommendations and start building your favourites list."
                      }
                    </p>
                    {!profile && onStartQuiz && (
                      <button
                        onClick={onStartQuiz}
                        className="bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105 inline-flex items-center space-x-2"
                      >
                        <Brain className="w-4 h-4" />
                        <span>Take Personality Quiz</span>
                      </button>
                    )}
                  </div>
                ) : (
                                     <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
                     {favorites.map((book) => (
                       <div key={book.id} className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6 hover:bg-white/10 transition-all duration-300 group">
                         {/* Book Cover */}
                         <div className="flex justify-center mb-4">
                           <div 
                             onClick={(e) => {
                               console.log('🎯 PlaceholderPage: DIV wrapper click detected for:', book.title);
                               e.stopPropagation();
                               handleBookCoverClick(book);
                             }}
                             onMouseDown={(e) => {
                               console.log('🎯 PlaceholderPage: DIV wrapper mousedown detected for:', book.title);
                             }}
                             onMouseUp={(e) => {
                               console.log('🎯 PlaceholderPage: DIV wrapper mouseup detected for:', book.title);
                             }}
                             style={{ zIndex: 5, position: 'relative' }}
                             className="cursor-pointer"
                           >
                             {/* Test button to see if clicks work at all */}
                             <button
                               onClick={(e) => {
                                 console.log('🎯 TEST BUTTON CLICKED for:', book.title);
                                 e.stopPropagation();
                               }}
                               style={{ 
                                 position: 'absolute', 
                                 top: 0, 
                                 left: 0, 
                                 zIndex: 999, 
                                 background: 'red', 
                                 color: 'white', 
                                 padding: '2px 4px', 
                                 fontSize: '10px',
                                 border: 'none',
                                 borderRadius: '2px'
                               }}
                             >
                               TEST
                             </button>
                             <BookCover
                               title={book.title}
                               author={book.author}
                               size="lg"
                               priority="high"
                               lazy={false}
                               clickable={true}
                               onClick={(e) => {
                                 console.log('🎯 PlaceholderPage: BookCover click detected for:', book.title);
                                 e.stopPropagation();
                                 handleBookCoverClick(book);
                               }}
                             />
                           </div>
                         </div>
                         
                         <div className="flex items-start justify-between mb-4">
                           <div className="flex-1">
                             <h3 className="font-semibold text-white mb-2 group-hover:text-amber-400 transition-colors duration-300">
                               {book.title}
                             </h3>
                             <p className="text-white/70 text-sm mb-3">{book.author}</p>
                           </div>
                           <button
                             onClick={() => onRemoveFavorite && onRemoveFavorite(book.id)}
                             className="text-white/40 hover:text-red-400 transition-colors duration-300 ml-2"
                             title="Remove from favourites"
                           >
                             <Star className="w-5 h-5 fill-current" />
                           </button>
                         </div>
                         
                         <p className="text-white/60 text-sm mb-4 line-clamp-3">
                           {book.description}
                         </p>
                         
                         <div className="flex items-center justify-between">
                           <span className="text-amber-400 text-sm font-medium">
                             {book.genre}
                           </span>
                           <a
                             href={book.amazonLink}
                             target="_blank"
                             rel="noopener noreferrer"
                             className="bg-white/10 hover:bg-white/20 text-white px-3 py-1 rounded-lg text-sm transition-all duration-300"
                           >
                             View Book
                           </a>
                         </div>
                       </div>
                     ))}
                   </div>
                )}
              </div>
            </>
          )}

          {activeTab === 'help' && (
            <>
              {/* Help Section */}
              <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 mb-8">
                <h2 className="text-3xl font-bold text-white mb-6 flex items-center space-x-3">
                  <User className="w-8 h-8 text-blue-400" />
                  <span>Help</span>
                </h2>
                
                <div className="space-y-6">
                  <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6">
                    <h3 className="text-xl font-semibold text-white mb-4">How to Use Tailor Page</h3>
                    <div className="space-y-4">
                      <div className="flex items-start space-x-3">
                        <div className="w-6 h-6 bg-amber-500 rounded-full flex items-center justify-center text-white text-sm font-bold mt-0.5">1</div>
                        <div>
                          <p className="text-white/80 font-medium">Take the Personality Quiz</p>
                          <p className="text-white/60 text-sm">Answer 25 questions about your personality and preferences to get started.</p>
                        </div>
                      </div>
                      <div className="flex items-start space-x-3">
                        <div className="w-6 h-6 bg-amber-500 rounded-full flex items-center justify-center text-white text-sm font-bold mt-0.5">2</div>
                        <div>
                          <p className="text-white/80 font-medium">Get Personalized Recommendations</p>
                          <p className="text-white/60 text-sm">Receive 6 book recommendations perfectly matched to your personality.</p>
                        </div>
                      </div>
                      <div className="flex items-start space-x-3">
                        <div className="w-6 h-6 bg-amber-500 rounded-full flex items-center justify-center text-white text-sm font-bold mt-0.5">3</div>
                        <div>
                          <p className="text-white/80 font-medium">Save Your Favorites</p>
                          <p className="text-white/60 text-sm">Click the star icon to save books you love to your favorites list.</p>
                        </div>
                      </div>
                    </div>
                  </div>
                  
                  <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6">
                    <h3 className="text-xl font-semibold text-white mb-4">Tailor Mates Feature</h3>
                    <div className="space-y-4">
                      <div className="flex items-start space-x-3">
                        <div className="w-6 h-6 bg-blue-500 rounded-full flex items-center justify-center text-white text-sm font-bold mt-0.5">1</div>
                        <div>
                          <p className="text-white/80 font-medium">Connect with Fellow Readers</p>
                          <p className="text-white/60 text-sm">Join book clubs and connect with readers who share your personality traits and reading preferences.</p>
                        </div>
                      </div>
                      <div className="flex items-start space-x-3">
                        <div className="w-6 h-6 bg-blue-500 rounded-full flex items-center justify-center text-white text-sm font-bold mt-0.5">2</div>
                        <div>
                          <p className="text-white/80 font-medium">Create or Join Book Clubs</p>
                          <p className="text-white/60 text-sm">Start your own book club or join existing ones based on your personality type and interests.</p>
                        </div>
                      </div>
                      <div className="flex items-start space-x-3">
                        <div className="w-6 h-6 bg-blue-500 rounded-full flex items-center justify-center text-white text-sm font-bold mt-0.5">3</div>
                        <div>
                          <p className="text-white/80 font-medium">Engage in Discussions</p>
                          <p className="text-white/60 text-sm">Participate in meaningful book discussions with like-minded readers who understand your perspective.</p>
                        </div>
                      </div>
                      <div className="flex items-start space-x-3">
                        <div className="w-6 h-6 bg-blue-500 rounded-full flex items-center justify-center text-white text-sm font-bold mt-0.5">4</div>
                        <div>
                          <p className="text-white/80 font-medium">Discover New Perspectives</p>
                          <p className="text-white/60 text-sm">Gain fresh insights on books through discussions with readers who have different but complementary personality traits.</p>
                        </div>
                      </div>
                    </div>
                  </div>
                  
                  <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6">
                    <h3 className="text-xl font-semibold text-white mb-4">Need More Help?</h3>
                    <div className="space-y-4">
                      <div className="flex items-center justify-between">
                        <div>
                          <span className="text-white/80">Contact Support</span>
                          <div className="text-white font-bold text-lg mt-2">thetailorpage@gmail.com</div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>


            </>
          )}

          {activeTab === 'profile-settings' && (
            <>
              {/* Profile Settings Section */}
              <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 mb-8">
                <h2 className="text-3xl font-bold text-white mb-6 flex items-center space-x-3">
                  <User className="w-8 h-8 text-blue-400" />
                  <span>Profile Settings</span>
                </h2>
                
                <div className="space-y-6">
                  {/* Profile Picture Section */}
                  <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6">
                    <h3 className="text-xl font-semibold text-white mb-4">Profile Picture</h3>
                    <div className="flex items-center space-x-6">
                      <div className="relative">
                        {profileSettings.profilePicture ? (
                          <img 
                            src={profileSettings.profilePicture} 
                            alt="Profile" 
                            className="w-20 h-20 rounded-full object-cover border-2 border-white/20"
                          />
                        ) : (
                          <div className="w-20 h-20 bg-gradient-to-br from-amber-400 to-orange-500 rounded-full flex items-center justify-center text-white text-2xl font-bold">
                            {user?.firstName?.charAt(0) || user?.username?.charAt(0) || 'U'}
                          </div>
                        )}
                        <label className="absolute -bottom-1 -right-1 w-6 h-6 bg-amber-500 rounded-full flex items-center justify-center text-white text-sm hover:bg-amber-600 transition-colors duration-300 cursor-pointer">
                          <Camera className="w-3 h-3" />
                          <input
                            type="file"
                            accept="image/*"
                            onChange={handleProfilePictureUpload}
                            className="hidden"
                            disabled={isUploadingImage}
                          />
                        </label>
                      </div>
                      <div className="flex-1">
                        <p className="text-white/80 text-sm mb-2">Upload a profile picture to personalize your account</p>
                        {profileErrors.profilePicture && (
                          <p className="text-red-400 text-sm mb-2">{profileErrors.profilePicture}</p>
                        )}
                        {profileSuccess.profilePicture && (
                          <p className="text-green-400 text-sm mb-2 flex items-center">
                            <Check className="w-4 h-4 mr-1" />
                            {profileSuccess.profilePicture}
                          </p>
                        )}
                        <div className="flex space-x-2">
                          <label className="bg-white/10 hover:bg-white/20 text-white px-4 py-2 rounded-lg text-sm transition-all duration-300 cursor-pointer flex items-center">
                            <Upload className="w-4 h-4 mr-1" />
                            Upload Photo
                            <input
                              type="file"
                              accept="image/*"
                              onChange={handleProfilePictureUpload}
                              className="hidden"
                              disabled={isUploadingImage}
                            />
                          </label>
                          {profileSettings.profilePicture && (
                            <button 
                              onClick={handleRemoveProfilePicture}
                              disabled={isUploadingImage}
                              className="bg-white/5 hover:bg-white/10 text-white/60 hover:text-white px-4 py-2 rounded-lg text-sm transition-all duration-300 disabled:opacity-50"
                            >
                              Remove
                            </button>
                          )}
                        </div>
                        {isUploadingImage && (
                          <p className="text-white/60 text-sm mt-2">Uploading...</p>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* Account Information Section */}
                  <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6">
                    <h3 className="text-xl font-semibold text-white mb-4">Account Information</h3>
                    <div className="space-y-4">
                      <div>
                        <label className="block text-white/80 text-sm font-medium mb-2">Username</label>
                        <div className="flex items-center space-x-2">
                          <input 
                            type="text" 
                            value={profileSettings.username}
                            onChange={(e) => handleProfileInputChange('username', e.target.value)}
                            className="flex-1 bg-white/10 border border-white/20 rounded-lg px-3 py-2 text-white placeholder-white/40 focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-transparent"
                            placeholder="Enter your username"
                          />
                          <button 
                            onClick={handleUpdateUsername}
                            disabled={isUpdating}
                            className="bg-amber-500 hover:bg-amber-600 disabled:bg-amber-500/50 text-white px-4 py-2 rounded-lg text-sm transition-all duration-300 flex items-center"
                          >
                            {isUpdating ? (
                              <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin mr-2" />
                            ) : (
                              <Check className="w-4 h-4 mr-1" />
                            )}
                            Update
                          </button>
                        </div>
                        {profileErrors.username && (
                          <p className="text-red-400 text-sm mt-2">{profileErrors.username}</p>
                        )}
                        {profileSuccess.username && (
                          <p className="text-green-400 text-sm mt-2 flex items-center">
                            <Check className="w-4 h-4 mr-1" />
                            {profileSuccess.username}
                          </p>
                        )}
                      </div>
                      
                      <div>
                        <label className="block text-white/80 text-sm font-medium mb-2">Email</label>
                        <input 
                          type="email" 
                          value={profileSettings.email}
                          disabled
                          className="w-full bg-white/5 border border-white/10 rounded-lg px-3 py-2 text-white/60 cursor-not-allowed"
                          placeholder="Email cannot be changed"
                        />
                        <p className="text-white/60 text-xs mt-1">Email address cannot be changed for security reasons</p>
                      </div>
                    </div>
                  </div>

                  {/* Password Change Section */}
                  <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6">
                    <h3 className="text-xl font-semibold text-white mb-4">Change Password</h3>
                    <div className="space-y-4">
                      <div>
                        <label className="block text-white/80 text-sm font-medium mb-2">Current Password</label>
                        <input 
                          type="password" 
                          value={profileSettings.currentPassword}
                          onChange={(e) => handleProfileInputChange('currentPassword', e.target.value)}
                          className="w-full bg-white/10 border border-white/20 rounded-lg px-3 py-2 text-white placeholder-white/40 focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-transparent"
                          placeholder="Enter current password"
                        />
                        {profileErrors.currentPassword && (
                          <p className="text-red-400 text-sm mt-2">{profileErrors.currentPassword}</p>
                        )}
                      </div>
                      
                      <div>
                        <label className="block text-white/80 text-sm font-medium mb-2">New Password</label>
                        <input 
                          type="password" 
                          value={profileSettings.newPassword}
                          onChange={(e) => handleProfileInputChange('newPassword', e.target.value)}
                          className="w-full bg-white/10 border border-white/20 rounded-lg px-3 py-2 text-white placeholder-white/40 focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-transparent"
                          placeholder="Enter new password"
                        />
                        {profileErrors.newPassword && (
                          <p className="text-red-400 text-sm mt-2">{profileErrors.newPassword}</p>
                        )}
                      </div>
                      
                      <div>
                        <label className="block text-white/80 text-sm font-medium mb-2">Confirm New Password</label>
                        <input 
                          type="password" 
                          value={profileSettings.confirmPassword}
                          onChange={(e) => handleProfileInputChange('confirmPassword', e.target.value)}
                          className="w-full bg-white/10 border border-white/20 rounded-lg px-3 py-2 text-white placeholder-white/40 focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-transparent"
                          placeholder="Confirm new password"
                        />
                        {profileErrors.confirmPassword && (
                          <p className="text-red-400 text-sm mt-2">{profileErrors.confirmPassword}</p>
                        )}
                      </div>
                      
                      {profileErrors.password && (
                        <div className="bg-red-500/10 border border-red-500/20 rounded-lg p-3">
                          <p className="text-red-400 text-sm">{profileErrors.password}</p>
                        </div>
                      )}
                      
                      {profileSuccess.password && (
                        <div className="bg-green-500/10 border border-green-500/20 rounded-lg p-3">
                          <p className="text-green-400 text-sm flex items-center">
                            <Check className="w-4 h-4 mr-1" />
                            {profileSuccess.password}
                          </p>
                        </div>
                      )}
                      
                      <button 
                        onClick={handleUpdatePassword}
                        disabled={isUpdating}
                        className="w-full bg-amber-500 hover:bg-amber-600 disabled:bg-amber-500/50 text-white px-4 py-2 rounded-lg font-medium transition-all duration-300 flex items-center justify-center"
                      >
                        {isUpdating ? (
                          <>
                            <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin mr-2" />
                            Updating...
                          </>
                        ) : (
                          <>
                            <Check className="w-4 h-4 mr-1" />
                            Update Password
                          </>
                        )}
                      </button>
                    </div>
                  </div>

                  {/* Notification Settings */}
                  <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6">
                    <h3 className="text-xl font-semibold text-white mb-4">Notification Settings</h3>
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
                  
                  {/* Privacy Settings */}
                  <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6">
                    <h3 className="text-xl font-semibold text-white mb-4">Privacy Settings</h3>
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

                  {/* Log Out Button */}
                  <div className="flex justify-end mt-8">
                    <button
                      onClick={onLogout}
                      className="bg-red-600 hover:bg-red-700 text-white px-6 py-3 rounded-xl font-semibold transition-all duration-300 shadow-lg"
                    >
                      Log Out
                    </button>
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
            className="mb-8 bg-white/10 backdrop-blur-sm border border-white/20 hover:bg-white/20 text-white p-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105 inline-flex items-center justify-center"
            aria-label="Go to Home"
          >
            <Home className="w-6 h-6" />
          </button>
          
          <div className="inline-flex items-center space-x-2 bg-white/10 backdrop-blur-sm border border-white/20 rounded-full px-4 py-2 mb-6">
            <User className="w-4 h-4 text-amber-400" />
            <span className="text-sm font-medium text-white/80">Your Profile</span>
          </div>
          
          <h1 className="text-4xl md:text-5xl font-bold text-white mb-8 leading-tight">
            <span className="text-white">Create Your </span>
            <span className="bg-gradient-to-r from-amber-400 to-orange-500 bg-clip-text text-transparent">Reading Profile</span>
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

        {/* Log Out Button */}
        <div className="flex justify-center">
          <button
            onClick={onLogout}
            className="bg-red-600 hover:bg-red-700 text-white px-6 py-3 rounded-xl font-semibold transition-all duration-300 shadow-lg"
          >
            Log Out
          </button>
        </div>
      </div>
      
      {/* Book Summary Modal */}
      {(() => {
        console.log('🔍 PlaceholderPage: Modal rendering check - selectedBook:', !!selectedBook, 'isModalOpen:', isModalOpen);
        return selectedBook && isModalOpen && (
          <BookSummaryModal
            book={selectedBook}
            isOpen={isModalOpen}
            onClose={handleCloseModal}
          />
        );
      })()}
    </div>
  );
};

export default PlaceholderPage;