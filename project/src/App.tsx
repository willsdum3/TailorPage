import React, { useState, useEffect } from 'react';
import { useAuth } from './contexts/AuthContext';
import WelcomePage from './components/WelcomePage';
import QuizPage from './components/QuizPage';
import ResultsPage from './components/ResultsPage';
import GeneratedRecommendationsPage from './components/GeneratedRecommendationsPage';
import CelebrityTesterPage from './components/CelebrityTesterPage';
import TrendingBooksPage from './components/TrendingBooksPage';
import TrendingAuthorsPage from './components/TrendingAuthorsPage';
import TailorMatesPage from './components/TailorMatesPage';
import PlaceholderPage from './components/PlaceholderPage';
import LearnMorePage from './components/LearnMorePage';
import BurgerMenu from './components/BurgerMenu';
import { AuthModal } from './components/AuthModal';
import { useScrollToTopInstant } from './hooks/useScrollToTop';
import { 
  getUserPersonalityProfile, 
  saveUserPersonalityProfile, 
  getUserFavorites, 
  addBookToFavorites, 
  removeBookFromFavorites 
} from './lib/supabase';
import { 
  PersonalityProfile, 
  BookRecommendation, 
  FavoriteBook, 
  User,
  LikertResponse,
  BookResponse,
  Question,
  BookQuestion
} from './types';
import { getBookRecommendationsWithExpandedMatching } from './utils/bookRecommendationsOptimized';
import { normalizeFavoriteFromDatabase, removeFavoriteByTitleAuthor } from './utils/favoritesUtils';

// Function to calculate personality profile from quiz answers
const calculatePersonalityProfile = (answers: Record<number, LikertResponse>, bookAnswers: Record<number, BookResponse>): PersonalityProfile => {
  const profile: PersonalityProfile = {
    openness: 0,
    conscientiousness: 0,
    extraversion: 0,
    agreeableness: 0,
    emotionalStability: 0,
    rationalThinking: 0,
    coreValues: 0,
    lifestyle: 0,
    socialStyle: 0,
    selfExpression: 0
  };

  // Calculate scores based on statement answers
  Object.entries(answers).forEach(([questionId, answer]) => {
    const question = questions.find(q => q.id === parseInt(questionId));
    if (question && question.type === 'statement') {
      const trait = question.trait as keyof PersonalityProfile;
      // Invert the scoring: 1 (Strongly Agree) should be high, 5 (Strongly Disagree) should be low
      const invertedScore = 6 - answer; // 1 becomes 5, 2 becomes 4, 3 stays 3, 4 becomes 2, 5 becomes 1
      profile[trait] += invertedScore;
    }
  });

  // Calculate scores based on book answers
  Object.entries(bookAnswers).forEach(([questionId, answer]) => {
    const question = questions.find(q => q.id === parseInt(questionId));
    if (question && question.type === 'book') {
      const trait = question.trait as keyof PersonalityProfile;
      // Book answers are 'yes'/'no', convert to numeric score
      const score = answer === 'yes' ? 4 : 2; // Higher score for 'yes' answers
      profile[trait] += score;
    }
  });

  // Normalize scores to 1-25 range to match the UI expectations
  // Calculate max possible scores for each trait
  const maxScores = {
    openness: 8 * 5 + 4, // 8 statements (max 5 each) + 1 book (max 4)
    conscientiousness: 6 * 5 + 4, // 6 statements + 1 book
    extraversion: 4 * 5 + 4, // 4 statements + 1 book
    agreeableness: 9 * 5 + 4, // 9 statements + 1 book
    emotionalStability: 8 * 5 + 4, // 8 statements + 1 book
    rationalThinking: 0, // Not used in current quiz
    coreValues: 0,
    lifestyle: 0,
    socialStyle: 0,
    selfExpression: 0
  };

  Object.keys(profile).forEach(trait => {
    const key = trait as keyof PersonalityProfile;
    const maxScore = maxScores[key];
    if (maxScore > 0) {
      // Scale to 1-25 range based on percentage of max score
      const percentage = profile[key] / maxScore;
      profile[key] = Math.max(1, Math.min(25, Math.round(percentage * 25)));
    } else {
      profile[key] = 13; // Default middle score for unused traits (13/25)
    }
  });

  return profile;
};

// Book questions for the quiz
const bookQuestions: BookQuestion[] = [
  {
    id: 6,
    title: "Invisible Cities",
    author: "Italo Calvino",
    description: "An experimental, poetic work in which Marco Polo describes fantastical cities to Kublai Khan.",
    trait: "openness",
    coverImageUrl: "/book-covers/InvisibleCities.jpg"
  },
  {
    id: 12,
    title: "Man's Search for Meaning",
    author: "Viktor E. Frankl",
    description: "A powerful memoir and philosophical reflection on purpose, responsibility, and resilience in the face of suffering.",
    trait: "conscientiousness",
    coverImageUrl: "/book-covers/MansSearchForMeaning.jpg"
  },
  {
    id: 18,
    title: "Where the Crawdads Sing",
    author: "Delia Owens",
    description: "It includes themes of solitude, it offers rich emotional relationships, courtroom drama, and a strong female lead.",
    trait: "extraversion",
    coverImageUrl: "/book-covers/WhereTheCrawdadsSing.jpg"
  },
  {
    id: 24,
    title: "Wonder",
    author: "R.J. Palacio",
    description: "A moving middle-grade novel about a boy with a facial difference navigating school and relationships.",
    trait: "agreeableness",
    coverImageUrl: "/book-covers/Wonder.jpg"
  },
  {
    id: 30,
    title: "Stillness Is the Key",
    author: "Ryan Holiday",
    description: "A modern take on ancient wisdom promoting inner calm, clarity, and balance in a busy world.",
    trait: "emotionalStability",
    coverImageUrl: "/book-covers/StillnessIsTheKey.jpg"
  }
];

const questions: Question[] = [
  {
    id: 1,
    text: "I forgive others easily.",
    trait: "agreeableness",
    type: "statement"
  },
  {
    id: 2,
    text: "I enjoy trying new and different things.",
    trait: "openness",
    type: "statement"
  },
  {
    id: 3,
    text: "I get upset or irritated quickly.",
    trait: "emotionalStability",
    type: "statement"
  },
  {
    id: 4,
    text: "I follow through with my plans.",
    trait: "conscientiousness",
    type: "statement"
  },
  {
    id: 5,
    text: "I am interested in the well-being of others.",
    trait: "agreeableness",
    type: "statement"
  },
  // Book question after 5 statements
  {
    id: 6,
    text: "Does this sort of book interest you?",
    trait: "openness",
    type: "book"
  },
  {
    id: 7,
    text: "I enjoy being the center of attention.",
    trait: "extraversion",
    type: "statement"
  },
  {
    id: 8,
    text: "I pay close attention to detail.",
    trait: "conscientiousness",
    type: "statement"
  },
  {
    id: 9,
    text: "I experience frequent mood swings.",
    trait: "emotionalStability",
    type: "statement"
  },
  {
    id: 10,
    text: "I prefer variety over routine.",
    trait: "openness",
    type: "statement"
  },
  {
    id: 11,
    text: "I sympathize with people who are struggling.",
    trait: "agreeableness",
    type: "statement"
  },
  // Book question after 10 statements
  {
    id: 12,
    text: "Does this sort of book interest you?",
    trait: "conscientiousness",
    type: "book"
  },
  {
    id: 13,
    text: "I often feel anxious or tense.",
    trait: "emotionalStability",
    type: "statement"
  },
  {
    id: 14,
    text: "I finish tasks successfully.",
    trait: "conscientiousness",
    type: "statement"
  },
  {
    id: 15,
    text: "I am curious about many different topics.",
    trait: "openness",
    type: "statement"
  },
  {
    id: 16,
    text: "I make people feel comfortable and valued.",
    trait: "agreeableness",
    type: "statement"
  },
  {
    id: 17,
    text: "I worry about things.",
    trait: "emotionalStability",
    type: "statement"
  },
  // Book question after 15 statements
  {
    id: 18,
    text: "Does this sort of book interest you?",
    trait: "extraversion",
    type: "book"
  },
  {
    id: 19,
    text: "I have a vivid imagination.",
    trait: "openness",
    type: "statement"
  },
  {
    id: 20,
    text: "I am generally trusting.",
    trait: "agreeableness",
    type: "statement"
  },
  {
    id: 21,
    text: "I am relaxed most of the time.",
    trait: "emotionalStability",
    type: "statement"
  },
  {
    id: 22,
    text: "I am outgoing and sociable.",
    trait: "extraversion",
    type: "statement"
  },
  {
    id: 23,
    text: "I am sometimes rude to others.",
    trait: "agreeableness",
    type: "statement"
  },
  // Book question after 20 statements
  {
    id: 24,
    text: "Does this sort of book interest you?",
    trait: "agreeableness",
    type: "book"
  },
  {
    id: 25,
    text: "I make plans and stick to them.",
    trait: "conscientiousness",
    type: "statement"
  },
  {
    id: 26,
    text: "I get nervous easily.",
    trait: "emotionalStability",
    type: "statement"
  },
  {
    id: 27,
    text: "I like to reflect and play with ideas.",
    trait: "openness",
    type: "statement"
  },
  {
    id: 28,
    text: "I have few artistic interests.",
    trait: "openness",
    type: "statement"
  },
  {
    id: 29,
    text: "I like to cooperate with others.",
    trait: "agreeableness",
    type: "statement"
  },
  // Book question after 25 statements
  {
    id: 30,
    text: "Does this sort of book interest you?",
    trait: "emotionalStability",
    type: "book"
  }
];

type AppPage = 'welcome' | 'quiz' | 'results' | 'generated' | 'celebrity-books' | 'trending-books' | 'trending-authors' | 'tailor-mates' | 'favourites' | 'learn-more' | 'profile' | 'book-cover-test';

function App() {
  // Use Supabase authentication
  const { user: supabaseUser, session, loading: authLoading, signOut } = useAuth();
  const [currentPage, setCurrentPage] = useState<AppPage>('welcome');
  const [answers, setAnswers] = useState<Record<number, LikertResponse>>({});
  const [bookAnswers, setBookAnswers] = useState<Record<number, BookResponse>>({});
  const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);
  const [personalityProfile, setPersonalityProfile] = useState<PersonalityProfile | null>(null);
  const [favorites, setFavorites] = useState<FavoriteBook[]>([]);
  const [isAuthModalOpen, setIsAuthModalOpen] = useState(false);
  const [authModalMode, setAuthModalMode] = useState<'login' | 'signup'>('login');
  const [requestedFeature, setRequestedFeature] = useState<string | null>(null);
  const [recommendations, setRecommendations] = useState<BookRecommendation[]>([]);
  const [allRecommendedIds, setAllRecommendedIds] = useState<string[]>([]);
  const [celebrityNavigationCount, setCelebrityNavigationCount] = useState(0);
  const [favoriteLoadingStates, setFavoriteLoadingStates] = useState<Set<string>>(new Set());
  const [lastLoadedUserId, setLastLoadedUserId] = useState<string | null>(null);

  // Scroll to top when page changes
  useScrollToTopInstant([currentPage]);

  // Convert Supabase user to our User type
  const user: User | null = supabaseUser ? {
    id: supabaseUser.id,
    name: supabaseUser.user_metadata?.name || supabaseUser.user_metadata?.full_name || 'User',
    username: supabaseUser.user_metadata?.username || supabaseUser.email?.split('@')[0] || 'user',
    email: supabaseUser.email || '',
    imageUrl: supabaseUser.user_metadata?.avatar_url || undefined
  } : null;

  // Check if user is authenticated
  const isAuthenticated = supabaseUser !== null;

  // Close auth modal when user becomes authenticated and redirect based on requested feature
  useEffect(() => {
    if (!authLoading && supabaseUser && isAuthModalOpen) {
      setIsAuthModalOpen(false);
      
      // Redirect based on requested feature
      if (requestedFeature === 'access profile') {
        setCurrentPage('profile');
        setRequestedFeature(null);
      } else if (requestedFeature === 'access Tailor Mates') {
        setCurrentPage('tailor-mates');
        setRequestedFeature(null);
      } else {
        // Default redirect to welcome page
        setCurrentPage('welcome');
        setRequestedFeature(null);
      }
    }
  }, [authLoading, supabaseUser, isAuthModalOpen, requestedFeature]);

  // Load user data from database when user is authenticated
  useEffect(() => {
    console.log('🔄 loadUserData useEffect triggered');
    console.log('  - user?.id:', user?.id);
    console.log('  - authLoading:', authLoading);
    console.log('  - current favorites count:', favorites.length);
    console.log('  - current personalityProfile:', !!personalityProfile);
    
    // Don't load data while auth is still loading
    if (authLoading) {
      console.log('⏳ Auth still loading, skipping user data load');
      return;
    }
    
    if (user && user.id) {
      console.log('✅ Loading user data for user:', user.id);
      
          // Check if we already loaded data for this specific user
    if (lastLoadedUserId === user.id && personalityProfile) {
      console.log('ℹ️ Data already loaded for this user, skipping reload');
      return;
    }
    
    // Clear any existing data when switching users
    if (lastLoadedUserId && lastLoadedUserId !== user.id) {
      console.log('🔄 User ID changed, clearing previous user data');
      setFavorites([]);
      setPersonalityProfile(null);
      setLastLoadedUserId(null);
    }
      
      console.log('🔄 Loading fresh data from database');
      
      const loadUserData = async () => {
        try {
          // Load personality profile first
          console.log('📊 Loading personality profile...');
          const profile = await getUserPersonalityProfile(user.id);
          if (profile) {
            console.log('✅ Personality profile loaded:', profile);
            setPersonalityProfile(profile);
          } else {
            console.log('ℹ️ No personality profile found for user');
            setPersonalityProfile(null);
          }
          
          // Load favorites
          console.log('❤️ Loading favorites...');
          const dbFavorites = await getUserFavorites(user.id);
          console.log('📚 getUserFavorites returned:', dbFavorites);
          
          if (Array.isArray(dbFavorites) && dbFavorites.length > 0) {
            const formattedFavorites: FavoriteBook[] = dbFavorites.map((fav: any) => 
              normalizeFavoriteFromDatabase(fav)
            );
            console.log('✅ Raw database favorites:', dbFavorites);
            console.log('✅ Formatted favorites:', formattedFavorites);
            setFavorites(formattedFavorites);
          } else {
            console.log('ℹ️ No favorites found, setting empty array');
            setFavorites([]);
          }
          
          // Track that we've loaded data for this user
          setLastLoadedUserId(user.id);
          console.log('✅ Data loading complete for user:', user.id);
        } catch (error) {
          console.error('❌ Error loading user data:', error);
          // Don't clear existing data on error - keep what we have
          console.log('⚠️ Keeping existing data due to loading error');
        }
      };
      
      // Load data immediately without delay
      loadUserData();
    } else {
      console.log('🚪 No user or no user.id, clearing user data');
      // Clear user data when user logs out
      setFavorites([]);
      setPersonalityProfile(null);
      setLastLoadedUserId(null);
      // Clear quiz state to prevent showing previous user's progress
      setAnswers({});
      setBookAnswers({});
      setCurrentQuestionIndex(0);
      setRecommendations([]);
      setAllRecommendedIds([]);
      
      // Force clear any remaining state that might affect the UI
      console.log('🧹 Cleared all user data and quiz state');
    }
  }, [user?.id, authLoading]); // Only trigger when user ID changes, not the entire user object



  const handleAuthPrompt = (mode: 'login' | 'signup' = 'signup', feature?: string) => {
    setAuthModalMode(mode);
    setIsAuthModalOpen(true);
    setRequestedFeature(feature || null);
    if (feature) {
      console.log(`User prompted to ${mode} for feature: ${feature}`);
    }
  };

  const handleToggleFavorite = async (book: BookRecommendation) => {
    console.log('🔍 handleToggleFavorite called with book:', book);
    console.log('🔍 isAuthenticated:', isAuthenticated);
    console.log('🔍 user:', user);
    
    if (!isAuthenticated) {
      console.log('🔍 User not authenticated, prompting login');
      handleAuthPrompt('login', 'favorite books');
      return;
    }

    if (!user) {
      console.log('🔍 No user object found');
      return;
    }

    // Create a unique key for this book to track loading state
    const bookKey = `${book.title}-${book.author}`;
    
    // Set loading state for this specific book
    setFavoriteLoadingStates(prev => new Set(prev).add(bookKey));

    try {
      console.log('🔍 Checking if book is already favorited...');
      const isFavorited = favorites.some(fav => 
        fav.title.toLowerCase() === book.title.toLowerCase() && 
        fav.author.toLowerCase() === book.author.toLowerCase()
      );
      console.log('🔍 isFavorited:', isFavorited);

      if (isFavorited) {
        console.log('🔍 Removing book from favorites...');
        // Remove from UI first for immediate feedback
        setFavorites(prev => removeFavoriteByTitleAuthor(prev, book.title, book.author));
        console.log('✅ Book removed from UI favorites immediately:', book.title);
        
        // Then try to remove from database
        const success = await removeBookFromFavorites(user.id, book.title, book.author);
        console.log('🔍 removeBookFromFavorites result:', success);
        
        if (!success) {
          console.warn('⚠️ Database removal failed, but book remains removed from UI favorites');
          // Optionally re-add to UI if database removal fails
          // setFavorites(prev => [...prev, newFavorite]);
        }
      } else {
        console.log('🔍 Adding book to favorites...');
        
        // Create new favorite object
        const newFavorite: FavoriteBook = {
          id: Date.now().toString(), // Temporary ID
          title: book.title,
          author: book.author,
          genre: book.genre,
          description: book.description,
          amazonLink: book.amazonLink || '',
          coverImageUrl: book.coverImageUrl || '',
          reason: book.reason || '',
          dateAdded: new Date().toISOString()
        };
        
        // Add to UI first for immediate feedback
        setFavorites(prev => [...prev, newFavorite]);
        console.log('✅ Book added to UI favorites immediately:', book.title);
        
        // Then try to save to database
        const success = await addBookToFavorites(user.id, {
          title: book.title,
          author: book.author,
          genre: book.genre,
          description: book.description,
          amazon_link: book.amazonLink || '',
          cover_image_url: book.coverImageUrl || ''
        });
        console.log('🔍 addBookToFavorites result:', success);
        console.log('🔍 user.id:', user.id);
        console.log('🔍 book data being sent:', {
          title: book.title,
          author: book.author,
          genre: book.genre,
          description: book.description,
          amazon_link: book.amazonLink || '',
          cover_image_url: book.coverImageUrl || ''
        });
        
        if (!success) {
          console.warn('⚠️ Database save failed, removing from UI favorites');
          // Remove from UI if database save fails to maintain consistency
          setFavorites(prev => removeFavoriteByTitleAuthor(prev, book.title, book.author));
        }
      }
    } catch (error) {
      console.error('❌ Error toggling favorite:', error);
      // On error, revert the UI change to maintain consistency
      const isFavorited = favorites.some(fav => 
        fav.title.toLowerCase() === book.title.toLowerCase() && 
        fav.author.toLowerCase() === book.author.toLowerCase()
      );
      
      if (isFavorited) {
        // If it was favorited, remove it from UI since database operation failed
        setFavorites(prev => removeFavoriteByTitleAuthor(prev, book.title, book.author));
      } else {
        // If it wasn't favorited, add it back to UI since database operation failed
        const newFavorite: FavoriteBook = {
          id: Date.now().toString(),
          title: book.title,
          author: book.author,
          genre: book.genre,
          description: book.description,
          amazonLink: book.amazonLink || '',
          coverImageUrl: book.coverImageUrl || '',
          reason: book.reason || '',
          dateAdded: new Date().toISOString()
        };
        setFavorites(prev => [...prev, newFavorite]);
      }
    } finally {
      // Clear loading state for this book
      setFavoriteLoadingStates(prev => {
        const newSet = new Set(prev);
        newSet.delete(bookKey);
        return newSet;
      });
    }
  };

  const handleStartQuiz = () => {
    console.log('🔄 Starting/Restarting quiz - clearing all previous data');
    setCurrentPage('quiz');
    setCurrentQuestionIndex(0);
    setAnswers({});
    setBookAnswers({});
    // Clear existing personality profile to ensure fresh data
    setPersonalityProfile(null);
    // Clear existing recommendations
    setRecommendations([]);
    setAllRecommendedIds([]);
  };

  const handleResumeQuiz = () => {
    setCurrentPage('quiz');
  };

  const handleQuizComplete = async (profile: PersonalityProfile) => {
    console.log('🎯 Quiz completed - new profile calculated:', profile);
    setPersonalityProfile(profile);
    
    // Generate initial book recommendations
    const initialRecommendations = getBookRecommendationsWithExpandedMatching(profile, [], true, new Set());
    setRecommendations(initialRecommendations);
    setAllRecommendedIds(initialRecommendations.map(book => book.id));
    
    setCurrentPage('results');

    if (user) {
      try {
        console.log('💾 Saving new personality profile to database for user:', user.id);
        await saveUserPersonalityProfile(user.id, profile);
        console.log('✅ Personality profile successfully saved to database');
      } catch (error) {
        console.error('❌ Error saving personality profile:', error);
      }
    } else {
      console.log('ℹ️ User not authenticated - profile will be saved when they sign in');
    }
  };

  const handleGenerateNewBooks = () => {
    if (!personalityProfile) return;
    
    const excludeIds = [...allRecommendedIds];
    const favoritedBookSignatures = new Set(
      favorites.map(fav => `${fav.title.toLowerCase()}-${fav.author.toLowerCase()}`)
    );
    
    let newRecs = getBookRecommendationsWithExpandedMatching(personalityProfile, excludeIds, true, favoritedBookSignatures);
    
    const removedFavorites: string[] = [];
    newRecs = newRecs.filter(book => {
      const bookSignature = `${book.title.toLowerCase()}-${book.author.toLowerCase()}`;
      const isFavorited = favoritedBookSignatures.has(bookSignature);
      
      if (isFavorited) {
        removedFavorites.push(`${book.title} by ${book.author}`);
      }
      
      return !isFavorited;
    });
    
    if (removedFavorites.length > 0) {
      console.log(`🚨 ALERT: Removed ${removedFavorites.length} favorited books from recommendations:`, removedFavorites);
    }
    
    setRecommendations(newRecs);
    setAllRecommendedIds([...allRecommendedIds, ...newRecs.map(book => book.id)]);
    setCurrentPage('generated');
  };

  const handleNavigation = (page: string) => {
    if (page === 'celebrity-books') {
      setCelebrityNavigationCount(prev => prev + 1);
    }
    setCurrentPage(page as AppPage);
  };

  const handleLogout = async () => {
    try {
      console.log('Logout initiated, navigating to welcome page...');
      // Navigate to welcome page first
      setCurrentPage('welcome');
      // Then sign out
      await signOut();
    } catch (error) {
      console.error('Error signing out:', error);
      // Still navigate to welcome page even if signout fails
      setCurrentPage('welcome');
    }
  };

  // Manual refresh function for debugging
  const handleRefreshUserData = async () => {
    if (user && user.id) {
      console.log('Manual refresh triggered for user:', user.id);
      
      try {
        // Clear current data
        setFavorites([]);
        setPersonalityProfile(null);
        
        // Reload personality profile
        console.log('Manual refresh: Loading personality profile...');
        const profile = await getUserPersonalityProfile(user.id);
        if (profile) {
          console.log('Manual refresh: Personality profile loaded:', profile);
          setPersonalityProfile(profile);
        } else {
          console.log('Manual refresh: No personality profile found');
          setPersonalityProfile(null);
        }
        
        // Reload favorites
        console.log('Manual refresh: Loading favorites...');
        const dbFavorites = await getUserFavorites(user.id);
        console.log('Manual refresh: getUserFavorites returned:', dbFavorites);
        
        if (Array.isArray(dbFavorites) && dbFavorites.length > 0) {
          const formattedFavorites: FavoriteBook[] = dbFavorites.map((fav: any) => 
            normalizeFavoriteFromDatabase(fav)
          );
          console.log('Manual refresh: Formatted favorites:', formattedFavorites);
          setFavorites(formattedFavorites);
        } else {
          console.log('Manual refresh: No favorites found');
          setFavorites([]);
        }
      } catch (error) {
        console.error('Manual refresh error:', error);
        setFavorites([]);
        setPersonalityProfile(null);
      }
    } else {
      console.log('Manual refresh: No user available');
    }
  };

  // Show loading while authentication is initializing
  if (authLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-white mx-auto mb-4"></div>
          <p className="text-white text-lg">Loading...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900">
      <AuthModal
        isOpen={isAuthModalOpen}
        onClose={() => setIsAuthModalOpen(false)}
        initialMode={authModalMode}
      />
      <BurgerMenu
        onNavigate={handleNavigation}
        user={user}
        onLoginRequired={() => setIsAuthModalOpen(true)}
        onAuthPrompt={handleAuthPrompt}
        onLogout={handleLogout}
      />
      {currentPage === 'welcome' && (
        <>
          {console.log('Rendering WelcomePage with - isAuthenticated:', isAuthenticated, 'personalityProfile:', personalityProfile, 'hasCompletedQuiz:', !!personalityProfile)}
          <WelcomePage
            onStartQuiz={handleStartQuiz}
            onResumeQuiz={handleResumeQuiz}
            onLearnMore={() => setCurrentPage('learn-more')}
            hasQuizProgress={Object.keys(answers).length > 0 || Object.keys(bookAnswers).length > 0}
            isLoggedIn={isAuthenticated}
            hasCompletedQuiz={isAuthenticated ? !!personalityProfile : false}
            onGenerateNewBooks={handleGenerateNewBooks}
            onSignIn={() => handleAuthPrompt('login', 'access features')}
            onSignUp={() => handleAuthPrompt('signup', 'access features')}
            onAuthPrompt={handleAuthPrompt}
          />
        </>
      )}
      {currentPage === 'quiz' && (
        <QuizPage
          questions={questions}
          bookQuestions={bookQuestions}
          initialAnswers={answers}
          initialBookAnswers={bookAnswers}
          initialQuestionIndex={currentQuestionIndex}
          onComplete={(answers, bookAnswers) => {
            // Calculate personality profile from answers
            const profile = calculatePersonalityProfile(answers, bookAnswers);
            handleQuizComplete(profile);
          }}
          onProgress={(answers, bookAnswers, questionIndex) => {
            setAnswers(answers);
            setBookAnswers(bookAnswers);
            setCurrentQuestionIndex(questionIndex);
          }}
          onHome={() => setCurrentPage('welcome')}
        />
      )}
      {currentPage === 'results' && (
        <ResultsPage
          profile={personalityProfile!}
          recommendations={recommendations}
          onRetakeQuiz={handleStartQuiz}
          onHome={() => setCurrentPage('welcome')}
          favorites={favorites}
          onToggleFavorite={handleToggleFavorite}
          user={user}
          onLoginRequired={() => setIsAuthModalOpen(true)}
          onAuthPrompt={handleAuthPrompt}
        />
      )}
      {currentPage === 'generated' && (
        <GeneratedRecommendationsPage
          recommendations={recommendations}
          profile={personalityProfile!}
          onHome={() => setCurrentPage('welcome')}
          favorites={favorites}
          onToggleFavorite={handleToggleFavorite}
          user={user}
          onLoginRequired={() => setIsAuthModalOpen(true)}
        />
      )}
      {currentPage === 'celebrity-books' && (
        <CelebrityTesterPage
          key={celebrityNavigationCount}
          favorites={favorites}
          onToggleFavorite={handleToggleFavorite}
          user={user}
          onLoginRequired={() => setIsAuthModalOpen(true)}
          onBack={() => setCurrentPage('welcome')}
          hasCompletedQuiz={isAuthenticated ? !!personalityProfile : false}
          favoriteLoadingStates={favoriteLoadingStates}
        />
      )}
      {currentPage === 'trending-books' && (
        <TrendingBooksPage
          favorites={favorites}
          onToggleFavorite={handleToggleFavorite}
          user={user}
          onLoginRequired={() => setIsAuthModalOpen(true)}
          onBack={() => setCurrentPage('welcome')}
          hasCompletedQuiz={isAuthenticated ? !!personalityProfile : false}
        />
      )}
      {currentPage === 'trending-authors' && (
        <TrendingAuthorsPage
          onBack={() => setCurrentPage('welcome')}
          hasCompletedQuiz={isAuthenticated ? !!personalityProfile : false}
        />
      )}
      {currentPage === 'tailor-mates' && (
        <TailorMatesPage
          onBack={() => setCurrentPage('welcome')}
          hasCompletedQuiz={isAuthenticated ? !!personalityProfile : false}
          user={user}
        />
      )}
      {currentPage === 'favourites' && (
        <PlaceholderPage
          title="Favorites"
          description="Your favorite books will appear here."
          onBack={() => setCurrentPage('welcome')}
        />
      )}
      {currentPage === 'learn-more' && (
        <LearnMorePage
          onBack={() => setCurrentPage('welcome')}
          onStartQuiz={handleStartQuiz}
        />
      )}
      {currentPage === 'profile' && (
        <PlaceholderPage
          title="Profile"
          description="Your personality profile and reading history."
          onBack={() => setCurrentPage('welcome')}
          profile={personalityProfile}
          favorites={favorites}
          onRemoveFavorite={(bookId) => {
            const book = favorites.find(fav => fav.id === bookId);
            if (book) {
              handleToggleFavorite(book);
            }
          }}
          onLogout={handleLogout}
          onStartQuiz={handleStartQuiz}
          onNewRecommendations={(newRecommendations) => {
            setRecommendations(newRecommendations);
            setAllRecommendedIds(newRecommendations.map(book => book.id));
            setCurrentPage('generated');
          }}
        />
      )}
      {currentPage === 'book-cover-test' && (
        <PlaceholderPage
          title="Book Cover Test"
          description="Testing book cover loading performance."
          onBack={() => setCurrentPage('welcome')}
        />
      )}
    </div>
  );
}

export default App;