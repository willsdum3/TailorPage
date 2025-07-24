import React, { useState } from 'react';
import { ArrowRight, ArrowLeft, CheckCircle, Home } from 'lucide-react';
import { Question, LikertResponse } from '../types';

interface QuizPageProps {
  questions: Question[];
  initialAnswers: Record<number, LikertResponse>;
  initialQuestionIndex: number;
  onComplete: (answers: Record<number, LikertResponse>) => void;
  onProgress: (answers: Record<number, LikertResponse>, questionIndex: number) => void;
  onHome: () => void;
}

const QuizPage: React.FC<QuizPageProps> = ({ 
  questions, 
  initialAnswers, 
  initialQuestionIndex, 
  onComplete, 
  onProgress, 
  onHome 
}) => {
  const [currentQuestion, setCurrentQuestion] = useState(initialQuestionIndex);
  const [answers, setAnswers] = useState<Record<number, LikertResponse>>(initialAnswers);
  const [selectedAnswer, setSelectedAnswer] = useState<LikertResponse | null>(null);

  const handleAnswer = (answer: LikertResponse) => {
    setSelectedAnswer(answer);
    const newAnswers = { ...answers, [questions[currentQuestion].id]: answer };
    setAnswers(newAnswers);
    
    const nextQuestionIndex = currentQuestion + 1;

    if (currentQuestion < questions.length - 1) {
      onProgress(newAnswers, nextQuestionIndex);
      setTimeout(() => {
        setSelectedAnswer(null); // Reset selection for next question
        setCurrentQuestion(nextQuestionIndex);
      }, 300);
    } else {
      setTimeout(() => {
        onComplete(newAnswers);
      }, 300);
    }
  };

  const handlePrevious = () => {
    if (currentQuestion > 0) {
      const prevQuestionIndex = currentQuestion - 1;
      setSelectedAnswer(null); // Reset selection when going back
      setCurrentQuestion(prevQuestionIndex);
      onProgress(answers, prevQuestionIndex);
    }
  };

  const likertOptions = [
    { value: 1 as LikertResponse, label: 'Strongly Agree', color: 'from-emerald-600 to-green-700 hover:from-emerald-700 hover:to-green-800' },
    { value: 2 as LikertResponse, label: 'Agree', color: 'from-lime-500 to-emerald-600 hover:from-lime-600 hover:to-emerald-700' },
    { value: 3 as LikertResponse, label: 'Neutral', color: 'from-gray-500 to-gray-600 hover:from-gray-600 hover:to-gray-700' },
    { value: 4 as LikertResponse, label: 'Disagree', color: 'from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600' },
    { value: 5 as LikertResponse, label: 'Strongly Disagree', color: 'from-red-600 to-red-700 hover:from-red-700 hover:to-red-800' }
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
          
          <div className="w-full bg-white/20 rounded-full h-3 overflow-hidden">
            <div 
              className="bg-gradient-to-r from-amber-500 to-orange-600 h-3 rounded-full transition-all duration-700 ease-out"
              style={{ width: `${progress}%` }}
            />
          </div>
        </div>

        {/* Question Card */}
        <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 mb-8 shadow-2xl">
          <h2 className="text-2xl md:text-3xl font-bold text-white mb-8 text-center leading-relaxed">
            {questions[currentQuestion].text}
          </h2>

          <div className="space-y-4">
            {likertOptions.map((option) => (
              <button
                key={option.value}
                onClick={() => handleAnswer(option.value)}
                className={`bg-gradient-to-r ${
                  selectedAnswer === option.value 
                    ? 'from-amber-500 to-orange-600' // Selected state color
                    : option.color // Default color
                } text-white px-6 py-4 rounded-xl font-medium text-base transition-all duration-300 transform hover:scale-105 hover:shadow-xl w-full flex items-center justify-between group`}
              >
                <span>{option.label}</span>
                <CheckCircle className={`w-5 h-5 transition-opacity duration-200 ${
                  selectedAnswer === option.value ? 'opacity-100' : 'opacity-0 group-hover:opacity-100'
                }`} />
              </button>
            ))}
          </div>
        </div>

        {/* Navigation */}
        {currentQuestion > 0 && (
          <div className="text-center">
            <button
              onClick={handlePrevious}
              className="bg-white/10 backdrop-blur-sm border border-white/20 hover:bg-white/20 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105 inline-flex items-center space-x-2"
            >
              <ArrowLeft className="w-4 h-4" />
              <span>Previous Question</span>
            </button>
          </div>
        )}
      </div>
      
      {/* Home Button - Top Left Corner */}
      <div className="fixed top-6 left-6 z-50">
        <button
          onClick={onHome}
          className="bg-white/10 backdrop-blur-sm border border-white/20 hover:bg-white/20 text-white p-3 rounded-xl transition-all duration-300 transform hover:scale-105"
          title="Go to Home"
        >
          <Home className="w-5 h-5" />
        </button>
      </div>
    </div>
  );
};

export default QuizPage;