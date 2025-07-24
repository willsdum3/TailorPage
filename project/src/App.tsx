import React, { useState } from 'react';
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
import { Question, PersonalityProfile, LikertResponse, FavoriteBook, BookRecommendation, LoginCredentials, SignupData } from './types';
import { User } from './types';
import { getBookRecommendations } from './utils/bookRecommendations';
import GeneratedRecommendationsPage from './components/GeneratedRecommendationsPage';
import { useEffect } from 'react';

const questions: Question[] = [
  {
    id: 1,
    text: "I enjoy trying new activities and experiences.",
    trait: "openness"
  },
  {
    id: 2,
    text: "I have a vivid imagination.",
    trait: "openness"
  },
  {
    id: 3,
    text: "I enjoy reflecting on abstract ideas.",
    trait: "openness"
  },
  {
    id: 4,
    text: "I am curious about different cultures and lifestyles.",
    trait: "openness"
  },
  {
    id: 5,
    text: "I enjoy artistic or creative activities.",
    trait: "openness"
  },
  {
    id: 6,
    text: "I like to have a clear plan before starting anything.",
    trait: "conscientiousness"
  },
  {
    id: 7,
    text: "I pay attention to details.",
    trait: "conscientiousness"
  },
  {
    id: 8,
    text: "I follow through with my commitments.",
    trait: "conscientiousness"
  },
  {
    id: 9,
    text: "I rarely procrastinate.",
    trait: "conscientiousness"
  },
  {
    id: 10,
    text: "I keep my space and belongings organized.",
    trait: "conscientiousness"
  },
  {
    id: 11,
    text: "I enjoy being the centre of attention.",
    trait: "extraversion"
  },
  {
    id: 12,
    text: "I feel energized after social events.",
    trait: "extraversion"
  },
  {
    id: 13,
    text: "I start conversations easily.",
    trait: "extraversion"
  },
  {
    id: 14,
    text: "I prefer group activities to being alone.",
    trait: "extraversion"
  },
  {
    id: 15,
    text: "I am comfortable meeting new people.",
    trait: "extraversion"
  },
  {
    id: 16,
    text: "I try to see things from others' perspectives.",
    trait: "agreeableness"
  },
  {
    id: 17,
    text: "I avoid conflict when possible.",
    trait: "agreeableness"
  },
  {
    id: 18,
    text: "I trust others easily.",
    trait: "agreeableness"
  },
  {
    id: 19,
    text: "I feel compassion for those less fortunate.",
    trait: "agreeableness"
  },
  {
    id: 20,
    text: "I am generous with my time or resources.",
    trait: "agreeableness"
  },
  {
    id: 21,
    text: "I remain calm under pressure.",
    trait: "emotionalStability"
  },
  {
    id: 22,
    text: "I don't worry much about the future.",
    trait: "emotionalStability"
  },
  {
    id: 23,
    text: "I bounce back quickly after setbacks.",
    trait: "emotionalStability"
  },
  {
    id: 24,
    text: "I rarely feel overwhelmed.",
    trait: "emotionalStability"
  },
  {
    id: 25,
    text: "I don't dwell on mistakes.",
    trait: "emotionalStability"
  },
  {
    id: 26,
    text: "I rely on logic more than feelings when making decisions.",
    trait: "rationalThinking"
  },
  {
    id: 27,
    text: "I follow my instincts when facing a tough choice.",
    trait: "rationalThinking"
  },
  {
    id: 28,
    text: "I analyse situations thoroughly before acting.",
    trait: "rationalThinking"
  },
  {
    id: 29,
    text: "I seek multiple perspectives before deciding.",
    trait: "rationalThinking"
  },
  {
    id: 30,
    text: "I often question conventional wisdom.",
    trait: "rationalThinking"
  },
  {
    id: 31,
    text: "I strive for success and achievement.",
    trait: "coreValues"
  },
  {
    id: 32,
    text: "I prioritize helping others over personal gain.",
    trait: "coreValues"
  },
  {
    id: 33,
    text: "I value tradition and stability.",
    trait: "coreValues"
  },
  {
    id: 34,
    text: "I desire freedom and independence above all.",
    trait: "coreValues"
  },
  {
    id: 35,
    text: "I am driven by curiosity and learning.",
    trait: "coreValues"
  },
  {
    id: 36,
    text: "I want to make a meaningful impact on the world.",
    trait: "coreValues"
  },
  {
    id: 37,
    text: "I prefer predictability over risk-taking.",
    trait: "lifestyle"
  },
  {
    id: 38,
    text: "I enjoy taking leadership roles when possible.",
    trait: "lifestyle"
  },
  {
    id: 39,
    text: "I enjoy a fast-paced lifestyle.",
    trait: "lifestyle"
  },
  {
    id: 40,
    text: "I prefer quiet, calm environments.",
    trait: "lifestyle"
  },
  {
    id: 41,
    text: "I like to keep busy and have full schedules.",
    trait: "lifestyle"
  },
  {
    id: 42,
    text: "I find comfort in routines.",
    trait: "lifestyle"
  },
  {
    id: 43,
    text: "I enjoy spontaneous adventures.",
    trait: "lifestyle"
  },
  {
    id: 44,
    text: "I make decisions quickly and easily.",
    trait: "socialStyle"
  },
  {
    id: 45,
    text: "I get restless when things stay the same too long.",
    trait: "socialStyle"
  },
  {
    id: 46,
    text: "I adapt my behaviour to fit in with different groups.",
    trait: "socialStyle"
  },
  {
    id: 47,
    text: "I prefer deep one-on-one conversations to group chats.",
    trait: "socialStyle"
  },
  {
    id: 48,
    text: "I often reflect on how others perceive me.",
    trait: "selfExpression"
  },
  {
    id: 49,
    text: "I express my opinions even if they're unpopular.",
    trait: "selfExpression"
  },
  {
    id: 50,
    text: "I feel comfortable being vulnerable with people I trust.",
    trait: "selfExpression"
  }
];

type AppPage = 'welcome' | 'quiz' | 'results' | 'profile' | 'favourites' | 'trending-books' | 'trending-authors' | 'celebrity-books' | 'learn-more' | 'generated';

// No Supabase or external auth logic present

function App() {
  const [currentPage, setCurrentPage] = useState<AppPage>('welcome');
  const [answers, setAnswers] = useState<Record<number, LikertResponse>>({});
  const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);
  const [personalityProfile, setPersonalityProfile] = useState<PersonalityProfile | null>(null);
  const [favorites, setFavorites] = useState<FavoriteBook[]>([]);
  const [user, setUser] = useState<User | null>(null);
  const [isAuthModalOpen, setIsAuthModalOpen] = useState(false);
  const [recommendations, setRecommendations] = useState<BookRecommendation[]>([]);
  const [allRecommendedIds, setAllRecommendedIds] = useState<string[]>([]);

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
    // Simulate API call
    await new Promise(resolve => setTimeout(resolve, 1000));
    // Mock successful login
    const mockUser: User = {
      id: '1',
      name: 'John Doe',
      username: credentials.username,
      email: credentials.email
    };
    setUser(mockUser);
    setIsAuthModalOpen(false);
  };

  const handleSignup = async (data: SignupData) => {
    // Simulate API call
    await new Promise(resolve => setTimeout(resolve, 1000));
    // Mock successful signup
    const newUser: User = {
      id: Date.now().toString(),
      name: data.name,
      username: data.username,
      email: data.email
    };
    setUser(newUser);
    setIsAuthModalOpen(false);
  };

  const handleLogout = () => {
    setUser(null);
    // Optionally clear favorites and other user data
    setFavorites([]);
    setPersonalityProfile(null);
    setAnswers({});
    setCurrentPage('welcome');
  };

  const handleStartQuiz = () => {
    // If there are existing answers, resume from where they left off
    if (Object.keys(answers).length > 0) {
      const answeredQuestions = Object.keys(answers).map(Number);
      const lastAnsweredIndex = questions.findIndex(q => !answeredQuestions.includes(q.id));
      setCurrentQuestionIndex(lastAnsweredIndex === -1 ? questions.length - 1 : lastAnsweredIndex);
    } else {
      setCurrentQuestionIndex(0);
    }
    setCurrentPage('quiz');
  };

  const handleQuizComplete = (quizAnswers: Record<number, LikertResponse>) => {
    setAnswers(quizAnswers);
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

    questions.forEach(question => {
      const answer = quizAnswers[question.id];
      if (answer !== undefined) {
        // Convert Likert scale to score (1-5 scale, where 1 = Strongly Agree, 5 = Strongly Disagree)
        let score = 6 - answer; // Convert so agreement = higher score
        
        // Handle reverse-scored questions
        const reverseScored = [27, 37, 40, 42, 44, 46, 47, 48]; // Questions that need reverse scoring
        if (reverseScored.includes(question.id)) {
          score = answer; // Keep original score for reverse-scored items
        }
        
        profile[question.trait] += score;
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
    setCurrentQuestionIndex(0);
    setPersonalityProfile(null);
    setCurrentPage('quiz');
  };

  const handleQuizProgress = (updatedAnswers: Record<number, LikertResponse>, questionIndex: number) => {
    setAnswers(updatedAnswers);
    setCurrentQuestionIndex(questionIndex);
  };

  const handleHomeFromQuiz = () => {
    // Keep answers and current progress when going home
    setCurrentPage('welcome');
  };

  const handleHomeFromResults = () => {
    // Clear quiz progress when going home from results
    setAnswers({});
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
            initialAnswers={answers}
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
          <LearnMorePage onBack={() => setCurrentPage('welcome')} />
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
          <TrendingBooksPage onBack={() => setCurrentPage('welcome')} />
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
          <TrendingAuthorsPage onBack={() => setCurrentPage('welcome')} />
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
            <CelebrityTesterPage onBack={() => setCurrentPage('welcome')} />
          ) : (
            <PlaceholderPage
              {...getPlaceholderContent(currentPage)}
              onBack={() => setCurrentPage('welcome')}
              profile={personalityProfile}
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