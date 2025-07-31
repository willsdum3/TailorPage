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
import { Question, PersonalityProfile, LikertResponse, FavoriteBook, BookRecommendation } from './types';
import { getBookRecommendations } from './utils/bookRecommendations';
import GeneratedRecommendationsPage from './components/GeneratedRecommendationsPage';
import { useEffect } from 'react';
import { useScrollToTopInstant } from './hooks/useScrollToTop';

const questions: Question[] = [
  {
    id: 1,
    text: "I forgive others easily.",
    trait: "agreeableness"
  },
  {
    id: 2,
    text: "I enjoy trying new and different things.",
    trait: "openness"
  },
  {
    id: 3,
    text: "I get upset or irritated quickly.",
    trait: "emotionalStability"
  },
  {
    id: 4,
    text: "I follow through with my plans.",
    trait: "conscientiousness"
  },
  {
    id: 5,
    text: "I am interested in the well-being of others.",
    trait: "agreeableness"
  },
  {
    id: 6,
    text: "I enjoy being the center of attention.",
    trait: "extraversion"
  },
  {
    id: 7,
    text: "I pay close attention to detail.",
    trait: "conscientiousness"
  },
  {
    id: 8,
    text: "I experience frequent mood swings.",
    trait: "emotionalStability"
  },
  {
    id: 9,
    text: "I prefer variety over routine.",
    trait: "openness"
  },
  {
    id: 10,
    text: "I sympathize with people who are struggling.",
    trait: "agreeableness"
  },
  {
    id: 11,
    text: "I often feel anxious or tense.",
    trait: "emotionalStability"
  },
  {
    id: 12,
    text: "I finish tasks successfully.",
    trait: "conscientiousness"
  },
  {
    id: 13,
    text: "I am curious about many different topics.",
    trait: "openness"
  },
  {
    id: 14,
    text: "I make people feel comfortable and valued.",
    trait: "agreeableness"
  },
  {
    id: 15,
    text: "I worry about things.",
    trait: "emotionalStability"
  },
  {
    id: 16,
    text: "I have a vivid imagination.",
    trait: "openness"
  },
  {
    id: 17,
    text: "I am enthusiastic and full of energy.",
    trait: "extraversion"
  },
  {
    id: 18,
    text: "I am always prepared.",
    trait: "conscientiousness"
  },
  {
    id: 19,
    text: "I am outgoing and sociable.",
    trait: "extraversion"
  },
  {
    id: 20,
    text: "I enjoy thinking about abstract concepts.",
    trait: "openness"
  },
  {
    id: 21,
    text: "I am cooperative and avoid conflict.",
    trait: "agreeableness"
  },
  {
    id: 22,
    text: "I start conversations easily.",
    trait: "extraversion"
  },
  {
    id: 23,
    text: "I am reliable and dependable.",
    trait: "conscientiousness"
  },
  {
    id: 24,
    text: "I feel energized by being around people.",
    trait: "extraversion"
  },
  {
    id: 25,
    text: "I get stressed out easily.",
    trait: "emotionalStability"
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
  const [recommendations, setRecommendations] = useState<BookRecommendation[]>([]);
  const [allRecommendedIds, setAllRecommendedIds] = useState<string[]>([]);

  // Scroll to top when page changes
  useScrollToTopInstant([currentPage]);

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
        
        // Handle reverse-scored questions for emotional stability (negative items)
        const reverseScored = [3, 8, 11, 15, 25]; // Questions that need reverse scoring
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
        user={null}
        onLoginRequired={() => {}}
      />
      
      {currentPage === 'welcome' && (
        <WelcomePage
          onStartQuiz={handleStartQuiz}
          hasQuizProgress={Object.keys(answers).length > 0}
          onLearnMore={() => setCurrentPage('learn-more')}
          isLoggedIn={false}
          hasCompletedQuiz={!!personalityProfile}
          onGenerateNewBooks={() => {
            if (!personalityProfile) return;
            const newRecs = getBookRecommendations(personalityProfile, allRecommendedIds);
            setRecommendations(newRecs);
            setAllRecommendedIds([...allRecommendedIds, ...newRecs.map(book => book.id)]);
            setCurrentPage('generated');
          }}
        />
      )}
      {currentPage === 'quiz' && (
        <QuizPage 
          questions={questions} 
          initialAnswers={answers}
          initialQuestionIndex={currentQuestionIndex}
          onComplete={handleQuizComplete}
          onProgress={handleQuizProgress}
          onHome={handleHomeFromQuiz}
        />
      )}
      {currentPage === 'results' && personalityProfile && (
        <ResultsPage 
          profile={personalityProfile}
          recommendations={recommendations}
          onRetakeQuiz={handleRetakeQuiz}
          onHome={handleHomeFromResults}
          favorites={favorites}
          onToggleFavorite={handleToggleFavorite}
          user={null}
          onLoginRequired={() => {}}
        />
      )}
      {currentPage === 'favourites' && (
        <FavoritesPage
          favorites={favorites}
          onRemoveFavorite={handleRemoveFavorite}
          onBack={() => setCurrentPage('welcome')}
          hasCompletedQuiz={!!personalityProfile}
          onGenerateNewBooks={() => {
            if (!personalityProfile) return;
            const newRecs = getBookRecommendations(personalityProfile, allRecommendedIds);
            setRecommendations(newRecs);
            setAllRecommendedIds([...allRecommendedIds, ...newRecs.map(book => book.id)]);
            setCurrentPage('generated');
          }}
        />
      )}
      {currentPage === 'learn-more' && (
        <LearnMorePage onBack={() => setCurrentPage('welcome')} />
      )}
      {currentPage === 'trending-books' && (
        <TrendingBooksPage onBack={() => setCurrentPage('welcome')} hasCompletedQuiz={!!personalityProfile} />
      )}
      {currentPage === 'trending-authors' && (
        <TrendingAuthorsPage onBack={() => setCurrentPage('welcome')} hasCompletedQuiz={!!personalityProfile} />
      )}
      {['profile', 'celebrity-books'].includes(currentPage) && (
        currentPage === 'celebrity-books' ? (
          <CelebrityTesterPage onBack={() => setCurrentPage('welcome')} hasCompletedQuiz={!!personalityProfile} />
        ) : (
          <PlaceholderPage
            {...getPlaceholderContent(currentPage)}
            onBack={() => setCurrentPage('welcome')}
            profile={personalityProfile}
            onNewRecommendations={handleNewRecommendations}
          />
        )
      )}
      {currentPage === 'generated' && personalityProfile && (
        <GeneratedRecommendationsPage
          profile={personalityProfile}
          recommendations={recommendations}
          onBack={() => setCurrentPage('profile')}
          onHome={() => setCurrentPage('welcome')}
          favorites={favorites}
          onToggleFavorite={handleToggleFavorite}
          user={null}
          onLoginRequired={() => {}}
        />
      )}
    </div>
  );
}

export default App;