import React, { useState } from 'react';
import { 
  Home,
  ArrowLeft, 
  Brain, 
  Book, 
  ShoppingCart, 
  ExternalLink, 
  Star,
  Sparkles,
  ChevronDown,
  ChevronUp,
  TrendingUp,
  Heart,
  Users,
  Lightbulb,
  Target,
  Zap,
  Shield,
  Globe,
  Palette,
  Music,
  Camera
} from 'lucide-react';
import { celebrities } from '../data/celebrities';
import { CelebrityProfile } from '../data/celebrities';
import { BookCover } from './BookCover';
import BookSummaryModal, { BookSummaryData } from './BookSummaryModal';
import { bookInfoService } from '../services/bookInfoService';

import { useScrollToTop } from '../hooks/useScrollToTop';
import { analyzePersonality, TraitAnalysis } from '../utils/personalityAnalysis';

interface CelebrityTesterPageProps {
  onBack: () => void;
  hasCompletedQuiz: boolean;
  onStartQuiz?: () => void;
}

const CelebrityTesterPage: React.FC<CelebrityTesterPageProps> = ({ onBack, hasCompletedQuiz, onStartQuiz }) => {
  const [selectedCelebrity, setSelectedCelebrity] = useState<CelebrityProfile | null>(null);
  const [expandedPersonality, setExpandedPersonality] = useState(false);
  
  // Book summary modal state
  const [selectedBook, setSelectedBook] = useState<BookSummaryData | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isLoadingBookInfo, setIsLoadingBookInfo] = useState(false);

  // Scroll to top when selected celebrity changes
  useScrollToTop([selectedCelebrity?.id]);

  const handleBookCoverClick = async (book: any) => {
    console.log('🎯 CelebrityTester: Book cover clicked for:', book.title, 'by', book.author);
    console.log('🔍 CelebrityTester: Setting modal state...');
    setIsLoadingBookInfo(true);
    
    try {
      const bookInfo = await bookInfoService.getBookInfo(book.title, book.author);
      setSelectedBook(bookInfo);
      setIsModalOpen(true);
      console.log('✅ CelebrityTester: Book info loaded successfully:', bookInfo);
      console.log('🔍 CelebrityTester: selectedBook set, modal should be visible');
    } catch (error) {
      console.error('❌ CelebrityTester: Error fetching book info:', error);
      // Set basic book info as fallback
      const fallbackBook = {
        title: book.title,
        author: book.author,
        description: book.description || `A book by ${book.author} that matches this celebrity's personality.`,
        genre: book.genre,
        amazonLink: book.amazonLink
      };
      setSelectedBook(fallbackBook);
      setIsModalOpen(true);
      console.log('🔍 CelebrityTester: Fallback book set:', fallbackBook);
    } finally {
      setIsLoadingBookInfo(false);
    }
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setSelectedBook(null);
  };

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

  if (selectedCelebrity) {
    return (
      <div className="min-h-screen py-8 px-4 relative">
        {/* Background Elements */}
        <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900" />
        <div className="absolute top-20 left-20 w-72 h-72 bg-purple-500/10 rounded-full blur-3xl" />
        <div className="absolute bottom-20 right-20 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl" />
        
        <div className="max-w-6xl mx-auto relative z-10">
          {/* Header */}
          <div className="text-center mb-12">
            <button
              onClick={() => setSelectedCelebrity(null)}
              className="mb-8 bg-white/10 backdrop-blur-sm border border-white/20 hover:bg-white/20 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105 inline-flex items-center space-x-2"
            >
              <ArrowLeft className="w-4 h-4" />
              <span>Back to Celebrities</span>
            </button>
            
            <div className="flex items-center justify-center space-x-6 mb-8">
              <div className="w-32 h-32 rounded-2xl overflow-hidden border-4 border-amber-400/50 shadow-xl bg-white/5">
                <img
                  src={selectedCelebrity.imageUrl}
                  alt={selectedCelebrity.name}
                  className="w-full h-full object-cover"
                />
              </div>
              <div className="text-left">
                <h1 className="text-4xl md:text-5xl font-bold text-white mb-2">
                  {selectedCelebrity.name}
                </h1>
                <p className="text-xl text-amber-400 font-medium mb-2">{selectedCelebrity.profession}</p>
                <p className="text-white/70 max-w-md">{selectedCelebrity.bio}</p>
              </div>
            </div>
          </div>

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
                const traitOrder = ['openness', 'conscientiousness', 'extraversion', 'agreeableness'];
                const orderedTraits = traitOrder.map(trait => [trait, selectedCelebrity.personalityScores[trait as keyof typeof selectedCelebrity.personalityScores]]);
                
                return (
                  <>
                    {orderedTraits.map(([trait, score]) => {
                      // Create a mock profile to use with analyzePersonality
                      const mockProfile = {
                        openness: trait === 'openness' ? Number(score) : 0,
                        conscientiousness: trait === 'conscientiousness' ? Number(score) : 0,
                        extraversion: trait === 'extraversion' ? Number(score) : 0,
                        agreeableness: trait === 'agreeableness' ? Number(score) : 0,
                        emotionalStability: trait === 'emotionalStability' ? Number(score) : 0,
                        rationalThinking: 0,
                        coreValues: 0,
                        lifestyle: 0,
                        socialStyle: 0,
                        selfExpression: 0
                      };
                      
                      const traitAnalyses = analyzePersonality(mockProfile);
                      const traitInfo = traitAnalyses.find(t => 
                        t.name === 'Openness to Experience' && trait === 'openness' ||
                        t.name === 'Conscientiousness' && trait === 'conscientiousness' ||
                        t.name === 'Extraversion' && trait === 'extraversion' ||
                        t.name === 'Agreeableness' && trait === 'agreeableness' ||
                        t.name === 'Emotional Stability' && trait === 'emotionalStability'
                      );
                      
                      if (!traitInfo) return null;
                      
                      const IconComponent = getTraitIcon(traitInfo.name);
                      
                      return (
                        <div key={trait} className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-4">
                          <div className="flex items-center space-x-3 mb-3">
                            <div className={`w-10 h-10 bg-gradient-to-r ${traitInfo.color} rounded-lg flex items-center justify-center`}>
                              <IconComponent className="w-5 h-5 text-white" />
                            </div>
                            <div className="flex-1">
                              <h3 className="font-semibold text-white">{traitInfo.name}</h3>
                              <div className="flex items-center space-x-2">
                                <div className="flex-1 bg-white/20 rounded-full h-2">
                                  <div 
                                    className={`bg-gradient-to-r ${traitInfo.color} h-2 rounded-full transition-all duration-500`}
                                    style={{ width: `${traitInfo.percentage}%` }}
                                  />
                                </div>
                                <span className="text-white/80 text-sm font-medium">{traitInfo.score}/25</span>
                              </div>
                            </div>
                          </div>
                          
                          {expandedPersonality && (
                            <div className="mt-3 pt-3 border-t border-white/10">
                              <p className="text-white/70 text-sm mb-2">{traitInfo.description}</p>
                              <div className="mb-3">
                                <p className="text-white/60 text-xs mb-1">
                                  <span className="font-medium text-amber-400">Level:</span> {traitInfo.level}
                                </p>
                                <p className="text-white/60 text-xs mb-2">
                                  <span className="font-medium text-amber-400">Strengths:</span> {traitInfo.strengths.join(', ')}
                                </p>
                                <p className="text-white/60 text-xs">
                                  <span className="font-medium text-amber-400">Reading Preferences:</span> {traitInfo.readingPreferences.join(', ')}
                                </p>
                              </div>
                            </div>
                          )}
                        </div>
                      );
                    })}
                    
                    {/* Emotional Stability at bottom center */}
                    {(() => {
                      const emotionalStabilityScore = selectedCelebrity.personalityScores.emotionalStability;
                      const mockProfile = {
                        openness: 0,
                        conscientiousness: 0,
                        extraversion: 0,
                        agreeableness: 0,
                        emotionalStability: Number(emotionalStabilityScore),
                        rationalThinking: 0,
                        coreValues: 0,
                        lifestyle: 0,
                        socialStyle: 0,
                        selfExpression: 0
                      };
                      
                      const traitAnalyses = analyzePersonality(mockProfile);
                      const traitInfo = traitAnalyses.find(t => t.name === 'Emotional Stability');
                      
                      if (!traitInfo) return null;
                      
                      const IconComponent = getTraitIcon(traitInfo.name);
                      
                      return (
                        <div key="emotionalStability" className="md:col-span-2 flex justify-center">
                          <div className="w-full max-w-md bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6 transform scale-105">
                          <div className="flex items-center space-x-3 mb-3">
                            <div className={`w-10 h-10 bg-gradient-to-r ${traitInfo.color} rounded-lg flex items-center justify-center`}>
                              <IconComponent className="w-5 h-5 text-white" />
                            </div>
                            <div className="flex-1">
                              <h3 className="font-semibold text-white">{traitInfo.name}</h3>
                              <div className="flex items-center space-x-2">
                                <div className="flex-1 bg-white/20 rounded-full h-2">
                                  <div 
                                    className={`bg-gradient-to-r ${traitInfo.color} h-2 rounded-full transition-all duration-500`}
                                    style={{ width: `${traitInfo.percentage}%` }}
                                  />
                                </div>
                                <span className="text-white/80 text-sm font-medium">{traitInfo.score}/25</span>
                              </div>
                            </div>
                          </div>
                          
                          {expandedPersonality && (
                            <div className="mt-3 pt-3 border-t border-white/10">
                              <p className="text-white/70 text-sm mb-2">{traitInfo.description}</p>
                              <div className="mb-3">
                                <p className="text-white/60 text-xs mb-1">
                                  <span className="font-medium text-amber-400">Level:</span> {traitInfo.level}
                                </p>
                                <p className="text-white/60 text-xs mb-2">
                                  <span className="font-medium text-amber-400">Strengths:</span> {traitInfo.strengths.join(', ')}
                                </p>
                                <p className="text-white/60 text-xs">
                                  <span className="font-medium text-amber-400">Reading Preferences:</span> {traitInfo.readingPreferences.join(', ')}
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

          {/* Book Recommendations */}
          <div className="mb-8">
            <div className="text-center mb-8">
              <div className="inline-flex items-center space-x-2 bg-white/10 backdrop-blur-sm border border-white/20 rounded-full px-4 py-2 mb-4">
                <Sparkles className="w-4 h-4 text-amber-400" />
                <span className="text-sm font-medium text-white/80">AI-Generated Recommendations</span>
              </div>
              <h2 className="text-3xl font-bold text-white mb-4">
                <h2 className="text-3xl font-bold text-white">Want Your Own Personalised Recommendations?</h2>
              </h2>
              <p className="text-white/70 max-w-2xl mx-auto">
                Just like these celebrities, you have a unique personality that influences your reading preferences. Take our quiz to discover books perfectly tailored to you!
              </p>
            </div>

            <div className="grid gap-10 md:grid-cols-2 lg:grid-cols-3">
              {selectedCelebrity.bookRecommendations.map((book, index) => (
                <div key={index} className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6 hover:bg-white/15 transition-all duration-300 transform hover:scale-105 group">
                  {/* Book Cover */}
                  <div className="flex justify-center mb-4">
                    <BookCover
                      title={book.title}
                      author={book.author}
                      size="lg"
                      priority="high"
                      lazy={false}
                      clickable={true}
                      onClick={() => {
                        console.log('🎯 CelebrityTester: Direct click detected for:', book.title);
                        handleBookCoverClick(book);
                      }}
                    />
                  </div>
                  
                  <div className="flex items-start justify-between mb-4">
                    <div className="flex-1">
                      <span className="inline-block bg-gradient-to-r from-amber-500 to-orange-600 text-white px-3 py-1 rounded-full text-sm font-medium mb-3">
                        {book.genre}
                      </span>
                      
                      <h3 className="text-xl font-bold text-white mb-2 group-hover:text-amber-400 transition-colors duration-300">
                        {book.title}
                      </h3>
                      <p className="text-white/70 font-medium mb-3">by {book.author}</p>
                    </div>

                  </div>
                  
                  <p className="text-white/70 mb-4 leading-relaxed text-sm">
                    {book.description}
                  </p>
                  
                  <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-4 mb-6">
                    <p className="text-sm text-white/80">
                      <span className="font-medium text-amber-400">Why this fits:</span> {book.reason}
                    </p>
                  </div>
                  
                  <a
                    href={book.amazonLink}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white px-4 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105 inline-flex items-center justify-center space-x-2 w-full group"
                  >
                    <Book className="w-4 h-4" />
                    <span>View on Amazon</span>
                  </a>
                </div>
              ))}
            </div>
          </div>

          {/* Back to List */}
          <div className="text-center">
            <button
              onClick={() => setSelectedCelebrity(null)}
              className="bg-white/10 backdrop-blur-sm border border-white/20 hover:bg-white/20 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-300 transform hover:scale-105 inline-flex items-center space-x-2"
            >
              <ArrowLeft className="w-5 h-5" />
              <span>Explore More Celebrities</span>
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen py-8 px-4 relative overflow-hidden">
      {/* Background Elements */}
      <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900" />
      <div className="absolute top-20 left-20 w-72 h-72 bg-purple-500/10 rounded-full blur-3xl" />
      <div className="absolute bottom-20 right-20 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl" />
      
      {/* Home Button - Top Left */}
      <button
        onClick={onBack}
        className="fixed top-6 left-6 z-50 bg-white/10 backdrop-blur-md border border-white/20 hover:bg-white/20 text-white p-3 rounded-xl transition-all duration-300 transform hover:scale-105"
        aria-label="Go to Home"
      >
        <Home className="w-6 h-6" />
      </button>

      <div className="max-w-7xl mx-auto relative z-10">
        {/* Header */}
        <div className="text-center mb-12">
          
          <div className="inline-flex items-center space-x-2 bg-white/10 backdrop-blur-sm border border-white/20 rounded-full px-4 py-2 mb-6">
            <Star className="w-4 h-4 text-amber-400" />
            <span className="text-sm font-medium text-white/80">Celebrity Personality Analysis</span>
          </div>
          
          <h1 className="text-5xl md:text-6xl font-bold text-white mb-6 leading-tight">
            Celebrity <span className="bg-gradient-to-r from-amber-400 to-orange-500 bg-clip-text text-transparent">Book Tester</span>
          </h1>
          
          <p className="text-xl text-white/70 mb-8 max-w-3xl mx-auto leading-relaxed">
            Discover what books would perfectly match famous personalities based on their psychological profiles. See how our AI analyses celebrity traits to recommend their ideal reads.
          </p>
        </div>

        {/* Celebrity Grid */}
        <div className="grid gap-10 md:grid-cols-2 lg:grid-cols-5 mb-16">
          {celebrities.map((celebrity) => (
            <div 
              key={celebrity.id} 
              onClick={() => setSelectedCelebrity(celebrity)}
              className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6 hover:bg-white/15 transition-all duration-300 transform hover:scale-105 cursor-pointer group"
            >
              <div className="text-center">
                <div className="w-24 h-24 rounded-xl overflow-hidden mx-auto mb-4 border-2 border-white/20 group-hover:border-amber-400/50 transition-colors duration-300 shadow-lg bg-white/5">
                  <img
                    src={celebrity.imageUrl}
                    alt={celebrity.name}
                    className="w-full h-full object-cover"
                  />
                </div>
                
                <h3 className="text-xl font-bold text-white mb-2 group-hover:text-amber-400 transition-colors duration-300">
                  {celebrity.name}
                </h3>
                <p className="text-amber-400 font-medium text-sm mb-3">{celebrity.profession}</p>
                
                <p className="text-white/70 text-sm mb-4 leading-relaxed line-clamp-3">
                  {celebrity.bio}
                </p>
                
                <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-3 mb-4">
                  <div className="text-xs text-white/60 mb-2">Personality Highlights:</div>
                  <div className="flex flex-wrap gap-1">
                    {Object.entries(celebrity.personalityScores)
                      .filter(([_, score]) => score >= 4)
                      .slice(0, 3)
                      .map(([trait, score]) => (
                        <span key={trait} className="bg-amber-400/20 text-amber-300 px-2 py-1 rounded-lg text-xs font-medium">
                          {trait.charAt(0).toUpperCase() + trait.slice(1)} ({score})
                        </span>
                      ))
                    }
                  </div>
                </div>
                
                <div className="text-center">
                  <span className="text-white/60 text-sm">
                    {celebrity.bookRecommendations.length} book recommendations
                  </span>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Bottom CTA */}
        <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 text-center">
          {hasCompletedQuiz ? (
            <>
              <div className="mb-8">
                <div className="inline-flex items-center space-x-2 mb-4">
                  <Sparkles className="w-6 h-6 text-amber-400" />
                  <h2 className="text-3xl font-bold text-white">Enjoying Tailor Page?</h2>
                </div>
                <p className="text-white/70 mb-8 max-w-2xl mx-auto">
                  Share the app with your friends on social media!
                </p>
                <div className="flex flex-wrap justify-center gap-4">
                  <a href="https://www.facebook.com/sharer/sharer.php?u=https://your-app-url.com" target="_blank" rel="noopener noreferrer" className="flex items-center space-x-3 px-6 py-3 rounded-xl font-semibold bg-white/10 hover:bg-blue-500/20 transition-all duration-300 transform hover:scale-105 border border-white/20 hover:border-blue-400/30">
                    <img src="/facebooklogo5.jpg" alt="Facebook" className="w-8 h-8 rounded-md object-cover" />
                    <span>Facebook</span>
                  </a>
                  <a href="https://twitter.com/intent/tweet?url=https://your-app-url.com&text=Check%20out%20Tailor%20Page%20for%20personalized%20book%20recommendations!" target="_blank" rel="noopener noreferrer" className="flex items-center space-x-3 px-6 py-3 rounded-xl font-semibold bg-white/10 hover:bg-black/20 transition-all duration-300 transform hover:scale-105 border border-white/20 hover:border-gray-400/30">
                    <img src="/xlogo2.jpg" alt="X" className="w-8 h-8 rounded-md object-cover" />
                    <span>X</span>
                  </a>
                  <a href="https://www.linkedin.com/sharing/share-offsite/?url=https://your-app-url.com" target="_blank" rel="noopener noreferrer" className="flex items-center space-x-3 px-6 py-3 rounded-xl font-semibold bg-white/10 hover:bg-blue-600/20 transition-all duration-300 transform hover:scale-105 border border-white/20 hover:border-blue-500/30">
                    <img src="/linkedinlogo3.jpg" alt="LinkedIn" className="w-8 h-8 rounded-md object-cover" />
                    <span>LinkedIn</span>
                  </a>
                  <a href="https://reddit.com/submit?url=https://your-app-url.com&title=Check%20out%20Tailor%20Page%20for%20personalized%20book%20recommendations!" target="_blank" rel="noopener noreferrer" className="flex items-center space-x-3 px-6 py-3 rounded-xl font-semibold bg-white/10 hover:bg-orange-500/20 transition-all duration-300 transform hover:scale-105 border border-white/20 hover:border-orange-400/30">
                    <img src="/Redditlogo5.png" alt="Reddit" className="w-8 h-8 rounded-md object-cover" />
                    <span>Reddit</span>
                  </a>
                  <a href="https://api.whatsapp.com/send?text=Check%20out%20Tailor%20Page%20for%20personalized%20book%20recommendations!%20https://your-app-url.com" target="_blank" rel="noopener noreferrer" className="flex items-center space-x-3 px-6 py-3 rounded-xl font-semibold bg-white/10 hover:bg-green-500/20 transition-all duration-300 transform hover:scale-105 border border-white/20 hover:border-green-400/30">
                    <img src="/whatsapplogo3.jpg" alt="WhatsApp" className="w-8 h-8 rounded-md object-cover" />
                    <span>WhatsApp</span>
                  </a>
                  <a href="https://www.instagram.com/" target="_blank" rel="noopener noreferrer" className="flex items-center space-x-3 px-6 py-3 rounded-xl font-semibold bg-white/10 hover:bg-pink-500/20 transition-all duration-300 transform hover:scale-105 border border-white/20 hover:border-pink-400/30">
                    <img src="/instagramlogo3.jpg" alt="Instagram" className="w-8 h-8 rounded-md object-cover" />
                    <span>Instagram</span>
                  </a>
                </div>
              </div>
            </>
          ) : (
            <>
              <div className="mb-8">
                <div className="inline-flex items-center space-x-2 mb-4">
                  <Sparkles className="w-6 h-6 text-amber-400" />
                  <h2 className="text-3xl font-bold text-white">Want Your Own Personalised Recommendations?</h2>
                </div>
                <p className="text-white/70 mb-8 max-w-2xl mx-auto">
                  Just like these celebrities, you have a unique personality that influences your reading preferences. Take our quiz to discover books perfectly tailored to you!
                </p>
              </div>
              <button
                onClick={onStartQuiz || onBack}
                className="bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-300 transform hover:scale-105 hover:shadow-2xl inline-flex items-center space-x-2"
              >
                <span>Take Your Personality Quiz</span>
                <ArrowLeft className="w-5 h-5 rotate-180" />
              </button>
            </>
          )}
        </div>
      </div>
      
      {/* Book Summary Modal */}
      {(() => {
        console.log('🔍 CelebrityTester: Modal rendering check - selectedBook:', !!selectedBook, 'isModalOpen:', isModalOpen);
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

export default CelebrityTesterPage;