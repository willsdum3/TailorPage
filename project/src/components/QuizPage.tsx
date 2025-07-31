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
    <div className="min-h-screen flex items-center justify-center p-4 relative overflow-hidden">
      {/* Background Elements */}
      <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900" />
      <div className="absolute top-20 left-20 w-72 h-72 bg-purple-500/10 rounded-full blur-3xl" />
      <div className="absolute bottom-20 right-20 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl" />
      
      <div className="max-w-3xl mx-auto w-full relative z-10">
        {/* Progress Section */}
        <div className="mb-12">
          <div className="flex justify-between items-center mb-6">
            <div className="flex items-center space-x-3">
              <div className="w-10 h-10 bg-gradient-to-r from-amber-500 to-orange-600 rounded-xl flex items-center justify-center">
                <span className="text-white font-bold">{currentQuestion + 1}</span>
              </div>
              <div>
                <div className="text-white font-semibold">
                  Question {currentQuestion + 1} of {questions.length}
                </div>
                <div className="text-white/70 text-sm">
                  {Math.round(progress)}% Complete
                </div>
              </div>
            </div>
            <div className="flex items-center space-x-2">
              {Array.from({ length: questions.length }, (_, i) => (
                <div
                  key={i}
                  className={`w-2 h-2 rounded-full transition-all duration-300 ${
                    i <= currentQuestion ? 'bg-amber-400' : 'bg-white/30'
                  }`}
                />
              ))}
            </div>
          </div>
          
          {/* Progress Bar */}
          <div className="w-full bg-white/20 rounded-full h-2">
            <div 
              className="bg-gradient-to-r from-amber-500 to-orange-600 h-2 rounded-full transition-all duration-500"
              style={{ width: `${progress}%` }}
            />
          </div>
        </div>

        {/* Question Content */}
        <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 mb-8">
          {isBookQuestion && currentBookData ? (
            // Book Question Display
            <div className="text-center">
              <div className="mb-6">
                <div className="inline-flex items-center space-x-2 bg-white/10 backdrop-blur-sm border border-white/20 rounded-full px-4 py-2 mb-4">
                  <BookOpen className="w-4 h-4 text-amber-400" />
                  <span className="text-sm font-medium text-white/80">Book Question</span>
                </div>
                
                {/* Book Cover and Info */}
                <div className="flex flex-col md:flex-row items-center justify-center gap-6 mb-6">
                  {/* Book Cover */}
                  <div className="w-48 h-64 bg-gradient-to-br from-amber-500/20 to-orange-600/20 border border-white/20 rounded-lg flex items-center justify-center shadow-xl">
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
                      <div className="text-4xl mb-2">📚</div>
                      <div className="text-white/80 text-sm font-medium">{currentBookData.title}</div>
                    </div>
                  </div>
                  
                  {/* Book Info */}
                  <div className="text-left max-w-md">
                    <h2 className="text-2xl font-bold text-white mb-2">{currentBookData.title}</h2>
                    <p className="text-white/70 text-lg mb-3">by {currentBookData.author}</p>
                    <p className="text-white/80 text-base leading-relaxed">
                      {currentBookData.description}
                    </p>
                  </div>
                </div>
              </div>
              
              <div className="mb-8">
                <h3 className="text-xl font-semibold text-white mb-6">
                  Does this sort of book interest you?
                </h3>
                
                <div className="flex flex-col sm:flex-row gap-4 justify-center">
                  {bookOptions.map((option) => (
                    <button
                      key={option.value}
                      onClick={() => handleBookAnswer(option.value)}
                      disabled={selectedBookAnswer !== null}
                      className={`bg-gradient-to-r ${option.color} text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-300 transform hover:scale-105 hover:shadow-2xl disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none ${
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
              <h2 className="text-2xl font-bold text-white mb-8 leading-relaxed">
                {currentQuestionData.text}
              </h2>
              
              <div className="space-y-4">
                {likertOptions.map((option) => (
                  <button
                    key={option.value}
                    onClick={() => handleAnswer(option.value)}
                    disabled={selectedAnswer !== null}
                    className={`w-full bg-gradient-to-r ${option.color} text-white px-6 py-4 rounded-xl font-semibold text-lg transition-all duration-300 transform hover:scale-105 hover:shadow-2xl disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none ${
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

        {/* Navigation Buttons */}
        <div className="flex justify-between items-center">
          <button
            onClick={handlePrevious}
            disabled={currentQuestion === 0}
            className="bg-white/10 backdrop-blur-sm border border-white/20 hover:bg-white/20 disabled:opacity-50 disabled:cursor-not-allowed text-white px-6 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105 inline-flex items-center space-x-2"
          >
            <ArrowLeft className="w-4 h-4" />
            <span>Previous</span>
          </button>
          
          <button
            onClick={onHome}
            className="bg-white/10 backdrop-blur-sm border border-white/20 hover:bg-white/20 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105 inline-flex items-center space-x-2"
          >
            <Home className="w-4 h-4" />
            <span>Home</span>
          </button>
        </div>
      </div>
    </div>
  );
};

export default QuizPage;