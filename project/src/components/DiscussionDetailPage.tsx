import React, { useState, useEffect, useRef } from 'react';
import { Home, ArrowLeft, MessageCircle, Send, Users, Clock, Book, Tag, User as UserIcon, Trash2, Volume2, VolumeX, X } from 'lucide-react';
import { Discussion, DiscussionMessage, DiscussionParticipant, User as UserType } from '../types';
import { TailorMatesService } from '../services/tailorMatesService';
import AddFriendModal from './AddFriendModal';
import UserActionModal from './UserActionModal';

interface DiscussionDetailPageProps {
  discussionId: string;
  onBack: () => void;
  user: UserType | null;
  onDiscussionDeleted?: () => void;
  onDiscussionLeft?: () => void;
  onNavigateToFriends?: (friendId: string) => Promise<void>;
}

const DiscussionDetailPage: React.FC<DiscussionDetailPageProps> = ({ discussionId, onBack, user, onDiscussionDeleted, onDiscussionLeft, onNavigateToFriends }) => {
  const [discussion, setDiscussion] = useState<Discussion | null>(null);
  const [messages, setMessages] = useState<DiscussionMessage[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [isSending, setIsSending] = useState(false);
  const [isParticipant, setIsParticipant] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const [showAddFriendModal, setShowAddFriendModal] = useState(false);
  const [selectedUserForFriend, setSelectedUserForFriend] = useState<{
    id: string;
    name: string;
    username: string;
    imageUrl?: string;
  } | null>(null);
  
  // User Action Modal state
  const [showUserActionModal, setShowUserActionModal] = useState(false);
  const [selectedUserForAction, setSelectedUserForAction] = useState<{
    id: string;
    name: string;
    username: string;
    avatarUrl?: string;
  } | null>(null);
  
  // Friend connections state
  const [friendConnections, setFriendConnections] = useState<any[]>([]);
  
  // Mute state
  const [isMuted, setIsMuted] = useState<boolean>(false);
  const [isLoadingMuteStatus, setIsLoadingMuteStatus] = useState<boolean>(false);

  // Discussion participants modal state
  const [showParticipantsModal, setShowParticipantsModal] = useState(false);
  const [participants, setParticipants] = useState<DiscussionParticipant[]>([]);
  const [isLoadingParticipants, setIsLoadingParticipants] = useState(false);
  const [participantsError, setParticipantsError] = useState<string | null>(null);

  useEffect(() => {
    loadDiscussion();
    loadFriendConnections();
    loadMuteStatus();
  }, [discussionId, user]);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const loadDiscussion = async () => {
    if (!user) {
      console.log('No user available for loading discussion');
      return;
    }

    try {
      setIsLoading(true);
      
      // Get discussion details and messages
      const [discussions, discussionMessages] = await Promise.all([
        TailorMatesService.getDiscussions(),
        TailorMatesService.getDiscussionMessages(discussionId)
      ]);

      const currentDiscussion = discussions.find(d => d.id === discussionId);
      if (currentDiscussion) {
        setDiscussion(currentDiscussion);
        setIsParticipant(currentDiscussion.isParticipant);
      }

      setMessages(discussionMessages);
    } catch (error) {
      console.error('Error loading discussion:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const loadFriendConnections = async () => {
    try {
      const connections = await TailorMatesService.getFriendConnections();
      setFriendConnections(connections);
    } catch (error) {
      console.error('Error loading friend connections:', error);
      setFriendConnections([]);
    }
  };

  const loadMuteStatus = async () => {
    if (!user || !discussionId) return;
    
    try {
      setIsLoadingMuteStatus(true);
      const status = await TailorMatesService.getDiscussionMuteStatus(discussionId);
      setIsMuted(status);
    } catch (error) {
      console.error('Error loading mute status:', error);
      setIsMuted(false);
    } finally {
      setIsLoadingMuteStatus(false);
    }
  };

  const openParticipantsModal = async () => {
    if (!discussionId) return;

    setShowParticipantsModal(true);
    setParticipantsError(null);
    setIsLoadingParticipants(true);

    try {
      const participantList = await TailorMatesService.getDiscussionParticipants(discussionId);
      setParticipants(participantList);
    } catch (error) {
      console.error('Error loading discussion participants:', error);
      setParticipantsError('Failed to load participants. Please try again.');
    } finally {
      setIsLoadingParticipants(false);
    }
  };

  const closeParticipantsModal = () => {
    setShowParticipantsModal(false);
  };

  const handleToggleMute = async () => {
    if (!user || !discussionId || isLoadingMuteStatus) return;
    
    try {
      setIsLoadingMuteStatus(true);
      const result = await TailorMatesService.toggleDiscussionMute(discussionId);
      if (result.success) {
        setIsMuted(result.isMuted);
      } else {
        alert(result.error || 'Failed to toggle mute status');
      }
    } catch (error) {
      console.error('Error toggling mute:', error);
      alert('Failed to toggle mute status. Please try again.');
    } finally {
      setIsLoadingMuteStatus(false);
    }
  };

  const handleJoinDiscussion = async () => {
    if (!user) {
      alert('Please log in to join the discussion.');
      return;
    }

    // Check if current user is blocked by the discussion creator
    try {
      if (discussion && discussion.createdBy) {
        const isBlocked = await TailorMatesService.isCurrentUserBlockedBy(discussion.createdBy);
        if (isBlocked) {
          alert('You cannot join this discussion. You have been blocked by the discussion creator.');
          return;
        }
      }
    } catch (error) {
      console.error('Error checking blocking status for discussion:', error);
      // Continue with join attempt if blocking check fails
    }

    try {
      const success = await TailorMatesService.joinDiscussion(discussionId);
      
      if (success) {
        // Reload discussion data to get accurate participant status from database
        await loadDiscussion();
        
        // Notify parent component to refresh discussions list
        if (onDiscussionLeft) {
          onDiscussionLeft(); // Reusing this callback for any participation change
        }
      } else {
        alert('Failed to join discussion. Please try again.');
      }
    } catch (error) {
      console.error('Error joining discussion:', error);
      alert('Failed to join discussion. Please try again.');
    }
  };

  const handleLeaveDiscussion = async () => {
    if (!user) {
      alert('Please log in to leave the discussion.');
      return;
    }

    // Confirm before leaving
    if (!confirm('Are you sure you want to leave this discussion? You will no longer be able to send messages unless you rejoin.')) {
      return;
    }

    try {
      const success = await TailorMatesService.leaveDiscussion(discussionId);
      if (success) {
        // Immediate UI update
        setIsParticipant(false);
        
        // Notify parent component to refresh discussions list
        if (onDiscussionLeft) {
          onDiscussionLeft();
        }
        
        // Update local discussion state
        if (discussion) {
          setDiscussion({
            ...discussion,
            participantCount: Math.max(0, discussion.participantCount - 1),
            isParticipant: false
          });
        }
        
        alert('You have left the discussion successfully.');
      } else {
        alert('Unable to leave discussion. You may be the creator of this discussion.');
      }
    } catch (error) {
      console.error('Error leaving discussion:', error);
      alert('Failed to leave discussion. Please try again.');
    }
  };

  const handleDeleteDiscussion = async () => {
    if (!user || !discussion) {
      alert('Please log in to delete the discussion.');
      return;
    }

    // Double confirmation for deletion
    if (!confirm(`Are you sure you want to DELETE this discussion "${discussion.title}"? This action cannot be undone and will remove all messages and participants.`)) {
      return;
    }

    if (!confirm('This will permanently delete the discussion and all its content. Are you absolutely sure?')) {
      return;
    }

    try {
      const result = await TailorMatesService.deleteDiscussion(discussionId);
      if (result.success) {
        // Notify parent component to refresh discussions list
        if (onDiscussionDeleted) {
          onDiscussionDeleted();
        }
        
        alert('Discussion deleted successfully.');
        onBack(); // Navigate back to discussions list
      } else {
        alert(result.error || 'Unable to delete discussion. You may not be the creator.');
      }
    } catch (error) {
      console.error('Error deleting discussion:', error);
      alert('Failed to delete discussion. Please try again.');
    }
  };

  const [currentUserId, setCurrentUserId] = useState<string | null>(null);

  // Get current user ID on component mount
  useEffect(() => {
    const getCurrentUserId = async () => {
      try {
        const userId = await TailorMatesService.getCurrentInternalUserId();
        setCurrentUserId(userId);
      } catch (error) {
        console.error('Error getting current user ID:', error);
      }
    };
    getCurrentUserId();
  }, []);

  const handleUserClick = (userId: string, userName: string, userUsername: string, userImageUrl?: string) => {
    // Don't allow clicking on your own username
    if (userId === currentUserId) {
      return;
    }
    
    // Show the UserActionModal immediately
    setSelectedUserForAction({
      id: userId,
      name: userName,
      username: userUsername,
      avatarUrl: userImageUrl
    });
    setShowUserActionModal(true);
  };

  // User Action Modal handlers
  const handleUserActionSendFriendRequest = async () => {
    if (!selectedUserForAction) return;
    
    try {
      const result = await TailorMatesService.sendFriendRequest(selectedUserForAction.id);
      
      if (result.success) {
        alert('Friend request sent successfully!');
        setShowUserActionModal(false);
        setSelectedUserForAction(null);
        // Refresh friend connections to update the UI
        await loadFriendConnections();
      } else {
        alert(result.error || 'Failed to send friend request. Please try again.');
      }
    } catch (error) {
      console.error('Error sending friend request:', error);
      alert('Failed to send friend request. Please try again.');
    }
  };

  const handleUserActionBlockUser = async () => {
    if (!selectedUserForAction) return;
    
    try {
      const result = await TailorMatesService.blockFriend(selectedUserForAction.id);
      
      if (result.success) {
        alert('User blocked successfully!');
        setShowUserActionModal(false);
        setSelectedUserForAction(null);
        // Refresh friend connections to update the UI
        await loadFriendConnections();
      } else {
        alert(result.error || 'Failed to block user. Please try again.');
      }
    } catch (error) {
      console.error('Error blocking user:', error);
      alert('Failed to block user. Please try again.');
    }
  };

  const handleUserActionSendMessage = async () => {
    console.log('handleUserActionSendMessage called');
    console.log('selectedUserForAction:', selectedUserForAction);
    console.log('onNavigateToFriends available:', !!onNavigateToFriends);
    
    if (!selectedUserForAction) {
      console.log('No selectedUserForAction, returning');
      return;
    }
    
    // Close the modal first
    setShowUserActionModal(false);
    setSelectedUserForAction(null);
    
    // Navigate to Friends tab and open conversation
    if (onNavigateToFriends) {
      console.log('Calling onNavigateToFriends with ID:', selectedUserForAction.id);
      await onNavigateToFriends(selectedUserForAction.id);
    } else {
      console.log('onNavigateToFriends not available');
    }
  };

  const isUserFriend = (userId: string) => {
    return friendConnections.some(friend => 
      friend.friendId === userId && friend.status === 'accepted'
    );
  };

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!newMessage.trim() || !isParticipant || !user) return;

    // Check if current user is blocked by the discussion creator
    try {
      if (discussion && discussion.createdBy) {
        const isBlocked = await TailorMatesService.isCurrentUserBlockedBy(discussion.createdBy);
        if (isBlocked) {
          alert('You cannot send messages to this discussion. You have been blocked by the discussion creator.');
          return;
        }
      }
    } catch (error) {
      console.error('Error checking blocking status for discussion messaging:', error);
      // Continue with message sending if blocking check fails
    }

    try {
      setIsSending(true);
      const messageResult = await TailorMatesService.addDiscussionMessage(discussionId, newMessage.trim());
      
      if (messageResult) {
        setNewMessage('');
        // Reload messages directly like book clubs do
        const updatedMessages = await TailorMatesService.getDiscussionMessages(discussionId);
        setMessages(updatedMessages);
      }
    } catch (error) {
      console.error('Error sending message:', error);
      alert('Failed to send message. Please try again.');
    } finally {
      setIsSending(false);
    }
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

  if (isLoading) {
    return (
      <div className="min-h-screen py-8 px-4 relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900" />
        <div className="max-w-4xl mx-auto relative z-10">
          <div className="text-center py-20">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-pink-400 mx-auto"></div>
            <p className="text-white/70 mt-4">Loading discussion...</p>
          </div>
        </div>
      </div>
    );
  }

  if (!discussion) {
    return (
      <div className="min-h-screen py-8 px-4 relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900" />
        <div className="max-w-4xl mx-auto relative z-10">
          <div className="text-center py-20">
            <p className="text-white/70">Discussion not found</p>
            <button
              onClick={onBack}
              className="mt-4 bg-gradient-to-r from-pink-500 to-purple-600 text-white px-6 py-3 rounded-xl font-medium hover:from-pink-600 hover:to-purple-700 transition-all duration-300"
            >
              Go Back
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
      <div className="absolute bottom-20 right-20 w-96 h-96 bg-pink-500/10 rounded-full blur-3xl" />
      
      {/* Header */}
      <div className="max-w-4xl mx-auto relative z-10">
        <div className="flex items-center justify-between mb-8">
          <button
            onClick={onBack}
            className="flex items-center space-x-2 bg-white/10 backdrop-blur-md border border-white/20 hover:bg-white/20 text-white p-3 rounded-xl transition-all duration-300"
          >
            <ArrowLeft className="w-5 h-5" />
            <span>Back</span>
          </button>
          
          <button
            onClick={() => window.location.href = '/'}
            className="flex items-center space-x-2 bg-white/10 backdrop-blur-md border border-white/20 hover:bg-white/20 text-white p-3 rounded-xl transition-all duration-300"
          >
            <Home className="w-5 h-5" />
            <span>Home</span>
          </button>
        </div>

        {/* Discussion Header */}
        <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6 mb-6">
          <div className="flex items-start justify-between mb-4">
            <div className="flex-1">
              {/* Title and Button Row */}
              <div className="flex items-center mb-2">
                {/* Title on the left */}
                <h1 className="text-2xl font-bold text-white">{discussion.title}</h1>
                
                {/* Button in the center */}
                <div className="flex-1 flex justify-center">
                  {/* Leave Discussion Button (Participants Only) */}
                  {isParticipant && discussion && !discussion.isCreatedByUser && (
                    <button
                      onClick={handleLeaveDiscussion}
                      className="bg-red-500/20 hover:bg-red-500/30 border border-red-500/30 text-red-300 px-4 py-2 rounded-xl font-medium transition-all duration-300 flex items-center space-x-2"
                    >
                      <UserIcon className="w-4 h-4" />
                      <span>Leave Discussion</span>
                    </button>
                  )}
                  {/* Delete Discussion Button (Creator Only) */}
                  {discussion && discussion.isCreatedByUser && (
                    <button
                      onClick={handleDeleteDiscussion}
                      className="bg-red-600/20 hover:bg-red-600/30 border border-red-600/40 text-red-300 px-4 py-2 rounded-xl font-medium transition-all duration-300 flex items-center space-x-2 hover:text-red-200"
                    >
                      <Trash2 className="w-4 h-4" />
                      <span>Delete Discussion</span>
                    </button>
                  )}
                </div>
              </div>
              
              {discussion.bookTitle && (
                <div className="flex items-center space-x-2 mb-3">
                  <Book className="w-4 h-4 text-amber-400" />
                  <span className="text-white/80">
                    Discussing: <span className="text-white font-medium">{discussion.bookTitle}</span>
                    {discussion.bookAuthor && ` by ${discussion.bookAuthor}`}
                  </span>
                </div>
              )}
              
              <div className="flex flex-wrap mb-4">
                {renderTags(discussion.tags)}
              </div>
            </div>
            
            <div className="text-right text-white/60 text-sm">
              <button
                onClick={openParticipantsModal}
                className="flex items-center space-x-1 mb-1 hover:text-white transition-colors"
              >
                <Users className="w-4 h-4" />
                <span>{discussion.participantCount} participants</span>
              </button>
              <div className="flex items-center space-x-1">
                <Clock className="w-4 h-4" />
                <span>{TailorMatesService.formatDate(discussion.lastActivity)}</span>
              </div>
            </div>
          </div>
          
          <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-4 mb-4">
            <p className="text-white/90 leading-relaxed">{discussion.content}</p>
          </div>
          
          <div className="flex items-center justify-between text-white/60 text-sm">
            <span>
              Started by {discussion.creatorName}
              {discussion.creatorUsername && ` @${discussion.creatorUsername}`}
            </span>
            <span>{TailorMatesService.formatDate(discussion.createdAt)}</span>
          </div>
        </div>

        {/* Join Discussion Prompt */}
        {!isParticipant && (
          <div className="bg-gradient-to-r from-pink-500/20 to-purple-500/20 backdrop-blur-sm border border-pink-500/30 rounded-2xl p-6 mb-6">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-lg font-bold text-white mb-2">Join the Discussion</h3>
                <p className="text-white/80">Participate in this conversation and share your thoughts!</p>
              </div>
              <button
                onClick={handleJoinDiscussion}
                className="bg-gradient-to-r from-pink-500 to-purple-600 hover:from-pink-600 hover:to-purple-700 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105"
              >
                Join Discussion
              </button>
            </div>
          </div>
        )}

        {/* Messages */}
        <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-bold text-white flex items-center space-x-2">
              <MessageCircle className="w-5 h-5 text-pink-400" />
              <span>Messages ({messages.length})</span>
            </h2>
            
            {/* Mute Button */}
            <button
              onClick={handleToggleMute}
              disabled={isLoadingMuteStatus}
              className={`p-2 rounded-lg transition-all duration-200 ${
                isMuted 
                  ? 'bg-red-500/20 hover:bg-red-500/30 text-red-400 border border-red-500/30' 
                  : 'bg-white/10 hover:bg-white/20 text-white/80 border border-white/20'
              } ${isLoadingMuteStatus ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}`}
              title={isMuted ? 'Unmute notifications for this discussion' : 'Mute notifications for this discussion'}
            >
              {isMuted ? (
                <VolumeX className="w-5 h-5" />
              ) : (
                <Volume2 className="w-5 h-5" />
              )}
            </button>
          </div>
          
          <div className="space-y-4 mb-6 max-h-96 overflow-y-auto">
            {messages.length === 0 ? (
              <div className="text-center py-8">
                <MessageCircle className="w-12 h-12 text-white/30 mx-auto mb-4" />
                <p className="text-white/60">No messages yet. Be the first to start the conversation!</p>
              </div>
            ) : (
              messages.map((message) => (
                <div key={message.id} className="flex space-x-3">
                  <div className="flex-shrink-0">
                    {message.userImageUrl ? (
                      <img 
                        src={message.userImageUrl} 
                        alt={message.userName || 'User'} 
                        className="w-8 h-8 rounded-full object-cover border border-white/20"
                        onError={(e) => {
                          // Hide broken image and show fallback
                          const target = e.target as HTMLImageElement;
                          target.style.display = 'none';
                          const parent = target.parentElement;
                          if (parent && !parent.querySelector('.avatar-fallback')) {
                            const fallback = document.createElement('div');
                            fallback.className = 'w-8 h-8 bg-gradient-to-r from-pink-500 to-purple-600 rounded-full flex items-center justify-center avatar-fallback';
                            const initial = (message.userName || message.userUsername || 'U').charAt(0).toUpperCase();
                            fallback.innerHTML = `<span class="text-white font-semibold text-xs">${initial}</span>`;
                            parent.appendChild(fallback);
                          }
                        }}
                      />
                    ) : (
                      <div className="w-8 h-8 bg-gradient-to-r from-pink-500 to-purple-600 rounded-full flex items-center justify-center">
                        <span className="text-white font-semibold text-xs">
                          {(message.userName || message.userUsername || 'U').charAt(0).toUpperCase()}
                        </span>
                      </div>
                    )}
                  </div>
                  <div className="flex-1 bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-4">
                    <div className="flex items-center justify-between mb-2">
                      <div className="flex items-center space-x-2">
                        {message.userId === currentUserId ? (
                          <span className="text-white font-medium">
                            {message.userName || 'You'}
                          </span>
                        ) : (
                          <button
                            onClick={() => handleUserClick(message.userId, message.userName || 'User', message.userUsername || '', message.userImageUrl)}
                            className="text-white font-medium hover:text-pink-400 transition-colors cursor-pointer"
                          >
                            {message.userName || 'User'}
                          </button>
                        )}
                        {message.userUsername && (
                          message.userId === currentUserId ? (
                            <span className="text-white/60 text-sm">
                              @{message.userUsername}
                            </span>
                          ) : (
                            <button
                              onClick={() => handleUserClick(message.userId, message.userName || 'User', message.userUsername, message.userImageUrl)}
                              className="text-white/60 hover:text-pink-400/70 text-sm transition-colors cursor-pointer"
                            >
                              @{message.userUsername}
                            </button>
                          )
                        )}
                      </div>
                      <span className="text-white/50 text-sm">
                        {message.createdAt ? TailorMatesService.formatDate(message.createdAt) : ''}
                      </span>
                    </div>
                    {message.content && (
                      <p className="text-white/90 leading-relaxed">{message.content}</p>
                    )}
                  </div>
                </div>
              ))
            )}
            <div ref={messagesEndRef} />
          </div>

          {/* Message Input */}
          {isParticipant && (
            <form onSubmit={handleSendMessage} className="flex space-x-3">
              <input
                type="text"
                value={newMessage}
                onChange={(e) => setNewMessage(e.target.value)}
                placeholder="Type your message..."
                className="flex-1 bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl px-4 py-3 text-white placeholder-white/50 focus:outline-none focus:ring-2 focus:ring-pink-500/50"
                disabled={isSending}
              />
              <button
                type="submit"
                disabled={!newMessage.trim() || isSending}
                className="bg-gradient-to-r from-pink-500 to-purple-600 hover:from-pink-600 hover:to-purple-700 text-white p-3 rounded-xl transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <Send className="w-5 h-5" />
              </button>
            </form>
          )}
        </div>
      </div>

      {/* Participants Modal */}
      {showParticipantsModal && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 px-4">
          <div className="bg-slate-900/90 border border-white/10 rounded-2xl w-full max-w-xl p-6 relative">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-2xl font-bold text-white">
                Discussion Participants
                {!isLoadingParticipants && (
                  <span className="text-white/60 text-sm ml-3">
                    ({participants.length})
                  </span>
                )}
              </h3>
              <button
                onClick={closeParticipantsModal}
                className="p-2 rounded-full bg-white/10 hover:bg-white/20 text-white transition-colors"
                aria-label="Close participants modal"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {participantsError && (
              <div className="bg-red-500/10 border border-red-500/30 text-red-200 px-4 py-2 rounded-xl mb-4">
                {participantsError}
              </div>
            )}

            {isLoadingParticipants ? (
              <div className="text-white/70 text-center py-10">Loading participants...</div>
            ) : participants.length === 0 ? (
              <div className="text-white/70 text-center py-10">
                No participants found for this discussion.
              </div>
            ) : (
              <div className="space-y-3 max-h-96 overflow-y-auto pr-1">
                {participants.map((participant) => (
                  <div
                    key={participant.id}
                    className="flex items-center space-x-3 bg-white/5 border border-white/10 rounded-xl p-3"
                  >
                    {participant.avatarUrl ? (
                      <img
                        src={participant.avatarUrl}
                        alt={participant.name || participant.username || 'Participant'}
                        className="w-12 h-12 rounded-full object-cover border border-white/20"
                        onError={(e) => {
                          const target = e.target as HTMLImageElement;
                          target.style.display = 'none';
                        }}
                      />
                    ) : (
                      <div className="w-12 h-12 rounded-full bg-gradient-to-r from-pink-500 to-purple-600 flex items-center justify-center border border-white/10">
                        <span className="text-white font-semibold text-lg">
                          {(participant.name || participant.username || 'U').charAt(0).toUpperCase()}
                        </span>
                      </div>
                    )}
                    <div>
                      <p className="text-white font-semibold">{participant.name || 'Unknown'}</p>
                      {participant.username && (
                        <p className="text-white/60 text-sm">@{participant.username}</p>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}

      {/* Add Friend Modal */}
      {showAddFriendModal && selectedUserForFriend && (
        <AddFriendModal
          isOpen={showAddFriendModal}
          onClose={() => {
            setShowAddFriendModal(false);
            setSelectedUserForFriend(null);
          }}
          targetUserId={selectedUserForFriend.id}
          targetUserName={selectedUserForFriend.name}
          targetUserUsername={selectedUserForFriend.username}
          targetUserImageUrl={selectedUserForFriend.imageUrl}
          onFriendRequestSent={() => {
            // Optionally refresh friend connections or show success message
          }}
        />
      )}

      {/* User Action Modal */}
      {selectedUserForAction && (
        <UserActionModal
          isOpen={showUserActionModal}
          onClose={() => {
            setShowUserActionModal(false);
            setSelectedUserForAction(null);
          }}
          user={selectedUserForAction}
          isFriend={isUserFriend(selectedUserForAction.id)}
          onSendFriendRequest={handleUserActionSendFriendRequest}
          onBlockUser={handleUserActionBlockUser}
          onSendMessage={handleUserActionSendMessage}
          isCurrentUser={selectedUserForAction.id === currentUserId}
        />
      )}
    </div>
  );
};

export default DiscussionDetailPage;
