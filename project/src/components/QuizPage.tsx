import React, { useState } from 'react';
import { ArrowRight, ArrowLeft, CheckCircle, Home, BookOpen } from 'lucide-react';
import { Question, LikertResponse, BookResponse, BookQuestion } from '../types';

interface QuizPageProps {
  questions: Question[];
  bookQuestions: BookQuestion[];
  initialAnswers: Record<number, LikertResponse>;
  initialBookAnswers: Record<number, BookResponse>;
  initialQuestionIndex: number;
  onComplete: (answers: Record<number, LikertResponse>, bookAnswers: Record<number, BookResponse>) => void;
  onProgress: (answers: Record<number, LikertResponse>, bookAnswers: Record<number, BookResponse>, questionIndex: number) => void;
  onHome: () => void;
}

const QuizPage: React.FC<QuizPageProps> = ({ 
  questions, 
  bookQuestions,
  initialAnswers, 
  initialBookAnswers,
  initialQuestionIndex, 
  onComplete, 
  onProgress, 
  onHome 
}) => {
  const [currentQuestion, setCurrentQuestion] = useState(initialQuestionIndex);
  const [answers, setAnswers] = useState<Record<number, LikertResponse>>(initialAnswers);
  const [bookAnswers, setBookAnswers] = useState<Record<number, BookResponse>>(initialBookAnswers);
  const [selectedAnswer, setSelectedAnswer] = useState<LikertResponse | null>(null);
  const [selectedBookAnswer, setSelectedBookAnswer] = useState<BookResponse | null>(null);

  const currentQuestionData = questions[currentQuestion];
  const isBookQuestion = currentQuestionData.type === 'book';
  const currentBookData = isBookQuestion ? bookQuestions.find(bq => bq.id === currentQuestionData.id) : null;

  const handleAnswer = (answer: LikertResponse) => {
    setSelectedAnswer(answer);
    const newAnswers = { ...answers, [questions[currentQuestion].id]: answer };
    setAnswers(newAnswers);
    
    const nextQuestionIndex = currentQuestion + 1;

    if (currentQuestion < questions.length - 1) {
      onProgress(newAnswers, bookAnswers, nextQuestionIndex);
      setTimeout(() => {
        setSelectedAnswer(null); // Reset selection for next question
        setCurrentQuestion(nextQuestionIndex);
      }, 300);
    } else {
      setTimeout(() => {
        onComplete(newAnswers, bookAnswers);
      }, 300);
    }
  };

  const handleBookAnswer = (answer: BookResponse) => {
    setSelectedBookAnswer(answer);
    const newBookAnswers = { ...bookAnswers, [questions[currentQuestion].id]: answer };
    setBookAnswers(newBookAnswers);
    
    const nextQuestionIndex = currentQuestion + 1;

    if (currentQuestion < questions.length - 1) {
      onProgress(answers, newBookAnswers, nextQuestionIndex);
      setTimeout(() => {
        setSelectedBookAnswer(null); // Reset selection for next question
        setCurrentQuestion(nextQuestionIndex);
      }, 300);
    } else {
      setTimeout(() => {
        onComplete(answers, newBookAnswers);
      }, 300);
    }
  };

  const handlePrevious = () => {
    if (currentQuestion > 0) {
      const prevQuestionIndex = currentQuestion - 1;
      setSelectedAnswer(null); // Reset selection when going back
      setSelectedBookAnswer(null);
      setCurrentQuestion(prevQuestionIndex);
      onProgress(answers, bookAnswers, prevQuestionIndex);
    }
  };

  const likertOptions = [
    { value: 1 as LikertResponse, label: 'Strongly Agree', color: 'from-emerald-600 to-green-700 hover:from-emerald-700 hover:to-green-800' },
    { value: 2 as LikertResponse, label: 'Agree', color: 'from-lime-500 to-emerald-600 hover:from-lime-600 hover:to-emerald-700' },
    { value: 3 as LikertResponse, label: 'Neutral', color: 'from-gray-500 to-gray-600 hover:from-gray-600 hover:to-gray-700' },
    { value: 4 as LikertResponse, label: 'Disagree', color: 'from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600' },
    { value: 5 as LikertResponse, label: 'Strongly Disagree', color: 'from-red-600 to-red-700 hover:from-red-700 hover:to-red-800' }
  ];

  const bookOptions = [
    { value: 'yes' as BookResponse, label: 'Yes', color: 'from-emerald-600 to-green-700 hover:from-emerald-700 hover:to-green-800' },
    { value: 'no' as BookResponse, label: 'No', color: 'from-red-600 to-red-700 hover:from-red-700 hover:to-red-800' }
  ];

  const progress = ((currentQuestion + 1) / questions.length) * 100;

  return (
    <div className="min-h-screen flex items-center justify-center p-3 sm:p-4 pb-20 sm:pb-8 relative overflow-hidden">
      {/* Home Button - Top Left */}
      <button
        onClick={onHome}
        className="fixed top-4 left-4 sm:top-6 sm:left-6 z-50 bg-white/10 backdrop-blur-md border border-white/20 hover:bg-white/20 text-white p-2.5 sm:p-3 rounded-xl transition-all duration-300 transform hover:scale-105"
        aria-label="Go to Home"
      >
        <Home className="w-5 h-5 sm:w-6 sm:h-6" />
      </button>

      {/* Background Elements */}
      <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900" />
      <div className="absolute top-20 left-20 w-72 h-72 bg-purple-500/10 rounded-full blur-3xl hidden md:block" />
      <div className="absolute bottom-20 right-20 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl hidden md:block" />
      
      <div className="max-w-3xl mx-auto w-full relative z-10 mt-12 sm:mt-0">
        {/* Previous Button - Left Side - Hidden on mobile, shown on desktop */}
        <button
          onClick={handlePrevious}
          disabled={currentQuestion === 0}
          className="hidden md:block absolute left-0 top-1/2 transform -translate-y-1/2 -translate-x-20 bg-white/5 backdrop-blur-md border border-white/10 hover:bg-white/10 hover:border-white/20 disabled:opacity-30 disabled:cursor-not-allowed text-white/90 hover:text-white p-4 rounded-2xl font-medium transition-all duration-300 hover:shadow-lg"
        >
          <ArrowLeft className="w-7 h-7" />
        </button>

        {/* Progress Section */}
        <div className="mb-6 sm:mb-8 md:mb-12">
          <div className="flex justify-between items-center mb-4 sm:mb-6 gap-2 sm:gap-4">
            <div className="flex items-center space-x-2 sm:space-x-3 flex-1 min-w-0">
              <div className="w-8 h-8 sm:w-10 sm:h-10 bg-gradient-to-r from-amber-500 to-orange-600 rounded-xl flex items-center justify-center flex-shrink-0">
                <span className="text-white font-bold text-sm sm:text-base">{currentQuestion + 1}</span>
              </div>
              <div className="min-w-0">
                <div className="text-white font-semibold text-sm sm:text-base truncate">
                  Question {currentQuestion + 1} of {questions.length}
                </div>
                <div className="text-white/70 text-xs sm:text-sm">
                  {Math.round(progress)}% Complete
                </div>
              </div>
            </div>
            <div className="flex items-center space-x-1 sm:space-x-2 flex-shrink-0">
              {Array.from({ length: Math.min(questions.length, 30) }, (_, i) => (
                <div
                  key={i}
                  className={`w-1.5 h-1.5 sm:w-2 sm:h-2 rounded-full transition-all duration-300 ${
                    i <= currentQuestion ? 'bg-amber-400' : 'bg-white/30'
                  }`}
                />
              ))}
              {questions.length > 30 && (
                <span className="text-white/50 text-xs ml-1">+{questions.length - 30}</span>
              )}
            </div>
          </div>
          
          {/* Progress Bar */}
          <div className="w-full bg-white/20 rounded-full h-1.5 sm:h-2">
            <div 
              className="bg-gradient-to-r from-amber-500 to-orange-600 h-1.5 sm:h-2 rounded-full transition-all duration-500"
              style={{ width: `${progress}%` }}
            />
          </div>
        </div>

        {/* Question Content */}
        <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-4 sm:p-6 md:p-8 mb-6 sm:mb-8">
          {isBookQuestion && currentBookData ? (
            // Book Question Display
            <div className="text-center">
              <div className="mb-4 sm:mb-6">
                <div className="inline-flex items-center space-x-2 bg-white/10 backdrop-blur-sm border border-white/20 rounded-full px-3 py-1.5 sm:px-4 sm:py-2 mb-3 sm:mb-4">
                  <BookOpen className="w-3 h-3 sm:w-4 sm:h-4 text-amber-400" />
                  <span className="text-xs sm:text-sm font-medium text-white/80">Book Question</span>
                </div>
                
                {/* Book Cover and Info */}
                <div className="flex flex-col md:flex-row items-center justify-center gap-4 sm:gap-6 mb-4 sm:mb-6">
                  {/* Book Cover */}
                  <div className="w-32 h-44 sm:w-40 sm:h-56 md:w-48 md:h-64 bg-gradient-to-br from-amber-500/20 to-orange-600/20 border border-white/20 rounded-lg flex items-center justify-center shadow-xl flex-shrink-0">
                    {currentBookData.coverImageUrl ? (
                      <img 
                        src={currentBookData.coverImageUrl} 
                        alt={`${currentBookData.title} book cover`}
                        className="w-full h-full object-cover rounded-lg"
                        onError={(e) => {
                          // Fallback to styled div if image fails to load
                          e.currentTarget.style.display = 'none';
                          e.currentTarget.nextElementSibling?.classList.remove('hidden');
                        }}
                      />
                    ) : null}
                    <div className={`${currentBookData.coverImageUrl ? 'hidden' : ''} text-center p-4`}>
                      <div className="text-3xl sm:text-4xl mb-2">📚</div>
                      <div className="text-white/80 text-xs sm:text-sm font-medium">{currentBookData.title}</div>
                    </div>
                  </div>
                  
                  {/* Book Info */}
                  <div className="text-center md:text-left max-w-md">
                    <h2 className="text-xl sm:text-2xl font-bold text-white mb-1 sm:mb-2 px-2">{currentBookData.title}</h2>
                    <p className="text-white/70 text-base sm:text-lg mb-2 sm:mb-3">by {currentBookData.author}</p>
                    <p className="text-white/80 text-sm sm:text-base leading-relaxed px-2">
                      {currentBookData.description}
                    </p>
                  </div>
                </div>
              </div>
              
              <div className="mb-4 sm:mb-6 md:mb-8">
                <h3 className="text-lg sm:text-xl font-semibold text-white mb-4 sm:mb-6 px-2">
                  Does this sort of book interest you?
                </h3>
                
                <div className="flex flex-col sm:flex-row gap-3 sm:gap-4 justify-center">
                  {bookOptions.map((option) => (
                    <button
                      key={option.value}
                      onClick={() => handleBookAnswer(option.value)}
                      disabled={selectedBookAnswer !== null}
                      className={`bg-gradient-to-r ${option.color} text-white px-6 py-3 sm:px-8 sm:py-4 rounded-xl font-semibold text-base sm:text-lg transition-all duration-300 transform hover:scale-105 hover:shadow-2xl disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none w-full sm:w-auto ${
                        selectedBookAnswer === option.value ? 'ring-4 ring-white/30' : ''
                      }`}
                    >
                      {option.label}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          ) : (
            // Regular Statement Question Display
            <div className="text-center">
              <h2 className="text-xl sm:text-2xl font-bold text-white mb-6 sm:mb-8 leading-relaxed px-2">
                {currentQuestionData.text}
              </h2>
              
              <div className="space-y-3 sm:space-y-4">
                {likertOptions.map((option) => (
                  <button
                    key={option.value}
                    onClick={() => handleAnswer(option.value)}
                    disabled={selectedAnswer !== null}
                    className={`w-full bg-gradient-to-r ${option.color} text-white px-4 py-3 sm:px-6 sm:py-4 rounded-xl font-semibold text-base sm:text-lg transition-all duration-300 transform hover:scale-105 hover:shadow-2xl disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none ${
                      selectedAnswer === option.value ? 'ring-4 ring-white/30' : ''
                    }`}
                  >
                    {option.label}
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Mobile Previous Button - Bottom Left */}
        <div className="md:hidden fixed bottom-4 left-4 z-50">
          <button
            onClick={handlePrevious}
            disabled={currentQuestion === 0}
            className="bg-white/10 backdrop-blur-md border border-white/20 hover:bg-white/20 disabled:opacity-30 disabled:cursor-not-allowed text-white/90 hover:text-white p-3 rounded-xl font-medium transition-all duration-300 shadow-lg"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
        </div>


      </div>
    </div>
  );
};

export default QuizPage;