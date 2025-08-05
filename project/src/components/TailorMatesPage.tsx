import React, { useState } from 'react';
import { Home, ArrowLeft, Users, MessageCircle, BookOpen, Heart, Star, Search, Filter, Plus, UserPlus, Book, Sparkles } from 'lucide-react';
import { useScrollToTopInstant } from '../hooks/useScrollToTop';

interface BookClub {
  id: string;
  name: string;
  description: string;
  currentBook: string;
  memberCount: number;
  maxMembers: number;
  personalityTraits: string[];
  meetingTime: string;
  nextMeeting: string;
  isPrivate: boolean;
  tags: string[];
}

interface Discussion {
  id: string;
  bookTitle: string;
  author: string;
  topic: string;
  participants: number;
  lastActivity: string;
  tags: string[];
}

interface TailorMatesPageProps {
  onBack: () => void;
  hasCompletedQuiz: boolean;
  onStartQuiz?: () => void;
}

const TailorMatesPage: React.FC<TailorMatesPageProps> = ({ onBack, hasCompletedQuiz, onStartQuiz }) => {
  const [activeTab, setActiveTab] = useState<'clubs' | 'discussions' | 'friends'>('clubs');
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedFilter, setSelectedFilter] = useState('All');

  // Scroll to top when component mounts
  useScrollToTopInstant([]);

  // Mock data for book clubs
  const bookClubs: BookClub[] = [
    {
      id: '1',
      name: 'Fantasy Enthusiasts',
      description: 'A club for lovers of fantasy and magical realism. We explore worlds beyond imagination.',
      currentBook: 'Fourth Wing',
      memberCount: 12,
      maxMembers: 20,
      personalityTraits: ['Openness', 'Extraversion'],
      meetingTime: 'Every Tuesday 7 PM',
      nextMeeting: 'Tomorrow',
      isPrivate: false,
      tags: ['Fantasy', 'Romance', 'Adventure']
    },
    {
      id: '2',
      name: 'Thriller Seekers',
      description: 'For those who love psychological thrillers and suspense. We dive deep into the human psyche.',
      currentBook: 'The Silent Patient',
      memberCount: 8,
      maxMembers: 15,
      personalityTraits: ['Conscientiousness', 'Emotional Stability'],
      meetingTime: 'Every Thursday 8 PM',
      nextMeeting: 'This Thursday',
      isPrivate: false,
      tags: ['Thriller', 'Psychological', 'Mystery']
    },
    {
      id: '3',
      name: 'Self-Development Circle',
      description: 'Focused on personal growth and self-improvement books. Let\'s grow together!',
      currentBook: 'Atomic Habits',
      memberCount: 15,
      maxMembers: 25,
      personalityTraits: ['Conscientiousness', 'Agreeableness'],
      meetingTime: 'Every Sunday 6 PM',
      nextMeeting: 'Next Sunday',
      isPrivate: false,
      tags: ['Self-Help', 'Personal Growth', 'Psychology']
    },
    {
      id: '4',
      name: 'Romance Readers',
      description: 'A warm community for romance lovers. We celebrate love in all its forms.',
      currentBook: 'It Ends with Us',
      memberCount: 18,
      maxMembers: 20,
      personalityTraits: ['Agreeableness', 'Extraversion'],
      meetingTime: 'Every Friday 7:30 PM',
      nextMeeting: 'This Friday',
      isPrivate: false,
      tags: ['Romance', 'Contemporary', 'Drama']
    }
  ];

  // Mock data for discussions
  const discussions: Discussion[] = [
    {
      id: '1',
      bookTitle: 'Fourth Wing',
      author: 'Rebecca Yarros',
      topic: 'Dragon riding scenes - what did you think?',
      participants: 24,
      lastActivity: '2 hours ago',
      tags: ['Fantasy', 'Dragons', 'Action']
    },
    {
      id: '2',
      bookTitle: 'The Silent Patient',
      author: 'Alex Michaelides',
      topic: 'The ending twist - did anyone see it coming?',
      participants: 31,
      lastActivity: '1 hour ago',
      tags: ['Thriller', 'Twist', 'Psychology']
    },
    {
      id: '3',
      bookTitle: 'Atomic Habits',
      author: 'James Clear',
      topic: 'Which habit formation technique worked best for you?',
      participants: 19,
      lastActivity: '3 hours ago',
      tags: ['Self-Help', 'Habits', 'Productivity']
    },
    {
      id: '4',
      bookTitle: 'Lessons in Chemistry',
      author: 'Bonnie Garmus',
      topic: 'Elizabeth Zott\'s character development',
      participants: 15,
      lastActivity: '5 hours ago',
      tags: ['Historical Fiction', 'Feminism', 'Science']
    }
  ];

  const renderPersonalityTags = (traits: string[]) => {
    return traits.map((trait, index) => (
      <span
        key={index}
        className="inline-block bg-gradient-to-r from-purple-500/20 to-pink-500/20 text-purple-300 px-2 py-1 rounded-lg text-xs font-medium mr-2 mb-1"
      >
        {trait}
      </span>
    ));
  };

  const renderTags = (tags: string[]) => {
    return tags.map((tag, index) => (
      <span
        key={index}
        className="inline-block bg-white/10 text-white/80 px-2 py-1 rounded-lg text-xs font-medium mr-2 mb-1"
      >
        {tag}
      </span>
    ));
  };

  return (
    <div className="min-h-screen py-8 px-4 relative overflow-hidden">
      {/* Background Elements */}
      <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900" />
      <div className="absolute top-20 left-20 w-72 h-72 bg-purple-500/10 rounded-full blur-3xl" />
      <div className="absolute bottom-20 right-20 w-96 h-96 bg-pink-500/10 rounded-full blur-3xl" />
      
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
            <Users className="w-4 h-4 text-pink-400" />
            <span className="text-sm font-medium text-white/80">Virtual Book Club</span>
          </div>
          
          <h1 className="text-5xl md:text-6xl font-bold text-white mb-6 leading-tight">
            Tailor <span className="bg-gradient-to-r from-pink-400 to-purple-500 bg-clip-text text-transparent">Mates</span>
          </h1>
          
          <p className="text-xl text-white/70 mb-8 max-w-3xl mx-auto leading-relaxed">
            Connect with readers who share your personality traits. Join book clubs, start discussions, and make friends through the power of books.
          </p>

          {/* CTA for users who haven't completed quiz */}
          {!hasCompletedQuiz && (
            <div className="bg-gradient-to-r from-pink-500/20 to-purple-500/20 backdrop-blur-sm border border-pink-500/30 rounded-2xl p-6 mb-8">
              <div className="flex items-center justify-center space-x-3 mb-4">
                <Sparkles className="w-6 h-6 text-pink-400" />
                <h3 className="text-xl font-bold text-white">Complete Your Personality Quiz</h3>
              </div>
              <p className="text-white/80 mb-4">
                Take our personality quiz to get matched with book clubs and readers who share your traits!
              </p>
              <button
                onClick={onStartQuiz}
                className="bg-gradient-to-r from-pink-500 to-purple-600 hover:from-pink-600 hover:to-purple-700 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105"
              >
                Take Personality Quiz
              </button>
            </div>
          )}
        </div>

        {/* Navigation Tabs */}
        <div className="flex justify-center mb-8">
          <div className="bg-white/10 backdrop-blur-sm border border-white/20 rounded-2xl p-2">
            <div className="flex space-x-2">
              <button
                onClick={() => setActiveTab('clubs')}
                className={`px-6 py-3 rounded-xl font-medium transition-all duration-300 ${
                  activeTab === 'clubs'
                    ? 'bg-gradient-to-r from-pink-500 to-purple-600 text-white'
                    : 'text-white/70 hover:text-white hover:bg-white/10'
                }`}
              >
                <div className="flex items-center space-x-2">
                  <BookOpen className="w-4 h-4" />
                  <span>Book Clubs</span>
                </div>
              </button>
              <button
                onClick={() => setActiveTab('discussions')}
                className={`px-6 py-3 rounded-xl font-medium transition-all duration-300 ${
                  activeTab === 'discussions'
                    ? 'bg-gradient-to-r from-pink-500 to-purple-600 text-white'
                    : 'text-white/70 hover:text-white hover:bg-white/10'
                }`}
              >
                <div className="flex items-center space-x-2">
                  <MessageCircle className="w-4 h-4" />
                  <span>Discussions</span>
                </div>
              </button>
              <button
                onClick={() => setActiveTab('friends')}
                className={`px-6 py-3 rounded-xl font-medium transition-all duration-300 ${
                  activeTab === 'friends'
                    ? 'bg-gradient-to-r from-pink-500 to-purple-600 text-white'
                    : 'text-white/70 hover:text-white hover:bg-white/10'
                }`}
              >
                <div className="flex items-center space-x-2">
                  <UserPlus className="w-4 h-4" />
                  <span>Find Friends</span>
                </div>
              </button>
            </div>
          </div>
        </div>

        {/* Search and Filter */}
        <div className="flex flex-col md:flex-row gap-4 mb-8">
          <div className="flex-1 relative">
            <Search className="absolute left-4 top-1/2 transform -translate-y-1/2 text-white/50 w-5 h-5" />
            <input
              type="text"
              placeholder="Search book clubs, discussions, or friends..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl pl-12 pr-4 py-3 text-white placeholder-white/50 focus:outline-none focus:ring-2 focus:ring-pink-500/50"
            />
          </div>
          <select
            value={selectedFilter}
            onChange={(e) => setSelectedFilter(e.target.value)}
            className="bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl px-4 py-3 text-white focus:outline-none focus:ring-2 focus:ring-pink-500/50"
          >
            <option value="All">All Categories</option>
            <option value="Fantasy">Fantasy</option>
            <option value="Thriller">Thriller</option>
            <option value="Romance">Romance</option>
            <option value="Self-Help">Self-Help</option>
            <option value="Historical Fiction">Historical Fiction</option>
          </select>
        </div>

        {/* Content based on active tab */}
        {activeTab === 'clubs' && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {bookClubs.map((club) => (
              <div
                key={club.id}
                className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6 hover:bg-white/15 transition-all duration-300 group cursor-pointer"
              >
                <div className="flex items-center justify-between mb-4">
                  <div className="flex items-center space-x-2">
                    <BookOpen className="w-5 h-5 text-pink-400" />
                    <h3 className="text-lg font-bold text-white group-hover:text-pink-400 transition-colors">
                      {club.name}
                    </h3>
                  </div>
                  <div className="flex items-center space-x-1 text-white/60 text-sm">
                    <Users className="w-4 h-4" />
                    <span>{club.memberCount}/{club.maxMembers}</span>
                  </div>
                </div>
                
                <p className="text-white/70 text-sm mb-4 line-clamp-2">
                  {club.description}
                </p>
                
                <div className="mb-4">
                  <div className="flex items-center space-x-2 mb-2">
                    <Book className="w-4 h-4 text-amber-400" />
                    <span className="text-white/80 text-sm font-medium">Currently Reading:</span>
                  </div>
                  <p className="text-white font-medium">{club.currentBook}</p>
                </div>
                
                <div className="mb-4">
                  <p className="text-white/60 text-sm mb-2">Personality Traits:</p>
                  <div className="flex flex-wrap">
                    {renderPersonalityTags(club.personalityTraits)}
                  </div>
                </div>
                
                <div className="mb-4">
                  <p className="text-white/60 text-sm mb-2">Tags:</p>
                  <div className="flex flex-wrap">
                    {renderTags(club.tags)}
                  </div>
                </div>
                
                <div className="flex items-center justify-between text-white/60 text-sm mb-4">
                  <span>Next Meeting: {club.nextMeeting}</span>
                  <span>{club.meetingTime}</span>
                </div>
                
                <button className="w-full bg-gradient-to-r from-pink-500 to-purple-600 hover:from-pink-600 hover:to-purple-700 text-white px-4 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105">
                  Join Club
                </button>
              </div>
            ))}
            
            {/* Create New Club Card */}
            <div className="bg-gradient-to-r from-pink-500/20 to-purple-500/20 backdrop-blur-xl border border-pink-500/30 rounded-2xl p-6 hover:bg-pink-500/30 transition-all duration-300 group cursor-pointer">
              <div className="flex flex-col items-center justify-center h-full text-center">
                <div className="w-16 h-16 bg-gradient-to-r from-pink-500 to-purple-600 rounded-full flex items-center justify-center mb-4 group-hover:scale-110 transition-transform">
                  <Plus className="w-8 h-8 text-white" />
                </div>
                <h3 className="text-lg font-bold text-white mb-2">Create Your Own Club</h3>
                <p className="text-white/70 text-sm mb-4">
                  Start a book club and invite readers who share your interests
                </p>
                <button className="bg-white/20 hover:bg-white/30 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300">
                  Create Club
                </button>
              </div>
            </div>
          </div>
        )}

        {activeTab === 'discussions' && (
          <div className="space-y-6">
            {discussions.map((discussion) => (
              <div
                key={discussion.id}
                className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6 hover:bg-white/15 transition-all duration-300 group cursor-pointer"
              >
                <div className="flex items-start justify-between mb-4">
                  <div className="flex-1">
                    <div className="flex items-center space-x-3 mb-2">
                      <MessageCircle className="w-5 h-5 text-pink-400" />
                      <h3 className="text-lg font-bold text-white group-hover:text-pink-400 transition-colors">
                        {discussion.topic}
                      </h3>
                    </div>
                    <p className="text-white/70 text-sm mb-3">
                      Discussing: <span className="text-white font-medium">{discussion.bookTitle}</span> by {discussion.author}
                    </p>
                    <div className="flex flex-wrap mb-4">
                      {renderTags(discussion.tags)}
                    </div>
                  </div>
                  <div className="text-right text-white/60 text-sm">
                    <div className="flex items-center space-x-1 mb-1">
                      <Users className="w-4 h-4" />
                      <span>{discussion.participants} participants</span>
                    </div>
                    <span>{discussion.lastActivity}</span>
                  </div>
                </div>
                
                <button className="bg-gradient-to-r from-pink-500 to-purple-600 hover:from-pink-600 hover:to-purple-700 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105">
                  Join Discussion
                </button>
              </div>
            ))}
            
            {/* Start New Discussion Card */}
            <div className="bg-gradient-to-r from-pink-500/20 to-purple-500/20 backdrop-blur-xl border border-pink-500/30 rounded-2xl p-6 hover:bg-pink-500/30 transition-all duration-300 group cursor-pointer">
              <div className="flex items-center justify-center text-center">
                <div className="w-16 h-16 bg-gradient-to-r from-pink-500 to-purple-600 rounded-full flex items-center justify-center mr-4 group-hover:scale-110 transition-transform">
                  <Plus className="w-8 h-8 text-white" />
                </div>
                <div>
                  <h3 className="text-lg font-bold text-white mb-2">Start a New Discussion</h3>
                  <p className="text-white/70 text-sm mb-4">
                    Share your thoughts and start a conversation about your favorite books
                  </p>
                  <button className="bg-white/20 hover:bg-white/30 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300">
                    Create Discussion
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}

        {activeTab === 'friends' && (
          <div className="text-center py-16">
            <div className="inline-flex items-center justify-center w-20 h-20 bg-gradient-to-r from-pink-500 to-purple-600 rounded-2xl mb-6">
              <UserPlus className="w-10 h-10 text-white" />
            </div>
            <h3 className="text-2xl font-bold text-white mb-4">Find Reading Friends</h3>
            <p className="text-white/70 mb-8 max-w-md mx-auto">
              Connect with readers who share your personality traits and reading preferences. 
              {!hasCompletedQuiz && ' Complete your personality quiz to get started!'}
            </p>
            {!hasCompletedQuiz ? (
              <button
                onClick={onStartQuiz}
                className="bg-gradient-to-r from-pink-500 to-purple-600 hover:from-pink-600 hover:to-purple-700 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105"
              >
                Take Personality Quiz
              </button>
            ) : (
              <div className="space-y-4">
                <button className="bg-gradient-to-r from-pink-500 to-purple-600 hover:from-pink-600 hover:to-purple-700 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105">
                  Browse Readers
                </button>
                <p className="text-white/50 text-sm">
                  Coming soon: Advanced matching based on your personality profile!
                </p>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default TailorMatesPage; 