import React, { useState, useEffect } from 'react';
import { Book, Users, Heart, Brain, Star, ArrowRight, Sparkles, Target, Zap, BookOpen, UserCheck, Bell } from 'lucide-react';
import Logo from './Logo';
import NotificationsPanel from './NotificationsPanel';
import { TailorMatesService } from '../services/tailorMatesService';

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
  onNavigateToMessages?: (conversationId?: string) => void;
  onNavigateToPendingRequests?: () => void;
  onNavigateToInvitations?: () => void;
  onNavigateToClub?: (clubId?: string) => void;
  onNavigateToDiscussion?: (discussionId?: string) => void;
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
  onNavigateToMessages,
  onNavigateToPendingRequests,
  onNavigateToInvitations,
  onNavigateToClub,
  onNavigateToDiscussion,
  user
}) => {
  const [showNotifications, setShowNotifications] = useState(false);
  const [unreadNotificationCount, setUnreadNotificationCount] = useState(0);
  
  // Load notification count when user is logged in
  useEffect(() => {
    const loadNotificationCount = async () => {
      if (isLoggedIn && user) {
        try {
          const count = await TailorMatesService.getUnreadNotificationCount();
          setUnreadNotificationCount(count);
        } catch (error) {
          console.error('Error loading notification count:', error);
          setUnreadNotificationCount(0);
        }
      } else {
        setUnreadNotificationCount(0);
      }
    };

    loadNotificationCount();
    
    // Refresh notification count every 30 seconds
    const interval = setInterval(loadNotificationCount, 30000);
    
    return () => clearInterval(interval);
  }, [isLoggedIn, user]);
  
  // Debug logging to understand the state
  console.log('WelcomePage render - isLoggedIn:', isLoggedIn, 'hasCompletedQuiz:', hasCompletedQuiz, 'hasQuizProgress:', hasQuizProgress);
  console.log('WelcomePage user data:', user);
  console.log('WelcomePage user imageUrl:', user?.imageUrl);
  return (
    <div className="min-h-screen flex items-center justify-center p-4 sm:p-6 md:p-8 pb-20 sm:pb-8 relative overflow-hidden">
      {/* Background Elements */}
      <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900" />
      <div className="absolute top-20 left-20 w-72 h-72 bg-purple-500/10 rounded-full blur-3xl hidden md:block" />
      <div className="absolute bottom-20 right-20 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl hidden md:block" />
      
      {/* Top Left Notifications Bell */}
      <div className="absolute top-4 left-4 sm:top-6 sm:left-6 z-20">
        <button
          onClick={() => {
            if (!isLoggedIn) {
              onAuthPrompt?.('login', 'notifications');
            } else {
              setShowNotifications(true);
            }
          }}
          className="p-2 sm:p-3 rounded-full bg-white/10 backdrop-blur-sm border border-white/20 hover:bg-white/20 transition-all duration-200 group relative"
          title={isLoggedIn ? "View Notifications" : "Sign in to view notifications"}
        >
          <Bell 
            className="w-5 h-5 sm:w-6 sm:h-6 text-white group-hover:text-amber-400 transition-colors duration-200" 
          />
          {/* Real notification badge */}
          {isLoggedIn && unreadNotificationCount > 0 && (
            <span className="absolute -top-1 -right-1 bg-red-500 text-white text-xs px-1.5 sm:px-2 py-0.5 sm:py-1 rounded-full min-w-[18px] sm:min-w-[20px] text-center text-[10px] sm:text-xs">
              {unreadNotificationCount > 99 ? '99+' : unreadNotificationCount}
            </span>
          )}
        </button>
      </div>

      {/* Top Center Profile Picture or Sign In Button - Hidden on mobile, shown on desktop */}
      <div className="absolute top-4 left-1/2 transform -translate-x-1/2 z-20 sm:top-6 hidden sm:block">
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
            <div className="text-white text-left">
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

      {/* User Info - Top Right (Mobile only) */}
      {isLoggedIn && user && (
        <div className="fixed top-4 right-4 z-50 sm:hidden">
          <div className="text-white text-right">
            <div className="font-semibold text-xs truncate max-w-[120px]">{user.name}</div>
            <div className="text-[10px] text-white/70 truncate max-w-[120px]">@{user.username}</div>
          </div>
        </div>
      )}
      
      <div className="max-w-7xl mx-auto relative z-10 w-full mt-12 sm:mt-20 md:mt-0">
        <div className="grid lg:grid-cols-2 gap-8 sm:gap-12 lg:gap-16 items-center">
          {/* Left Content */}
          <div className="text-center sm:text-left">
            <div className="mb-6 sm:mb-8">
              <div className="mb-6 sm:mb-8 flex justify-center sm:justify-start">
                <Logo size="lg" showText={true} />
              </div>
              
              <h1 className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl xl:text-7xl font-bold text-white mb-4 sm:mb-6 md:mb-8 leading-tight tracking-tight">
                <span className="block mb-1 sm:mb-2">Discover Your</span>
                <span className="bg-gradient-to-r from-amber-400 via-orange-500 to-amber-500 bg-clip-text text-transparent drop-shadow-sm">Perfect Books</span>
              </h1>
              
              <p className="text-base sm:text-lg md:text-xl text-white/80 mb-6 sm:mb-8 md:mb-10 leading-relaxed max-w-2xl mx-auto sm:mx-0 font-medium px-2 sm:px-0">
                Get personalized book recommendations tailored to your unique personality through our advanced AI-powered quiz system.
              </p>
            </div>

            {/* Stats */}
            {/* Removed stats section */}

            {/* CTA Buttons */}
            <div className="flex flex-col sm:flex-row gap-3 sm:gap-4 justify-center sm:justify-start">
              {isLoggedIn && hasCompletedQuiz && onGenerateNewBooks ? (
                <button
                  onClick={onGenerateNewBooks}
                  className="bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white px-6 py-3 sm:px-8 sm:py-4 rounded-xl font-semibold text-base sm:text-lg transition-all duration-300 transform hover:scale-105 hover:shadow-2xl inline-flex items-center justify-center space-x-2 group w-full sm:w-auto"
                >
                  <span>Generate New Books</span>
                  <ArrowRight className="w-4 h-4 sm:w-5 sm:h-5 group-hover:translate-x-1 transition-transform" />
                </button>
              ) : hasCompletedQuiz && !isLoggedIn ? (
                <button
                  onClick={() => onAuthPrompt?.('login', 'access profile')}
                  className="bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-600 hover:to-purple-700 text-white px-6 py-3 sm:px-8 sm:py-4 rounded-xl font-semibold text-base sm:text-lg transition-all duration-300 transform hover:scale-105 hover:shadow-2xl inline-flex items-center justify-center space-x-2 group w-full sm:w-auto"
                >
                  <UserCheck className="w-4 h-4 sm:w-5 sm:h-5" />
                  <span>View Profile</span>
                </button>
              ) : (
                <button
                  onClick={hasQuizProgress ? onResumeQuiz : onStartQuiz}
                  className="bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white px-6 py-3 sm:px-8 sm:py-4 rounded-xl font-semibold text-base sm:text-lg transition-all duration-300 transform hover:scale-105 hover:shadow-2xl inline-flex items-center justify-center space-x-2 group w-full sm:w-auto"
                >
                  <span>{hasQuizProgress ? 'Resume Quiz' : 'Start Discovery'}</span>
                  <ArrowRight className="w-4 h-4 sm:w-5 sm:h-5 group-hover:translate-x-1 transition-transform" />
                </button>
              )}
              <button
                onClick={onLearnMore}
                className="bg-white/10 hover:bg-white/20 backdrop-blur-sm border border-white/20 text-white px-6 py-3 sm:px-8 sm:py-4 rounded-xl font-semibold text-base sm:text-lg transition-all duration-300 transform hover:scale-105 w-full sm:w-auto"
              >
                Learn More
              </button>
            </div>
          </div>

          {/* Right Content - Feature Cards */}
          <div className="relative mt-8 lg:mt-0">
            <div className="grid gap-4 sm:gap-6">
              {/* Main Feature Card */}
              <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6 sm:p-8 hover:bg-white/15 transition-all duration-300 transform hover:scale-105">
                <div className="flex items-center space-x-3 sm:space-x-4 mb-4 sm:mb-6">
                  <div className="w-10 h-10 sm:w-12 sm:h-12 bg-gradient-to-r from-amber-500 to-orange-600 rounded-xl flex items-center justify-center flex-shrink-0">
                    <Brain className="w-5 h-5 sm:w-6 sm:h-6 text-white" />
                  </div>
                  <div>
                    <h3 className="text-lg sm:text-xl font-bold text-white">Smart Algorithm</h3>
                    <p className="text-sm sm:text-base text-white/70">AI-powered personality analysis</p>
                  </div>
                </div>
                <p className="text-sm sm:text-base text-white/70 leading-relaxed">
                  Our advanced algorithm analyses your personality traits to recommend books that perfectly match your reading preferences and interests.
                </p>
              </div>

              {/* Secondary Feature Cards */}
              <div className="grid grid-cols-2 gap-3 sm:gap-4">
                <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-xl p-4 sm:p-6 hover:bg-white/15 transition-all duration-300">
                  <Target className="w-6 h-6 sm:w-8 sm:h-8 text-amber-400 mb-3 sm:mb-4" />
                  <h4 className="font-semibold text-white mb-1 sm:mb-2 text-sm sm:text-base">Personalised</h4>
                  <p className="text-xs sm:text-sm text-white/70">Tailored to your unique taste</p>
                </div>
                
                <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-xl p-4 sm:p-6 hover:bg-white/15 transition-all duration-300">
                  <Zap className="w-6 h-6 sm:w-8 sm:h-8 text-amber-400 mb-3 sm:mb-4" />
                  <h4 className="font-semibold text-white mb-1 sm:mb-2 text-sm sm:text-base">Instant</h4>
                  <p className="text-xs sm:text-sm text-white/70">Get results in seconds</p>
                </div>
              </div>
            </div>

            {/* Floating Elements - Hidden on mobile */}
            <div className="absolute -top-4 -right-4 w-20 h-20 bg-gradient-to-r from-purple-500/20 to-pink-500/20 rounded-full blur-xl hidden md:block" />
            <div className="absolute -bottom-8 -left-8 w-32 h-32 bg-gradient-to-r from-blue-500/20 to-cyan-500/20 rounded-full blur-xl hidden md:block" />
          </div>
        </div>


      </div>

      {/* Notifications Panel */}
      <NotificationsPanel
        isOpen={showNotifications}
        onClose={() => {
          setShowNotifications(false);
          // Refresh notification count when panel is closed
          if (isLoggedIn && user) {
            TailorMatesService.getUnreadNotificationCount()
              .then(count => setUnreadNotificationCount(count))
              .catch(error => console.error('Error refreshing notification count:', error));
          }
        }}
        user={user}
        onNotificationClick={async (notification) => {
          // Mark notification as read
          if (!notification.isRead) {
            try {
              await TailorMatesService.markNotificationAsRead(notification.id);
            } catch (error) {
              console.error('Error marking notification as read:', error);
            }
          }
          
          setShowNotifications(false);
          
          if (notification.type === 'friend_message' && notification.relatedId) {
            onNavigateToMessages?.(notification.relatedId);
          } else if (notification.type === 'friend_request' && notification.relatedId) {
            onNavigateToPendingRequests?.();
          } else if (notification.type === 'club_invitation' && notification.relatedId) {
            onNavigateToInvitations?.();
          } else if (notification.type === 'club_message' && notification.relatedId) {
            onNavigateToClub?.(notification.relatedId);
          } else if (notification.type === 'discussion_message' && notification.relatedId) {
            onNavigateToDiscussion?.(notification.relatedId);
          }
        }}
      />
    </div>
  );
};

export default WelcomePage;