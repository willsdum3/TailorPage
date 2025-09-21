import React, { useState, useEffect } from 'react';
import { Home, ArrowLeft, Users, MessageCircle, BookOpen, Heart, Star, Search, Filter, Plus, UserPlus, Book, Sparkles, UserCheck, UserX, Send, User as UserIcon, Clock, Crown } from 'lucide-react';
import { useScrollToTopInstant } from '../hooks/useScrollToTop';
import { TailorMatesService } from '../services/tailorMatesService';
import { BookClub, Discussion, FriendConnection, FriendRecommendation, User, CreateBookClubServiceData } from '../types';
import CreateBookClubModal from './CreateBookClubModal';
import CreateDiscussionModal from './CreateDiscussionModal';
import DiscussionDetailPage from './DiscussionDetailPage';
import BookClubDetailPage from './BookClubDetailPage';
import ClubInvitationsNotifications from './ClubInvitationsNotifications';

interface TailorMatesPageProps {
  onBack: () => void;
  hasCompletedQuiz: boolean;
  onStartQuiz?: () => void;
  user: User | null;
}

const TailorMatesPage: React.FC<TailorMatesPageProps> = ({ onBack, hasCompletedQuiz, onStartQuiz, user }) => {
  const [activeTab, setActiveTab] = useState<'clubs' | 'discussions' | 'friends'>('clubs');
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedFilter, setSelectedFilter] = useState('All');
  
  // Data states
  const [bookClubs, setBookClubs] = useState<BookClub[]>([]);
  const [discussions, setDiscussions] = useState<Discussion[]>([]);
  const [friendConnections, setFriendConnections] = useState<FriendConnection[]>([]);
  const [friendRecommendations, setFriendRecommendations] = useState<FriendRecommendation[]>([]);
  
  // UI states
  const [isLoading, setIsLoading] = useState(true);
  const [showCreateClubModal, setShowCreateClubModal] = useState(false);
  const [showCreateDiscussionModal, setShowCreateDiscussionModal] = useState(false);
  const [selectedDiscussionId, setSelectedDiscussionId] = useState<string | null>(null);
  const [selectedClubId, setSelectedClubId] = useState<string | null>(null);
  
  // Scroll to top when component mounts
  useScrollToTopInstant([]);

  useEffect(() => {
    loadData();
  }, [activeTab, user]);

  const loadDiscussionsData = async () => {
    if (!user) {
      console.log('No user available for loading discussions');
      return;
    }

    try {
      console.log('Loading discussions...');
      const discussionsData = await TailorMatesService.getDiscussions();
      setDiscussions(discussionsData);
      console.log('Loaded discussions:', discussionsData);
      console.log('Discussions state updated:', discussionsData.length, 'discussions');
    } catch (error) {
      console.error('Error loading discussions:', error);
    }
  };

  const loadBookClubsData = async () => {
    if (!user) {
      console.log('No user available for loading book clubs');
      return;
    }

    try {
      console.log('Loading book clubs...');
      const clubs = await TailorMatesService.getBookClubs();
      setBookClubs(clubs);
      console.log('Loaded book clubs:', clubs);
      console.log('Book clubs state updated:', clubs.length, 'clubs');
    } catch (error) {
      console.error('Error loading book clubs:', error);
    }
  };

  const loadData = async () => {
    if (!user) {
      console.log('No user available for loading data');
      return;
    }

    console.log('Loading data for active tab:', activeTab);
    try {
      setIsLoading(true);
      
      // Load data for the current active tab
      if (activeTab === 'clubs') {
        await loadBookClubsData();
      } else if (activeTab === 'discussions') {
        await loadDiscussionsData();
      } else if (activeTab === 'friends') {
        console.log('Loading friends data...');
        const [connections, recommendations] = await Promise.all([
          TailorMatesService.getFriendConnections(),
          TailorMatesService.getFriendRecommendations()
        ]);
        setFriendConnections(connections);
        setFriendRecommendations(recommendations);
        console.log('Loaded friends data:', { connections, recommendations });
      }
    } catch (error) {
      console.error('Error loading data:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleTabChange = (tab: 'clubs' | 'discussions' | 'friends') => {
    console.log('Changing tab to:', tab);
    setActiveTab(tab);
    setSearchTerm('');
    setSelectedFilter('All');
    // loadData will be called automatically by useEffect when activeTab changes
  };

  const handleCreateClub = async (clubData: any) => {
    if (!user) {
      alert('Please log in to create a book club.');
      return;
    }

    try {
      console.log('Attempting to create book club for user:', user.id);
      
      // Map form data to service expected format
      const mappedClubData: CreateBookClubServiceData = {
        name: clubData.name,
        description: clubData.description,
        currentBookTitle: clubData.currentBookTitle,
        currentBookAuthor: clubData.currentBookAuthor,
        maxMembers: clubData.maxMembers,
        isPublic: !clubData.isPrivate, // Convert isPrivate to isPublic
        targetPersonalityTraits: clubData.personalityTraits, // Map personalityTraits to targetPersonalityTraits
        tags: clubData.tags,
        meetingInfo: clubData.meetingTime ? `${clubData.meetingTime}${clubData.nextMeetingDate ? ` - ${clubData.nextMeetingDate}` : ''}` : undefined
      };
      
      await TailorMatesService.createBookClub(mappedClubData);
      await loadBookClubsData(); // Refresh only book clubs list for better performance
    } catch (error: any) {
      console.error('Error creating club:', error);
      // Show more specific error message
      const errorMessage = error.message || 'Failed to create book club. Please try again.';
      alert(errorMessage);
      throw error;
    }
  };

  const handleCreateDiscussion = async (discussionData: any) => {
    if (!user) {
      alert('Please log in to create a discussion.');
      return;
    }

    try {
      await TailorMatesService.createDiscussion(discussionData);
      await loadDiscussionsData(); // Refresh only discussions list for better performance
    } catch (error) {
      console.error('Error creating discussion:', error);
      throw error;
    }
  };

  const handleJoinClub = async (clubId: string) => {
    if (!user) {
      alert('Please log in to join a book club.');
      return;
    }

    try {
      await TailorMatesService.joinBookClub(clubId);
      await loadData(); // Refresh the list
    } catch (error) {
      console.error('Error joining club:', error);
      alert('Failed to join club. Please try again.');
    }
  };

  const handleLeaveClub = async (clubId: string) => {
    if (!user) {
      alert('Please log in to leave a book club.');
      return;
    }

    try {
      await TailorMatesService.leaveBookClub(clubId);
      await loadData(); // Refresh the list
    } catch (error) {
      console.error('Error leaving club:', error);
      alert('Failed to leave club. Please try again.');
    }
  };

  const handleSendFriendRequest = async (friendClerkId: string) => {
    if (!user) {
      alert('Please log in to send friend requests.');
      return;
    }

    try {
      await TailorMatesService.sendFriendRequest(friendClerkId);
      await loadData(); // Refresh the list
    } catch (error) {
      console.error('Error sending friend request:', error);
      alert('Failed to send friend request. Please try again.');
    }
  };

  const handleAcceptFriendRequest = async (friendClerkId: string) => {
    if (!user) {
      alert('Please log in to accept friend requests.');
      return;
    }

    try {
      await TailorMatesService.acceptFriendRequest(friendClerkId);
      await loadData(); // Refresh the list
    } catch (error) {
      console.error('Error accepting friend request:', error);
      alert('Failed to accept friend request. Please try again.');
    }
  };

  const handleGenerateRecommendations = async () => {
    if (!user) {
      alert('Please log in to generate friend recommendations.');
      return;
    }

    try {
      await TailorMatesService.generateFriendRecommendations();
      await loadData(); // Refresh the list
    } catch (error) {
      console.error('Error generating recommendations:', error);
      alert('Failed to generate recommendations. Please try again.');
    }
  };

  const renderPersonalityTags = (traits: string[]) => {
    return traits.map((trait, index) => (
      <span
        key={index}
        className={`inline-block bg-gradient-to-r ${TailorMatesService.getPersonalityTraitColor(trait)} px-2 py-1 rounded-lg text-xs font-medium mr-2 mb-1`}
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

  // Show book club detail page if a club is selected
  if (selectedClubId) {
    return (
      <BookClubDetailPage
        clubId={selectedClubId}
        onBack={() => setSelectedClubId(null)}
        user={user}
        onBookClubDeleted={() => {
          // Refresh book clubs list after deletion
          loadBookClubsData();
        }}
      />
    );
  }

  // Show discussion detail page if a discussion is selected
  if (selectedDiscussionId) {
    return (
      <DiscussionDetailPage
        discussionId={selectedDiscussionId}
        onBack={() => setSelectedDiscussionId(null)}
        user={user}
        onDiscussionDeleted={() => {
          // Refresh discussions list after deletion
          loadDiscussionsData();
        }}
        onDiscussionLeft={() => {
          // Refresh discussions list after leaving
          loadDiscussionsData();
        }}
      />
    );
  }

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

        {/* Club Invitations Notifications */}
        {user && (
          <div className="mb-8">
            <ClubInvitationsNotifications 
              onInvitationResponse={() => {
                // Refresh data after responding to an invitation
                loadData();
              }}
            />
          </div>
        )}

        {/* Navigation Tabs */}
        <div className="flex justify-center mb-8">
          <div className="bg-white/10 backdrop-blur-sm border border-white/20 rounded-2xl p-2">
            <div className="flex space-x-2">
              <button
                onClick={() => handleTabChange('clubs')}
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
                onClick={() => handleTabChange('discussions')}
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
                onClick={() => handleTabChange('friends')}
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
            {isLoading ? (
              <div className="col-span-full text-center py-20">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-pink-400 mx-auto"></div>
                <p className="text-white/70 mt-4">Loading book clubs...</p>
              </div>
            ) : bookClubs.length === 0 ? (
              <div className="col-span-full text-center py-20">
                <BookOpen className="w-16 h-16 text-white/30 mx-auto mb-4" />
                <h3 className="text-xl font-bold text-white mb-2">No Book Clubs Yet</h3>
                <p className="text-white/70 mb-6">Be the first to create a book club!</p>
                <p className="text-white/50 text-sm mb-4">Debug: bookClubs.length = {bookClubs.length}</p>
                <button
                  onClick={() => setShowCreateClubModal(true)}
                  className="bg-gradient-to-r from-pink-500 to-purple-600 hover:from-pink-600 hover:to-purple-700 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300"
                >
                  Create First Club
                </button>
              </div>
            ) : (
              <>
                {bookClubs
                  .sort((a, b) => {
                    // Sort priority: 1. Admin clubs, 2. Member clubs, 3. Other clubs
                    const aIsAdmin = a.userRole === 'admin' || a.userRole === 'owner';
                    const bIsAdmin = b.userRole === 'admin' || b.userRole === 'owner';
                    const aIsMember = a.isMember;
                    const bIsMember = b.isMember;
                    
                    // Admin clubs first
                    if (aIsAdmin && !bIsAdmin) return -1;
                    if (!aIsAdmin && bIsAdmin) return 1;
                    
                    // Then member clubs
                    if (aIsMember && !bIsMember) return -1;
                    if (!aIsMember && bIsMember) return 1;
                    
                    // Finally sort by creation date (newest first)
                    return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
                  })
                  .map((club) => (
                  <div
                    key={club.id}
                    className={`backdrop-blur-xl rounded-2xl p-6 transition-all duration-300 group relative ${
                      club.userRole === 'admin' || club.userRole === 'owner'
                        ? 'bg-gradient-to-br from-amber-500/20 to-orange-500/20 border-2 border-amber-400/50 hover:from-amber-500/30 hover:to-orange-500/30 shadow-lg shadow-amber-500/10'
                        : club.isMember
                        ? 'bg-gradient-to-br from-blue-500/15 to-purple-500/15 border-2 border-blue-400/40 hover:from-blue-500/25 hover:to-purple-500/25'
                        : 'bg-white/10 border border-white/20 hover:bg-white/15'
                    }`}
                  >
                    {/* Admin/Owner Corner Badge */}
                    {(club.userRole === 'admin' || club.userRole === 'owner') && (
                      <div className="absolute top-3 right-3">
                        <div className="bg-gradient-to-r from-amber-400 to-orange-500 text-white p-1.5 rounded-full shadow-lg">
                          <Crown className="w-3 h-3" />
                        </div>
                      </div>
                    )}
                    <div className="flex items-center justify-between mb-4">
                      <div className="flex items-center space-x-2">
                        <BookOpen className={`w-5 h-5 ${
                          club.userRole === 'admin' || club.userRole === 'owner' 
                            ? 'text-amber-400' 
                            : club.isMember 
                            ? 'text-blue-400' 
                            : 'text-pink-400'
                        }`} />
                        <button
                          onClick={() => setSelectedClubId(club.id)}
                          className={`text-lg font-bold transition-colors hover:underline cursor-pointer text-left ${
                            club.userRole === 'admin' || club.userRole === 'owner'
                              ? 'text-amber-100 group-hover:text-amber-300'
                              : club.isMember
                              ? 'text-blue-100 group-hover:text-blue-300'
                              : 'text-white group-hover:text-pink-400'
                          }`}
                        >
                          {club.name}
                        </button>
                        {/* Role Badge */}
                        {(club.userRole === 'admin' || club.userRole === 'owner') && (
                          <div className="flex items-center space-x-1 bg-amber-500/30 border border-amber-400/50 text-amber-200 px-2 py-1 rounded-full text-xs font-medium">
                            <Crown className="w-3 h-3" />
                            <span>{club.userRole === 'owner' ? 'Owner' : 'Admin'}</span>
                          </div>
                        )}
                        {club.isMember && club.userRole === 'member' && (
                          <div className="flex items-center space-x-1 bg-blue-500/30 border border-blue-400/50 text-blue-200 px-2 py-1 rounded-full text-xs font-medium">
                            <UserCheck className="w-3 h-3" />
                            <span>Member</span>
                          </div>
                        )}
                      </div>
                      <div className="flex items-center space-x-1 text-white/60 text-sm">
                        <Users className="w-4 h-4" />
                        <span>{club.memberCount}/{club.maxMembers}</span>
                      </div>
                    </div>
                    
                    <p className="text-white/70 text-sm mb-4 line-clamp-2">
                      {club.description}
                    </p>
                    
                    {club.currentBookTitle && (
                      <div className="mb-4">
                        <div className="flex items-center space-x-2 mb-2">
                          <Book className="w-4 h-4 text-amber-400" />
                          <span className="text-white/80 text-sm font-medium">Currently Reading:</span>
                        </div>
                        <p className="text-white font-medium">{club.currentBookTitle}</p>
                        {club.currentBookAuthor && (
                          <p className="text-white/60 text-sm">by {club.currentBookAuthor}</p>
                        )}
                      </div>
                    )}
                    
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
                      {club.nextMeetingDate && (
                        <span>Next Meeting: {new Date(club.nextMeetingDate).toLocaleDateString()}</span>
                      )}
                      {club.meetingTime && <span>{club.meetingTime}</span>}
                    </div>
                    
                    <div className="flex items-center justify-between text-white/60 text-sm mb-4">
                      <span>Created by {club.creatorName}</span>
                      <span>{TailorMatesService.formatDate(club.createdAt)}</span>
                    </div>
                    
                    {club.isMember ? (
                      <button 
                        onClick={() => handleLeaveClub(club.id)}
                        className="w-full bg-red-500/20 hover:bg-red-500/30 border border-red-500/30 text-red-300 px-4 py-3 rounded-xl font-medium transition-all duration-300"
                      >
                        Leave Club
                      </button>
                    ) : (
                      <button 
                        onClick={() => handleJoinClub(club.id)}
                        disabled={club.memberCount >= club.maxMembers}
                        className="w-full bg-gradient-to-r from-pink-500 to-purple-600 hover:from-pink-600 hover:to-purple-700 text-white px-4 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105 disabled:opacity-50 disabled:cursor-not-allowed"
                      >
                        {club.memberCount >= club.maxMembers ? 'Club Full' : 'Join Club'}
                      </button>
                    )}
                  </div>
                ))}
                
                {/* Create New Club Card */}
                <div 
                  onClick={() => setShowCreateClubModal(true)}
                  className="bg-gradient-to-r from-pink-500/20 to-purple-500/20 backdrop-blur-xl border border-pink-500/30 rounded-2xl p-6 hover:bg-pink-500/30 transition-all duration-300 group cursor-pointer"
                >
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
              </>
            )}
          </div>
        )}

        {activeTab === 'discussions' && (
          <div className="space-y-6">
            {isLoading ? (
              <div className="text-center py-20">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-pink-400 mx-auto"></div>
                <p className="text-white/70 mt-4">Loading discussions...</p>
              </div>
            ) : discussions.length === 0 ? (
              <div className="text-center py-20">
                <MessageCircle className="w-16 h-16 text-white/30 mx-auto mb-4" />
                <h3 className="text-xl font-bold text-white mb-2">No Discussions Yet</h3>
                <p className="text-white/70 mb-6">Be the first to start a discussion!</p>
                <p className="text-white/50 text-sm mb-4">Debug: discussions.length = {discussions.length}</p>
                <button
                  onClick={() => setShowCreateDiscussionModal(true)}
                  className="bg-gradient-to-r from-pink-500 to-purple-600 hover:from-pink-600 hover:to-purple-700 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300"
                >
                  Start First Discussion
                </button>
              </div>
            ) : (
              <>
                {discussions
                  .sort((a, b) => {
                    // Sort priority: 1. Created by user, 2. Participated discussions, 3. Other discussions
                    if (a.isCreatedByUser && !b.isCreatedByUser) return -1;
                    if (!a.isCreatedByUser && b.isCreatedByUser) return 1;
                    
                    // If both/neither created by user, then sort by participation
                    if (a.isParticipant && !b.isParticipant) return -1;
                    if (!a.isParticipant && b.isParticipant) return 1;
                    
                    // Within each group, sort by last activity (most recent first)
                    return new Date(b.lastActivity).getTime() - new Date(a.lastActivity).getTime();
                  })
                  .map((discussion) => (
                  <div
                    key={discussion.id}
                    className={`backdrop-blur-xl rounded-2xl p-6 transition-all duration-300 group cursor-pointer relative ${
                      discussion.isCreatedByUser
                        ? 'bg-gradient-to-br from-amber-500/15 to-orange-500/15 border-2 border-amber-400/40 hover:from-amber-500/25 hover:to-orange-500/25'
                        : discussion.isParticipant
                        ? 'bg-gradient-to-br from-green-500/15 to-emerald-500/15 border-2 border-green-400/40 hover:from-green-500/25 hover:to-emerald-500/25'
                        : 'bg-white/10 border border-white/20 hover:bg-white/15'
                    }`}
                    onClick={() => setSelectedDiscussionId(discussion.id)}
                  >
                    {/* Creator Badge */}
                    {discussion.isCreatedByUser && (
                      <div className="absolute top-3 right-3">
                        <div className="bg-gradient-to-r from-amber-400 to-orange-500 text-white p-1.5 rounded-full shadow-lg">
                          <UserIcon className="w-3 h-3" />
                        </div>
                      </div>
                    )}
                    {/* Participant Badge */}
                    {discussion.isParticipant && !discussion.isCreatedByUser && (
                      <div className="absolute top-3 right-3">
                        <div className="bg-gradient-to-r from-green-400 to-emerald-500 text-white p-1.5 rounded-full shadow-lg">
                          <MessageCircle className="w-3 h-3" />
                        </div>
                      </div>
                    )}
                    <div className="flex items-start justify-between mb-4">
                      <div className="flex-1">
                        <div className="flex items-center space-x-3 mb-2">
                          <MessageCircle className={`w-5 h-5 ${
                            discussion.isCreatedByUser 
                              ? 'text-amber-400' 
                              : discussion.isParticipant 
                              ? 'text-green-400' 
                              : 'text-pink-400'
                          }`} />
                          <h3 className={`text-lg font-bold transition-colors ${
                            discussion.isCreatedByUser
                              ? 'text-amber-100 group-hover:text-amber-300'
                              : discussion.isParticipant 
                              ? 'text-green-100 group-hover:text-green-300' 
                              : 'text-white group-hover:text-pink-400'
                          }`}>
                            {discussion.title}
                          </h3>
                          {discussion.isParticipant && (
                            <div className="flex items-center space-x-1 bg-green-500/30 border border-green-400/50 text-green-200 px-2 py-1 rounded-full text-xs font-medium">
                              <UserCheck className="w-3 h-3" />
                              <span>Participating</span>
                            </div>
                          )}
                        </div>
                        {discussion.bookTitle && (
                          <p className="text-white/70 text-sm mb-3">
                            Discussing: <span className="text-white font-medium">{discussion.bookTitle}</span>
                            {discussion.bookAuthor && ` by ${discussion.bookAuthor}`}
                          </p>
                        )}
                        <div className="flex flex-wrap mb-4">
                          {renderTags(discussion.tags)}
                        </div>
                      </div>
                      <div className="text-right text-white/60 text-sm">
                        <div className="flex items-center space-x-1 mb-1">
                          <Users className="w-4 h-4" />
                          <span>{discussion.participantCount} participants</span>
                        </div>
                        <span>{TailorMatesService.formatDate(discussion.lastActivity)}</span>
                      </div>
                    </div>
                    
                    <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-4 mb-4">
                      <p className="text-white/90 leading-relaxed line-clamp-2">{discussion.content}</p>
                    </div>
                    
                    <div className="flex items-center justify-between text-white/60 text-sm">
                      <span>
                        Started by {discussion.creatorName}
                        {discussion.creatorUsername && ` @${discussion.creatorUsername}`}
                      </span>
                      <span>{TailorMatesService.formatDate(discussion.createdAt)}</span>
                    </div>
                    
                    <button className="w-full mt-4 bg-gradient-to-r from-pink-500 to-purple-600 hover:from-pink-600 hover:to-purple-700 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105">
                      {discussion.isParticipant ? 'View Discussion' : 'Join Discussion'}
                    </button>
                  </div>
                ))}
                
                {/* Start New Discussion Card */}
                <div 
                  onClick={() => setShowCreateDiscussionModal(true)}
                  className="bg-gradient-to-r from-pink-500/20 to-purple-500/20 backdrop-blur-xl border border-pink-500/30 rounded-2xl p-6 hover:bg-pink-500/30 transition-all duration-300 group cursor-pointer"
                >
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
              </>
            )}
          </div>
        )}

        {activeTab === 'friends' && (
          <div className="space-y-8">
            {isLoading ? (
              <div className="text-center py-20">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-pink-400 mx-auto"></div>
                <p className="text-white/70 mt-4">Loading friends...</p>
              </div>
            ) : (
              <>
                {/* Friend Connections */}
                <div>
                  <h3 className="text-2xl font-bold text-white mb-6 flex items-center space-x-2">
                    <UserCheck className="w-6 h-6 text-green-400" />
                    <span>Your Friends ({friendConnections.filter(f => f.status === 'accepted').length})</span>
                  </h3>
                  
                  {friendConnections.filter(f => f.status === 'accepted').length === 0 ? (
                    <div className="text-center py-12 bg-white/5 backdrop-blur-sm border border-white/10 rounded-2xl">
                      <UserCheck className="w-16 h-16 text-white/30 mx-auto mb-4" />
                      <p className="text-white/70 mb-4">You haven't connected with any friends yet.</p>
                      <p className="text-white/50 text-sm">Check out the recommendations below to find reading buddies!</p>
                    </div>
                  ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                      {friendConnections
                        .filter(f => f.status === 'accepted')
                        .map((friend) => (
                          <div key={friend.id} className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-4">
                            <div className="flex items-center space-x-3 mb-3">
                              <div className="w-12 h-12 bg-gradient-to-r from-pink-500 to-purple-600 rounded-full flex items-center justify-center">
                                <UserIcon className="w-6 h-6 text-white" />
                              </div>
                              <div className="flex-1">
                                <h4 className="text-white font-medium">{friend.friendName}</h4>
                                <p className="text-white/60 text-sm">@{friend.friendUsername}</p>
                              </div>
                            </div>
                            <div className="flex items-center justify-between text-sm">
                              <span className={`${TailorMatesService.getMatchScoreColor(friend.personalityMatchScore)} font-medium`}>
                                {Math.round(friend.personalityMatchScore * 100)}% Match
                              </span>
                              <span className="text-white/50">
                                {TailorMatesService.formatDate(friend.createdAt)}
                              </span>
                            </div>
                          </div>
                        ))}
                    </div>
                  )}
                </div>

                {/* Pending Friend Requests */}
                {friendConnections.filter(f => f.status === 'pending').length > 0 && (
                  <div>
                    <h3 className="text-xl font-bold text-white mb-4 flex items-center space-x-2">
                      <Clock className="w-5 h-5 text-yellow-400" />
                      <span>Pending Requests ({friendConnections.filter(f => f.status === 'pending').length})</span>
                    </h3>
                    <div className="space-y-3">
                      {friendConnections
                        .filter(f => f.status === 'pending')
                        .map((friend) => (
                          <div key={friend.id} className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-4">
                            <div className="flex items-center justify-between">
                              <div className="flex items-center space-x-3">
                                <div className="w-10 h-10 bg-gradient-to-r from-pink-500 to-purple-600 rounded-full flex items-center justify-center">
                                  <UserIcon className="w-5 h-5 text-white" />
                                </div>
                                <div>
                                  <h4 className="text-white font-medium">{friend.friendName}</h4>
                                  <p className="text-white/60 text-sm">@{friend.friendUsername}</p>
                                </div>
                              </div>
                              <div className="flex space-x-2">
                                <button
                                  onClick={() => handleAcceptFriendRequest(friend.friendId)}
                                  className="bg-green-500/20 hover:bg-green-500/30 border border-green-500/30 text-green-300 px-3 py-1 rounded-lg text-sm transition-colors"
                                >
                                  Accept
                                </button>
                                <button className="bg-red-500/20 hover:bg-red-500/30 border border-red-500/30 text-red-300 px-3 py-1 rounded-lg text-sm transition-colors">
                                  Decline
                                </button>
                              </div>
                            </div>
                          </div>
                        ))}
                    </div>
                  </div>
                )}

                {/* Friend Recommendations */}
                <div>
                  <div className="flex items-center justify-between mb-6">
                    <h3 className="text-2xl font-bold text-white flex items-center space-x-2">
                      <Sparkles className="w-6 h-6 text-amber-400" />
                      <span>Recommended Friends ({friendRecommendations.length})</span>
                    </h3>
                    <button
                      onClick={handleGenerateRecommendations}
                      className="bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white px-4 py-2 rounded-xl font-medium transition-all duration-300"
                    >
                      Refresh
                    </button>
                  </div>
                  
                  {!hasCompletedQuiz ? (
                    <div className="text-center py-12 bg-gradient-to-r from-pink-500/20 to-purple-500/20 backdrop-blur-sm border border-pink-500/30 rounded-2xl">
                      <Sparkles className="w-16 h-16 text-pink-400 mx-auto mb-4" />
                      <h4 className="text-xl font-bold text-white mb-2">Complete Your Personality Quiz</h4>
                      <p className="text-white/80 mb-4">
                        Take our personality quiz to get matched with readers who share your traits!
                      </p>
                      <button
                        onClick={onStartQuiz}
                        className="bg-gradient-to-r from-pink-500 to-purple-600 hover:from-pink-600 hover:to-purple-700 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300"
                      >
                        Take Personality Quiz
                      </button>
                    </div>
                  ) : friendRecommendations.length === 0 ? (
                    <div className="text-center py-12 bg-white/5 backdrop-blur-sm border border-white/10 rounded-2xl">
                      <Sparkles className="w-16 h-16 text-white/30 mx-auto mb-4" />
                      <p className="text-white/70 mb-4">No recommendations available.</p>
                      <button
                        onClick={handleGenerateRecommendations}
                        className="bg-gradient-to-r from-pink-500 to-purple-600 hover:from-pink-600 hover:to-purple-700 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300"
                      >
                        Generate Recommendations
                      </button>
                    </div>
                  ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                      {friendRecommendations.map((recommendation) => (
                        <div key={recommendation.id} className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-4">
                          <div className="flex items-center space-x-3 mb-3">
                            <div className="w-12 h-12 bg-gradient-to-r from-pink-500 to-purple-600 rounded-full flex items-center justify-center">
                              <UserIcon className="w-6 h-6 text-white" />
                            </div>
                            <div className="flex-1">
                              <h4 className="text-white font-medium">{recommendation.recommendedUserName}</h4>
                              <p className="text-white/60 text-sm">@{recommendation.recommendedUserUsername}</p>
                            </div>
                          </div>
                          
                          <div className="mb-3">
                            <div className="flex items-center justify-between text-sm mb-2">
                              <span className={`${TailorMatesService.getMatchScoreColor(recommendation.matchScore)} font-medium`}>
                                {Math.round(recommendation.matchScore * 100)}% Match
                              </span>
                              <span className="text-white/50">
                                {TailorMatesService.getMatchScoreLabel(recommendation.matchScore)}
                              </span>
                            </div>
                            
                            {recommendation.matchReasons.length > 0 && (
                              <div className="space-y-1">
                                {recommendation.matchReasons
                                  .filter(reason => reason)
                                  .slice(0, 2)
                                  .map((reason, index) => (
                                    <p key={index} className="text-white/70 text-xs">• {reason}</p>
                                  ))}
                              </div>
                            )}
                          </div>
                          
                          <button
                            onClick={() => handleSendFriendRequest(recommendation.recommendedUserId)}
                            className="w-full bg-gradient-to-r from-pink-500 to-purple-600 hover:from-pink-600 hover:to-purple-700 text-white px-4 py-2 rounded-xl font-medium transition-all duration-300"
                          >
                            Send Friend Request
                          </button>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </>
            )}
          </div>
        )}
      </div>

      {/* Modals */}
      <CreateBookClubModal
        isOpen={showCreateClubModal}
        onClose={() => setShowCreateClubModal(false)}
        onSubmit={handleCreateClub}
      />
      
      <CreateDiscussionModal
        isOpen={showCreateDiscussionModal}
        onClose={() => setShowCreateDiscussionModal(false)}
        onSubmit={handleCreateDiscussion}
      />

    </div>
  );
};

export default TailorMatesPage; 