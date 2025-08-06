import React, { useState, useEffect } from 'react';
import { useUser, useClerk } from '@clerk/clerk-react';
import IntroPage from './components/IntroPage';
import WelcomePage from './components/WelcomePage';
import QuizPage from './components/QuizPage';
import ResultsPage from './components/ResultsPage';
import BurgerMenu from './components/BurgerMenu';
import FavoritesPage from './components/FavoritesPage';
import PlaceholderPage from './components/PlaceholderPage';
import LearnMorePage from './components/LearnMorePage';
import TrendingBooksPage from './components/TrendingBooksPage';
import TrendingAuthorsPage from './components/TrendingAuthorsPage';
import CelebrityTesterPage from './components/CelebrityTesterPage';
import TailorMatesPage from './components/TailorMatesPage';
import AuthModal from './components/AuthModal';
import AuthButton from './components/AuthButton';
import { Question, PersonalityProfile, LikertResponse, FavoriteBook, BookRecommendation, LoginCredentials, SignupData, BookQuestion, BookResponse } from './types';
import { User } from './types';
import { getBookRecommendations } from './utils/bookRecommendations';
import GeneratedRecommendationsPage from './components/GeneratedRecommendationsPage';
import { useScrollToTopInstant } from './hooks/useScrollToTop';
import { useUserSync } from './hooks/useUserSync';
import { saveUserPersonalityProfile, getUserPersonalityProfile, addBookToFavorites, removeBookFromFavorites, getUserFavorites } from './lib/supabase';
import { clearBookCoverFromCache } from './utils/bookCoverService';

// Book questions for the quiz
const bookQuestions: BookQuestion[] = [
  {
    id: 101,
    title: "Invisible Cities",
    author: "Italo Calvino",
    description: "An experimental, poetic work in which Marco Polo describes fantastical cities to Kublai Khan.",
    trait: "openness",
    coverImageUrl: "/book-covers/InvisibleCities.jpg"
  },
  {
    id: 102,
    title: "Man's Search for Meaning",
    author: "Viktor E. Frankl",
    description: "A powerful memoir and philosophical reflection on purpose, responsibility, and resilience in the face of suffering.",
    trait: "conscientiousness",
    coverImageUrl: "/book-covers/MansSearchForMeaning.jpg"
  },
  {
    id: 103,
    title: "Where the Crawdads Sing",
    author: "Delia Owens",
    description: "It includes themes of solitude, it offers rich emotional relationships, courtroom drama, and a strong female lead.",
    trait: "extraversion",
    coverImageUrl: "/book-covers/WhereTheCrawdadsSing.jpg"
  },
  {
    id: 104,
    title: "Wonder",
    author: "R.J. Palacio",
    description: "A moving middle-grade novel about a boy with a facial difference navigating school and relationships.",
    trait: "agreeableness",
    coverImageUrl: "/book-covers/Wonder.jpg"
  },
  {
    id: 105,
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
    id: 101,
    text: "Does this sort of book interest you?",
    trait: "openness",
    type: "book"
  },
  {
    id: 6,
    text: "I enjoy being the center of attention.",
    trait: "extraversion",
    type: "statement"
  },
  {
    id: 7,
    text: "I pay close attention to detail.",
    trait: "conscientiousness",
    type: "statement"
  },
  {
    id: 8,
    text: "I experience frequent mood swings.",
    trait: "emotionalStability",
    type: "statement"
  },
  {
    id: 9,
    text: "I prefer variety over routine.",
    trait: "openness",
    type: "statement"
  },
  {
    id: 10,
    text: "I sympathize with people who are struggling.",
    trait: "agreeableness",
    type: "statement"
  },
  // Book question after 10 statements
  {
    id: 102,
    text: "Does this sort of book interest you?",
    trait: "conscientiousness",
    type: "book"
  },
  {
    id: 11,
    text: "I often feel anxious or tense.",
    trait: "emotionalStability",
    type: "statement"
  },
  {
    id: 12,
    text: "I finish tasks successfully.",
    trait: "conscientiousness",
    type: "statement"
  },
  {
    id: 13,
    text: "I am curious about many different topics.",
    trait: "openness",
    type: "statement"
  },
  {
    id: 14,
    text: "I make people feel comfortable and valued.",
    trait: "agreeableness",
    type: "statement"
  },
  {
    id: 15,
    text: "I worry about things.",
    trait: "emotionalStability",
    type: "statement"
  },
  // Book question after 15 statements
  {
    id: 103,
    text: "Does this sort of book interest you?",
    trait: "extraversion",
    type: "book"
  },
  {
    id: 16,
    text: "I have a vivid imagination.",
    trait: "openness",
    type: "statement"
  },
  {
    id: 17,
    text: "I am enthusiastic and full of energy.",
    trait: "extraversion",
    type: "statement"
  },
  {
    id: 18,
    text: "I am always prepared.",
    trait: "conscientiousness",
    type: "statement"
  },
  {
    id: 19,
    text: "I am outgoing and sociable.",
    trait: "extraversion",
    type: "statement"
  },
  {
    id: 20,
    text: "I enjoy thinking about abstract concepts.",
    trait: "openness",
    type: "statement"
  },
  // Book question after 20 statements
  {
    id: 104,
    text: "Does this sort of book interest you?",
    trait: "agreeableness",
    type: "book"
  },
  {
    id: 21,
    text: "I am cooperative and avoid conflict.",
    trait: "agreeableness",
    type: "statement"
  },
  {
    id: 22,
    text: "I start conversations easily.",
    trait: "extraversion",
    type: "statement"
  },
  {
    id: 23,
    text: "I am reliable and dependable.",
    trait: "conscientiousness",
    type: "statement"
  },
  {
    id: 24,
    text: "I feel energized by being around people.",
    trait: "extraversion",
    type: "statement"
  },
  {
    id: 25,
    text: "I get stressed out easily.",
    trait: "emotionalStability",
    type: "statement"
  },
  // Final book question after 25 statements
  {
    id: 105,
    text: "Does this sort of book interest you?",
    trait: "emotionalStability",
    type: "book"
  }
];

type AppPage = 'intro' | 'welcome' | 'quiz' | 'results' | 'profile' | 'favourites' | 'trending-books' | 'trending-authors' | 'celebrity-books' | 'learn-more' | 'generated' | 'tailor-mates';

// No Supabase or external auth logic present

function App() {
  // Use user sync hook to automatically sync Clerk user to Supabase
  const { user: clerkUser, isLoaded } = useUserSync();
  const { signOut } = useClerk();
  const [currentPage, setCurrentPage] = useState<AppPage>('intro');
  const [answers, setAnswers] = useState<Record<number, LikertResponse>>({});
  const [bookAnswers, setBookAnswers] = useState<Record<number, BookResponse>>({});
  const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);
  const [personalityProfile, setPersonalityProfile] = useState<PersonalityProfile | null>(null);
  const [favorites, setFavorites] = useState<FavoriteBook[]>([]);
  const [isAuthModalOpen, setIsAuthModalOpen] = useState(false);
  const [authModalMode, setAuthModalMode] = useState<'login' | 'signup'>('login');
  const [recommendations, setRecommendations] = useState<BookRecommendation[]>([]);
  const [allRecommendedIds, setAllRecommendedIds] = useState<string[]>([]);

  // Scroll to top when page changes
  useScrollToTopInstant([currentPage]);

  // Convert Clerk user to our User type
  const user: User | null = clerkUser ? {
    id: clerkUser.id,
    name: clerkUser.fullName || clerkUser.firstName || clerkUser.username || 'User',
    username: clerkUser.username || clerkUser.emailAddresses[0]?.emailAddress?.split('@')[0] || 'user',
    email: clerkUser.emailAddresses[0]?.emailAddress || '',
    imageUrl: clerkUser.imageUrl || undefined
  } : null;

  // Close auth modal when user becomes authenticated and redirect to welcome
  useEffect(() => {
    if (isLoaded && clerkUser && isAuthModalOpen) {
      setIsAuthModalOpen(false);
      setCurrentPage('welcome');
    }
  }, [isLoaded, clerkUser, isAuthModalOpen]);

  // Ensure currentPage is set to welcome when user becomes authenticated
  useEffect(() => {
    if (isLoaded && clerkUser && currentPage === 'intro') {
      setCurrentPage('welcome');
    }
  }, [isLoaded, clerkUser, currentPage]);

  // Load user data from database when user is authenticated
  useEffect(() => {
    console.log('loadUserData useEffect triggered, user:', user);
    
    if (user) {
      console.log('Loading user data for user:', user.id);
      
      const loadUserData = async () => {
        try {
          // Load personality profile
          console.log('Loading personality profile...');
          const profile = await getUserPersonalityProfile(user.id);
          if (profile) {
            console.log('Personality profile loaded:', profile);
            setPersonalityProfile(profile);
          } else {
            console.log('No personality profile found for user');
          }
          
          // Load favorites
          console.log('Loading favorites...');
          const dbFavorites = await getUserFavorites(user.id);
          console.log('getUserFavorites returned:', dbFavorites);
          
          const formattedFavorites: FavoriteBook[] = dbFavorites.map((fav: any) => ({
            id: fav.book_id,
            title: fav.title,
            author: fav.author,
            genre: fav.genre,
            description: fav.description,
            amazonLink: fav.amazon_link,
            coverImageUrl: fav.cover_image_url,
            dateAdded: fav.date_added
          }));
          console.log('Formatted favorites:', formattedFavorites);
          setFavorites(formattedFavorites);
        } catch (error) {
          console.error('Error loading user data:', error);
          // Don't reset data if database fails - keep local state
        }
      };
      
      loadUserData();
    } else {
      console.log('No user, clearing user data');
      // Clear user data when user logs out
      setFavorites([]);
      setPersonalityProfile(null);
    }
  }, [user]); // Trigger on any user change

  // Handle intro page navigation
  const handleIntroLogin = () => {
    setAuthModalMode('login');
    setIsAuthModalOpen(true);
  };

  const handleIntroSignup = () => {
    setAuthModalMode('signup');
    setIsAuthModalOpen(true);
  };

  const handleToggleFavorite = async (book: BookRecommendation) => {
    console.log('handleToggleFavorite called with book:', book);
    console.log('Current user:', user);
    
    if (!user) {
      console.log('No user found, returning early');
      return;
    }
    
    // Check if book is already favorited by comparing title and author
    const isAlreadyFavorited = favorites.some(fav => 
      fav.title.toLowerCase() === book.title.toLowerCase() && 
      fav.author.toLowerCase() === book.author.toLowerCase()
    );
    console.log('Is already favorited:', isAlreadyFavorited);
    
    // Update UI immediately for better user experience
    if (isAlreadyFavorited) {
      // Remove from favorites immediately
      setFavorites(prev => prev.filter(fav => 
        !(fav.title.toLowerCase() === book.title.toLowerCase() && 
          fav.author.toLowerCase() === book.author.toLowerCase())
      ));
      console.log('Book removed from favorites (UI updated)');
    } else {
      // Add to favorites immediately
      const favoriteBook: FavoriteBook = {
        ...book,
        dateAdded: new Date().toISOString()
      };
      setFavorites(prev => [...prev, favoriteBook]);
      console.log('Book added to favorites (UI updated)');
      
      // Clear the book cover cache for this book to ensure fresh cover
      clearBookCoverFromCache(book.id, book.title, book.author);
    }
    
    // Then try to sync with database in the background
    try {
      console.log('Starting database sync...');
      if (isAlreadyFavorited) {
        console.log('Removing from database...');
        const success = await removeBookFromFavorites(user.id, book.title, book.author);
        console.log('Database remove result:', success);
      } else {
        console.log('Adding to database...');
        const result = await addBookToFavorites(user.id, {
          title: book.title,
          author: book.author,
          genre: book.genre,
          description: book.description,
          amazon_link: book.amazonLink,
          cover_image_url: book.coverImageUrl
        });
        console.log('Database add result:', result);
      }
    } catch (error) {
      console.error('Error syncing with database:', error);
      // Don't show alert to user since UI already updated
    }
  };

  const handleRemoveFavorite = async (bookId: string) => {
    if (!user) return;
    
    const favorite = favorites.find(fav => fav.id === bookId);
    if (!favorite) return;

    // Update UI immediately for better user experience
    setFavorites(prev => prev.filter(fav => fav.id !== bookId));

    // Clear the book cover cache for this book to prevent stale covers
    clearBookCoverFromCache(bookId, favorite.title, favorite.author);

    try {
      const success = await removeBookFromFavorites(user.id, favorite.title, favorite.author);
      if (!success) {
        // If database removal failed, revert the UI change
        setFavorites(prev => [...prev, favorite]);
        alert('Failed to remove favorite. Please try again.');
      }
    } catch (error) {
      console.error('Error removing favorite:', error);
      // Revert the UI change if there was an error
      setFavorites(prev => [...prev, favorite]);
      alert('Failed to remove favorite. Please try again.');
    }
  };

  const handleLogin = async (credentials: LoginCredentials) => {
    // This would integrate with your auth system
    console.log('Login attempt:', credentials);
  };

  const handleSignup = async (data: SignupData) => {
    // This would integrate with your auth system
    console.log('Signup attempt:', data);
  };

  const handleLogout = async () => {
    try {
      await signOut();
    } catch (error) {
      console.error('Error signing out:', error);
    }
  };

  const handleStartQuiz = () => {
    setAnswers({});
    setBookAnswers({});
    setCurrentQuestionIndex(0);
    setPersonalityProfile(null);
    setCurrentPage('quiz');
  };

  const handleResumeQuiz = () => {
    // Don't reset answers, bookAnswers, or currentQuestionIndex
    // Just navigate back to the quiz page
    setCurrentPage('quiz');
  };

  const handleQuizComplete = async (quizAnswers: Record<number, LikertResponse>, quizBookAnswers: Record<number, BookResponse>) => {
    setAnswers(quizAnswers);
    setBookAnswers(quizBookAnswers);
    setCurrentQuestionIndex(0); // Reset for next time
    
    // Calculate personality profile
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

    // Process regular statement questions
    questions.filter(q => q.type === 'statement').forEach(question => {
      const answer = quizAnswers[question.id];
      if (answer !== undefined) {
        // Convert Likert scale to score (1-5 scale, where 1 = Strongly Agree, 5 = Strongly Disagree)
        let score = 6 - answer; // Convert so agreement = higher score
        
        // Handle reverse-scored questions for emotional stability (negative items)
        const reverseScored = [3, 8, 11, 15, 25]; // Questions that need reverse scoring
        if (reverseScored.includes(question.id)) {
          score = answer; // Keep original score for reverse-scored items
        }
        
        profile[question.trait] += score;
      }
    });

    // Process book questions - add 1 point for each "yes" answer
    questions.filter(q => q.type === 'book').forEach(question => {
      const answer = quizBookAnswers[question.id];
      if (answer === 'yes') {
        profile[question.trait] += 1;
      }
    });

    setPersonalityProfile(profile);

    // Save personality profile to database
    if (user) {
      try {
        await saveUserPersonalityProfile(user.id, profile);
        console.log('Personality profile saved successfully');
      } catch (error) {
        console.error('Error saving personality profile:', error);
      }
    }

    // Generate and store recommendations ONCE per quiz completion
    const recs = getBookRecommendations(profile);
    setRecommendations(recs);
    setAllRecommendedIds(recs.map(book => book.id));
    setCurrentPage('results');
  };

  const handleRetakeQuiz = () => {
    setAnswers({});
    setBookAnswers({});
    setCurrentQuestionIndex(0);
    setPersonalityProfile(null);
    setCurrentPage('quiz');
  };

  const handleQuizProgress = (updatedAnswers: Record<number, LikertResponse>, updatedBookAnswers: Record<number, BookResponse>, questionIndex: number) => {
    setAnswers(updatedAnswers);
    setBookAnswers(updatedBookAnswers);
    setCurrentQuestionIndex(questionIndex);
  };

  const handleHomeFromQuiz = () => {
    // Keep answers and current progress when going home
    setCurrentPage('welcome');
  };

  const handleHomeFromResults = () => {
    // Clear quiz progress when going home from results
    setAnswers({});
    setBookAnswers({});
    setCurrentQuestionIndex(0);
    setCurrentPage('welcome');
  };

  const handleNewRecommendations = () => {
    // Generate new recommendations, excluding all previously recommended book IDs
    if (!personalityProfile) return;
    const newRecs = getBookRecommendations(personalityProfile, allRecommendedIds);
    setRecommendations(newRecs);
    setAllRecommendedIds([...allRecommendedIds, ...newRecs.map(book => book.id)]);
    setCurrentPage('generated');
  };

  const handleNavigation = (page: string) => {
    console.log('App navigation handler received:', page); // Debug log
    if (page === 'home') {
      setCurrentPage('welcome');
    } else if (page === 'favourites' && user) {
      // Load favorites when navigating to favorites page
      console.log('Navigating to favorites, loading favorites for user:', user.id);
      const loadFavorites = async () => {
        try {
          const dbFavorites = await getUserFavorites(user.id);
          const formattedFavorites: FavoriteBook[] = dbFavorites.map((fav: any) => ({
            id: fav.book_id,
            title: fav.title,
            author: fav.author,
            genre: fav.genre,
            description: fav.description,
            amazonLink: fav.amazon_link,
            coverImageUrl: fav.cover_image_url,
            dateAdded: fav.date_added
          }));
          setFavorites(formattedFavorites);
          console.log('Favorites loaded from database:', formattedFavorites);
        } catch (error) {
          console.error('Error loading favorites on navigation:', error);
        }
      };
      loadFavorites();
      setCurrentPage(page as AppPage);
    } else {
      // Clear quiz progress when navigating to any page other than quiz or results
      setAnswers({});
      setBookAnswers({});
      setCurrentQuestionIndex(0);
      setCurrentPage(page as AppPage);
    }
  };

  const getPlaceholderContent = (page: AppPage) => {
    switch (page) {
      case 'profile':
        return {
          title: 'Profile',
          description: 'Manage your reading preferences and personality insights'
        };
      case 'favourites':
        return {
          title: 'Favourites',
          description: 'Your saved books and personalized reading list'
        };
      case 'trending-books':
        return {
          title: 'Trending Books',
          description: 'Discover what everyone is reading right now'
        };
      case 'trending-authors':
        return {
          title: 'Trending Authors',
          description: 'Explore popular authors and their latest works'
        };
      case 'celebrity-books':
        return {
          title: 'Celebrity Tester',
          description: 'Test your knowledge about celebrities and their reading preferences'
        };
      default:
        return {
          title: 'Page',
          description: 'This page is under construction'
        };
    }
  };

  // Show loading while Clerk is initializing
  if (!isLoaded) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900 flex items-center justify-center">
        <div className="text-center">
          <div className="w-16 h-16 border-4 border-white/20 border-t-white rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-white/80 text-lg">Loading...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900">
      {/* AuthModal - available for both authenticated and unauthenticated users */}
      <AuthModal
        isOpen={isAuthModalOpen}
        onClose={() => setIsAuthModalOpen(false)}
        onLogin={handleLogin}
        onSignup={handleSignup}
        initialMode={authModalMode}
      />
      
      {/* Show IntroPage if user is not authenticated */}
      {!user ? (
        <IntroPage
          onLogin={handleIntroLogin}
          onSignup={handleIntroSignup}
        />
      ) : (
        <>
          <BurgerMenu 
            onNavigate={handleNavigation} 
            user={user}
            onLoginRequired={() => setIsAuthModalOpen(true)}
          />
          
          {currentPage === 'welcome' && (
            <>
              <WelcomePage
                onStartQuiz={handleStartQuiz}
                onResumeQuiz={handleResumeQuiz}
                hasQuizProgress={Object.keys(answers).length > 0}
                onLearnMore={() => setCurrentPage('learn-more')}
                isLoggedIn={!!user}
                hasCompletedQuiz={!!personalityProfile}
                onGenerateNewBooks={() => {
                  if (!personalityProfile) return;
                  const newRecs = getBookRecommendations(personalityProfile, allRecommendedIds);
                  setRecommendations(newRecs);
                  setAllRecommendedIds([...allRecommendedIds, ...newRecs.map(book => book.id)]);
                  setCurrentPage('generated');
                }}
              />
            </>
          )}
          {currentPage === 'quiz' && (
            <>
              <QuizPage 
                questions={questions} 
                bookQuestions={bookQuestions}
                initialAnswers={answers}
                initialBookAnswers={bookAnswers}
                initialQuestionIndex={currentQuestionIndex}
                onComplete={handleQuizComplete}
                onProgress={handleQuizProgress}
                onHome={handleHomeFromQuiz}
              />
            </>
          )}
          {currentPage === 'results' && personalityProfile && (
            <>
              <ResultsPage 
                profile={personalityProfile}
                recommendations={recommendations}
                onRetakeQuiz={handleRetakeQuiz}
                onHome={handleHomeFromResults}
                favorites={favorites}
                onToggleFavorite={handleToggleFavorite}
                user={user}
                onLoginRequired={() => setIsAuthModalOpen(true)}
              />
            </>
          )}
          {currentPage === 'favourites' && (
            <>
              <FavoritesPage
                favorites={favorites}
                onRemoveFavorite={handleRemoveFavorite}
                onBack={() => setCurrentPage('welcome')}
                hasCompletedQuiz={!!personalityProfile}
                onStartQuiz={handleStartQuiz}
                onGenerateNewBooks={() => {
                  if (!personalityProfile) return;
                  const newRecs = getBookRecommendations(personalityProfile, allRecommendedIds);
                  setRecommendations(newRecs);
                  setAllRecommendedIds([...allRecommendedIds, ...newRecs.map(book => book.id)]);
                  setCurrentPage('generated');
                }}
              />
            </>
          )}
          {currentPage === 'learn-more' && (
            <>
              <LearnMorePage onBack={() => setCurrentPage('welcome')} onStartQuiz={handleStartQuiz} />
            </>
          )}
          {currentPage === 'trending-books' && (
            <>
              <TrendingBooksPage onBack={() => setCurrentPage('welcome')} hasCompletedQuiz={!!personalityProfile} onStartQuiz={handleStartQuiz} />
            </>
          )}
          {currentPage === 'trending-authors' && (
            <>
              <TrendingAuthorsPage onBack={() => setCurrentPage('welcome')} hasCompletedQuiz={!!personalityProfile} onStartQuiz={handleStartQuiz} />
            </>
          )}
          {currentPage === 'tailor-mates' && (
            <>
              <TailorMatesPage onBack={() => setCurrentPage('welcome')} hasCompletedQuiz={!!personalityProfile} onStartQuiz={handleStartQuiz} />
            </>
          )}
          {currentPage === 'celebrity-books' && (
            <>
              <CelebrityTesterPage onBack={() => setCurrentPage('welcome')} hasCompletedQuiz={!!personalityProfile} onStartQuiz={handleStartQuiz} />
            </>
          )}
          {currentPage === 'profile' && (
            <>
              <AuthButton 
                user={user}
                onLogin={() => setIsAuthModalOpen(true)}
                position="top-left"
              />
              <PlaceholderPage
                {...getPlaceholderContent(currentPage)}
                onBack={() => setCurrentPage('welcome')}
                profile={personalityProfile}
                onStartQuiz={handleStartQuiz}
                onNewRecommendations={handleNewRecommendations}
                onNavigate={handleNavigation}
                favorites={favorites}
                onRemoveFavorite={handleRemoveFavorite}
                onLogout={handleLogout}
              />
            </>
          )}
          {currentPage === 'generated' && personalityProfile && (
            <GeneratedRecommendationsPage
              profile={personalityProfile}
              recommendations={recommendations}
              onBack={() => setCurrentPage('profile')}
              onHome={() => setCurrentPage('welcome')}
              favorites={favorites}
              onToggleFavorite={handleToggleFavorite}
              user={user}
              onLoginRequired={() => setIsAuthModalOpen(true)}
            />
          )}
        </>
      )}
    </div>
  );
}

export default App;