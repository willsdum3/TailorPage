import React, { useState, useEffect, useRef } from 'react';
import { ArrowLeft, Users, MessageCircle, Send, BookOpen, Calendar, User, Crown, MessageSquare } from 'lucide-react';
import { TailorMatesService } from '../services/tailorMatesService';
import { BookClub } from '../types';

interface BookClubDetailPageProps {
  clubId: string;
  onBack: () => void;
  user: any;
}

const BookClubDetailPage: React.FC<BookClubDetailPageProps> = ({ clubId, onBack, user }) => {
  const [club, setClub] = useState<BookClub | null>(null);
  const [members, setMembers] = useState<any[]>([]);
  const [messages, setMessages] = useState<any[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [isSending, setIsSending] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    loadClubData();
  }, [clubId]);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const loadClubData = async () => {
    try {
      setIsLoading(true);
      
      // Load club details, members, and messages in parallel
      const [clubData, membersData, messagesData] = await Promise.all([
        TailorMatesService.getBookClubDetails(clubId),
        TailorMatesService.getBookClubMembers(clubId),
        TailorMatesService.getBookClubMessages(clubId)
      ]);

      setClub(clubData);
      setMembers(membersData);
      setMessages(messagesData);
    } catch (error) {
      console.error('Error loading club data:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleSendMessage = async () => {
    if (!newMessage.trim() || isSending) return;

    try {
      setIsSending(true);
      const messageId = await TailorMatesService.addBookClubMessage(clubId, newMessage.trim());
      
      if (messageId) {
        setNewMessage('');
        // Reload messages to get the new one
        const updatedMessages = await TailorMatesService.getBookClubMessages(clubId);
        setMessages(updatedMessages);
      }
    } catch (error) {
      console.error('Error sending message:', error);
    } finally {
      setIsSending(false);
    }
  };

  const handleLeaveClub = async () => {
    if (!club) return;
    
    if (window.confirm(`Are you sure you want to leave "${club.name}"?`)) {
      try {
        const success = await TailorMatesService.leaveBookClub(clubId);
        if (success) {
          onBack(); // Go back to the main Tailor Mates page
        }
      } catch (error) {
        console.error('Error leaving club:', error);
        alert('Failed to leave club. Please try again.');
      }
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

  if (isLoading) {
    return (
      <div className="min-h-screen py-8 px-4 relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900" />
        <div className="max-w-4xl mx-auto relative z-10">
          <div className="text-center py-20">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-pink-400 mx-auto"></div>
            <p className="text-white/70 mt-4">Loading book club...</p>
          </div>
        </div>
      </div>
    );
  }

  if (!club) {
    return (
      <div className="min-h-screen py-8 px-4 relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900" />
        <div className="max-w-4xl mx-auto relative z-10">
          <div className="text-center py-20">
            <BookOpen className="w-16 h-16 text-white/30 mx-auto mb-4" />
            <h3 className="text-xl font-bold text-white mb-2">Book Club Not Found</h3>
            <p className="text-white/70 mb-6">This book club may have been deleted or you don't have access to it.</p>
            <button
              onClick={onBack}
              className="bg-gradient-to-r from-pink-500 to-purple-600 hover:from-pink-600 hover:to-purple-700 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300"
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
      
      {/* Back Button */}
      <button
        onClick={onBack}
        className="fixed top-6 left-6 z-50 bg-white/10 backdrop-blur-md border border-white/20 hover:bg-white/20 text-white p-3 rounded-xl transition-all duration-300 transform hover:scale-105"
        aria-label="Go Back"
      >
        <ArrowLeft className="w-6 h-6" />
      </button>

      <div className="max-w-6xl mx-auto relative z-10">
        {/* Header */}
        <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6 mb-6">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center space-x-3">
              <BookOpen className="w-8 h-8 text-pink-400" />
              <h1 className="text-3xl font-bold text-white">{club.name}</h1>
            </div>
            <div className="flex items-center space-x-2 text-white/60">
              <Users className="w-5 h-5" />
              <span>{club.memberCount}/{club.maxMembers} members</span>
            </div>
          </div>
          
          <p className="text-white/80 text-lg mb-4">{club.description}</p>
          
          {club.currentBookTitle && (
            <div className="mb-4">
              <div className="flex items-center space-x-2 mb-2">
                <BookOpen className="w-5 h-5 text-amber-400" />
                <span className="text-white/80 font-medium">Currently Reading:</span>
              </div>
              <p className="text-white text-xl font-semibold">{club.currentBookTitle}</p>
              {club.currentBookAuthor && (
                <p className="text-white/70">by {club.currentBookAuthor}</p>
              )}
            </div>
          )}
          
          <div className="flex flex-wrap gap-4 mb-4">
            <div>
              <p className="text-white/60 text-sm mb-2">Personality Traits:</p>
              <div className="flex flex-wrap">
                {renderPersonalityTags(club.personalityTraits)}
              </div>
            </div>
            <div>
              <p className="text-white/60 text-sm mb-2">Tags:</p>
              <div className="flex flex-wrap">
                {renderTags(club.tags)}
              </div>
            </div>
          </div>
          
          <div className="flex items-center justify-between text-white/60 text-sm">
            <div className="flex items-center space-x-4">
              {club.nextMeetingDate && (
                <div className="flex items-center space-x-1">
                  <Calendar className="w-4 h-4" />
                  <span>Next Meeting: {new Date(club.nextMeetingDate).toLocaleDateString()}</span>
                </div>
              )}
              <div className="flex items-center space-x-1">
                <User className="w-4 h-4" />
                <span>Created by {club.creatorName}</span>
              </div>
            </div>
            <button
              onClick={handleLeaveClub}
              className="bg-red-500/20 hover:bg-red-500/30 border border-red-500/30 text-red-300 px-4 py-2 rounded-xl font-medium transition-all duration-300"
            >
              Leave Club
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Members Section */}
          <div className="lg:col-span-1">
            <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6">
              <h3 className="text-xl font-bold text-white mb-4 flex items-center space-x-2">
                <Users className="w-5 h-5 text-pink-400" />
                <span>Members ({members.length})</span>
              </h3>
              
              <div className="space-y-3">
                {members.map((member) => (
                  <div key={member.user_id} className="flex items-center space-x-3 p-3 bg-white/5 rounded-xl">
                    <div className="w-10 h-10 bg-gradient-to-r from-pink-500 to-purple-600 rounded-full flex items-center justify-center">
                      <User className="w-5 h-5 text-white" />
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center space-x-2">
                        <span className="text-white font-medium">{member.name}</span>
                        {member.role === 'admin' && (
                          <Crown className="w-4 h-4 text-yellow-400" />
                        )}
                      </div>
                      <p className="text-white/60 text-sm">@{member.username}</p>
                    </div>
                    <span className={`px-2 py-1 rounded-lg text-xs font-medium ${
                      member.role === 'admin' 
                        ? 'bg-yellow-500/20 text-yellow-300' 
                        : 'bg-blue-500/20 text-blue-300'
                    }`}>
                      {member.role}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Messages Section */}
          <div className="lg:col-span-2">
            <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6 h-[600px] flex flex-col">
              <h3 className="text-xl font-bold text-white mb-4 flex items-center space-x-2">
                <MessageSquare className="w-5 h-5 text-pink-400" />
                <span>Discussion</span>
              </h3>
              
              {/* Messages */}
              <div className="flex-1 overflow-y-auto mb-4 space-y-4">
                {messages.length === 0 ? (
                  <div className="text-center py-8">
                    <MessageCircle className="w-12 h-12 text-white/30 mx-auto mb-3" />
                    <p className="text-white/60">No messages yet. Start the conversation!</p>
                  </div>
                ) : (
                  messages.map((message) => (
                    <div key={message.id} className="flex space-x-3">
                      <div className="w-8 h-8 bg-gradient-to-r from-pink-500 to-purple-600 rounded-full flex items-center justify-center flex-shrink-0">
                        <User className="w-4 h-4 text-white" />
                      </div>
                      <div className="flex-1">
                        <div className="flex items-center space-x-2 mb-1">
                          <span className="text-white font-medium">{message.name}</span>
                          <span className="text-white/50 text-xs">@{message.username}</span>
                          <span className="text-white/40 text-xs">
                            {new Date(message.created_at).toLocaleString()}
                          </span>
                        </div>
                        <p className="text-white/90 bg-white/5 rounded-lg p-3">{message.content}</p>
                      </div>
                    </div>
                  ))
                )}
                <div ref={messagesEndRef} />
              </div>
              
              {/* Message Input */}
              <div className="flex space-x-3">
                <input
                  type="text"
                  value={newMessage}
                  onChange={(e) => setNewMessage(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && handleSendMessage()}
                  placeholder="Type your message..."
                  className="flex-1 bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl px-4 py-3 text-white placeholder-white/50 focus:outline-none focus:ring-2 focus:ring-pink-500/50"
                  disabled={isSending}
                />
                <button
                  onClick={handleSendMessage}
                  disabled={!newMessage.trim() || isSending}
                  className="bg-gradient-to-r from-pink-500 to-purple-600 hover:from-pink-600 hover:to-purple-700 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105 disabled:opacity-50 disabled:cursor-not-allowed flex items-center space-x-2"
                >
                  <Send className="w-4 h-4" />
                  <span>{isSending ? 'Sending...' : 'Send'}</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default BookClubDetailPage;
