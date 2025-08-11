import React, { useState, useEffect, useRef } from 'react';
import { Home, ArrowLeft, MessageCircle, Send, Users, Clock, Book, Tag, User as UserIcon } from 'lucide-react';
import { Discussion, DiscussionMessage, User as UserType } from '../types';
import { TailorMatesService } from '../services/tailorMatesService';

interface DiscussionDetailPageProps {
  discussionId: string;
  onBack: () => void;
  user: UserType | null;
}

const DiscussionDetailPage: React.FC<DiscussionDetailPageProps> = ({ discussionId, onBack, user }) => {
  const [discussion, setDiscussion] = useState<Discussion | null>(null);
  const [messages, setMessages] = useState<DiscussionMessage[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [isSending, setIsSending] = useState(false);
  const [isParticipant, setIsParticipant] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    loadDiscussion();
  }, [discussionId]);

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
        TailorMatesService.getDiscussions(user.id),
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

  const handleJoinDiscussion = async () => {
    if (!user) {
      alert('Please log in to join the discussion.');
      return;
    }

    try {
      await TailorMatesService.joinDiscussion(discussionId, user.id);
      setIsParticipant(true);
      await loadDiscussion(); // Refresh to update participant count
    } catch (error) {
      console.error('Error joining discussion:', error);
      alert('Failed to join discussion. Please try again.');
    }
  };

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!newMessage.trim() || !isParticipant || !user) return;

    try {
      setIsSending(true);
      await TailorMatesService.addDiscussionMessage(discussionId, newMessage.trim(), user.id);
      setNewMessage('');
      await loadDiscussion(); // Refresh messages
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
              <h1 className="text-2xl font-bold text-white mb-2">{discussion.title}</h1>
              
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
              <div className="flex items-center space-x-1 mb-1">
                <Users className="w-4 h-4" />
                <span>{discussion.participantCount} participants</span>
              </div>
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
            <span>Started by {discussion.creatorName}</span>
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
          <h2 className="text-xl font-bold text-white mb-6 flex items-center space-x-2">
            <MessageCircle className="w-5 h-5 text-pink-400" />
            <span>Messages ({messages.length})</span>
          </h2>
          
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
                                         <div className="w-8 h-8 bg-gradient-to-r from-pink-500 to-purple-600 rounded-full flex items-center justify-center">
                       <UserIcon className="w-4 h-4 text-white" />
                     </div>
                  </div>
                  <div className="flex-1 bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-4">
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-white font-medium">{message.userName}</span>
                      <span className="text-white/50 text-sm">
                        {TailorMatesService.formatDate(message.createdAt)}
                      </span>
                    </div>
                    <p className="text-white/90 leading-relaxed">{message.content}</p>
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
    </div>
  );
};

export default DiscussionDetailPage;
