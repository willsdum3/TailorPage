import React, { useState, useEffect } from 'react';
import { useUser, useClerk } from '@clerk/clerk-react';
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
import AuthModal from './components/AuthModal';
import AuthButton from './components/AuthButton';
import { Question, PersonalityProfile, LikertResponse, FavoriteBook, BookRecommendation, LoginCredentials, SignupData, BookQuestion, BookResponse } from './types';
import { User } from './types';
import { getBookRecommendations } from './utils/bookRecommendations';
import GeneratedRecommendationsPage from './components/GeneratedRecommendationsPage';
import { useScrollToTopInstant } from './hooks/useScrollToTop';

// Book questions for the quiz
const bookQuestions: BookQuestion[] = [
  {
    id: 101,
    title: "Invisible Cities",
    author: "Italo Calvino",
    description: "An experimental, poetic work in which Marco Polo describes fantastical cities to Kublai Khan.",
    trait: "openness"
  },
  {
    id: 102,
    title: "Man's Search for Meaning",
    author: "Viktor E. Frankl",
    description: "A powerful memoir and philosophical reflection on purpose, responsibility, and resilience in the face of suffering.",
    trait: "conscientiousness"
  },
  {
    id: 103,
    title: "Where the Crawdads Sing",
    author: "Delia Owens",
    description: "It includes themes of solitude, it offers rich emotional relationships, courtroom drama, and a strong female lead.",
    trait: "extraversion"
  },
  {
    id: 104,
    title: "Wonder",
    author: "R.J. Palacio",
    description: "A moving middle-grade novel about a boy with a facial difference navigating school and relationships.",
    trait: "agreeableness"
  },
  {
    id: 105,
    title: "Stillness Is the Key",
    author: "Ryan Holiday",
    description: "A modern take on ancient wisdom promoting inner calm, clarity, and balance in a busy world.",
    trait: "emotionalStability"
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

type AppPage = 'welcome' | 'quiz' | 'results' | 'profile' | 'favourites' | 'trending-books' | 'trending-authors' | 'celebrity-books' | 'learn-more' | 'generated';

// No Supabase or external auth logic present

function App() {
  const { user: clerkUser, isLoaded } = useUser();
  const { signOut } = useClerk();
  const [currentPage, setCurrentPage] = useState<AppPage>('welcome');
  const [answers, setAnswers] = useState<Record<number, LikertResponse>>({});
  const [bookAnswers, setBookAnswers] = useState<Record<number, BookResponse>>({});
  const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);
  const [personalityProfile, setPersonalityProfile] = useState<PersonalityProfile | null>(null);
  const [favorites, setFavorites] = useState<FavoriteBook[]>([]);
  const [isAuthModalOpen, setIsAuthModalOpen] = useState(false);
  const [recommendations, setRecommendations] = useState<BookRecommendation[]>([]);
  const [allRecommendedIds, setAllRecommendedIds] = useState<string[]>([]);

  // Scroll to top when page changes
  useScrollToTopInstant([currentPage]);

  // Convert Clerk user to our User type
  const user: User | null = clerkUser ? {
    id: clerkUser.id,
    name: clerkUser.fullName || clerkUser.firstName || clerkUser.username || 'User',
    username: clerkUser.username || clerkUser.emailAddresses[0]?.emailAddress?.split('@')[0] || 'user',
    email: clerkUser.emailAddresses[0]?.emailAddress || ''
  } : null;

  // Close auth modal when user becomes authenticated
  useEffect(() => {
    if (isLoaded && clerkUser && isAuthModalOpen) {
      setIsAuthModalOpen(false);
    }
  }, [isLoaded, clerkUser, isAuthModalOpen]);

  const handleToggleFavorite = (book: BookRecommendation) => {
    // Only allow favoriting books that are in the current recommendations
    const isRecommended = recommendations.some(rec => rec.id === book.id);
    if (!isRecommended) {
      alert("You can only favorite books from your current recommendations.");
      return;
    }
    const isAlreadyFavorited = favorites.some(fav => fav.id === book.id);
    
    if (isAlreadyFavorited) {
      setFavorites(favorites.filter(fav => fav.id !== book.id));
    } else {
      const favoriteBook: FavoriteBook = {
        ...book,
        dateAdded: new Date().toISOString()
      };
      setFavorites([...favorites, favoriteBook]);
    }
  };

  const handleRemoveFavorite = (bookId: string) => {
    setFavorites(favorites.filter(fav => fav.id !== bookId));
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

  const handleQuizComplete = (quizAnswers: Record<number, LikertResponse>, quizBookAnswers: Record<number, BookResponse>) => {
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
    if (page === 'home') {
      setCurrentPage('welcome');
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
      <BurgerMenu 
        onNavigate={handleNavigation} 
        user={user}
        onLoginRequired={() => setIsAuthModalOpen(true)}
      />
      
      <AuthModal
        isOpen={isAuthModalOpen}
        onClose={() => setIsAuthModalOpen(false)}
        onLogin={handleLogin}
        onSignup={handleSignup}
      />
      
      {currentPage === 'welcome' && (
        <>
          <AuthButton 
            user={user}
            onLogin={() => setIsAuthModalOpen(true)}
            onLogout={handleLogout}
            position="top-center"
          />
          <WelcomePage
            onStartQuiz={handleStartQuiz}
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
          <AuthButton 
            user={user}
            onLogin={() => setIsAuthModalOpen(true)}
            onLogout={handleLogout}
            position="top-right"
          />
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
          <AuthButton 
            user={user}
            onLogin={() => setIsAuthModalOpen(true)}
            onLogout={handleLogout}
            position="top-right"
          />
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
          <AuthButton 
            user={user}
            onLogin={() => setIsAuthModalOpen(true)}
            onLogout={handleLogout}
            position="top-left"
          />
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
          <AuthButton 
            user={user}
            onLogin={() => setIsAuthModalOpen(true)}
            onLogout={handleLogout}
            position="top-left"
          />
          <LearnMorePage onBack={() => setCurrentPage('welcome')} onStartQuiz={handleStartQuiz} />
        </>
      )}
      {currentPage === 'trending-books' && (
        <>
          <AuthButton 
            user={user}
            onLogin={() => setIsAuthModalOpen(true)}
            onLogout={handleLogout}
            position="top-left"
          />
          <TrendingBooksPage onBack={() => setCurrentPage('welcome')} hasCompletedQuiz={!!personalityProfile} onStartQuiz={handleStartQuiz} />
        </>
      )}
      {currentPage === 'trending-authors' && (
        <>
          <AuthButton 
            user={user}
            onLogin={() => setIsAuthModalOpen(true)}
            onLogout={handleLogout}
            position="top-left"
          />
          <TrendingAuthorsPage onBack={() => setCurrentPage('welcome')} hasCompletedQuiz={!!personalityProfile} onStartQuiz={handleStartQuiz} />
        </>
      )}
      {['profile', 'celebrity-books'].includes(currentPage) && (
        <>
          <AuthButton 
            user={user}
            onLogin={() => setIsAuthModalOpen(true)}
            onLogout={handleLogout}
            position="top-left"
          />
          {currentPage === 'celebrity-books' ? (
            <CelebrityTesterPage onBack={() => setCurrentPage('welcome')} hasCompletedQuiz={!!personalityProfile} onStartQuiz={handleStartQuiz} />
          ) : (
            <PlaceholderPage
              {...getPlaceholderContent(currentPage)}
              onBack={() => setCurrentPage('welcome')}
              profile={personalityProfile}
              onStartQuiz={handleStartQuiz}
              onNewRecommendations={handleNewRecommendations}
            />
          )}
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
    </div>
  );
}

export default App;