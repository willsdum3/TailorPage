import React, { useState, useEffect, useRef } from 'react';
import { ArrowLeft, Send, Book, Search, Users, MessageCircle, UserX, UserMinus, Plus, Star } from 'lucide-react';
import { FriendConversation, FriendMessage, User as UserType } from '../types';
import { TailorMatesService } from '../services/tailorMatesService';

interface FriendsMessagingPageProps {
  onBack: () => void;
  user: UserType | null;
  selectedFriend?: FriendConnection | null;
}

const FriendsMessagingPage: React.FC<FriendsMessagingPageProps> = ({ onBack, user, selectedFriend }) => {
  const [conversations, setConversations] = useState<FriendConversation[]>([]);
  const [selectedConversation, setSelectedConversation] = useState<FriendConversation | null>(null);
  const [messages, setMessages] = useState<FriendMessage[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [isSending, setIsSending] = useState(false);
  const [currentInternalUserId, setCurrentInternalUserId] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [showBookRecommendation, setShowBookRecommendation] = useState(false);
  const [bookRecommendation, setBookRecommendation] = useState({
    title: '',
    author: '',
    description: '',
    amazonUrl: ''
  });
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    loadConversations();
    // Fetch current user's internal ID for message comparison
    const fetchCurrentInternalUserId = async () => {
      try {
        const internalUserId = await TailorMatesService.getCurrentInternalUserId();
        setCurrentInternalUserId(internalUserId);
      } catch (error) {
        console.error('Error fetching current internal user ID:', error);
      }
    };
    fetchCurrentInternalUserId();
  }, [user]);

  useEffect(() => {
    if (selectedConversation) {
      loadMessages(selectedConversation.id);
    }
  }, [selectedConversation]);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  // Auto-select conversation when a friend is passed from Friends tab
  useEffect(() => {
    if (selectedFriend && conversations.length > 0) {
      const matchingConversation = conversations.find(conv => 
        conv.friendId === selectedFriend.friendId
      );
      if (matchingConversation) {
        setSelectedConversation(matchingConversation);
      }
    }
  }, [selectedFriend, conversations]);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const loadConversations = async () => {
    if (!user) return;
    try {
      setIsLoading(true);
      const conversationsData = await TailorMatesService.getFriendConversations();
      setConversations(conversationsData);
    } catch (error) {
      console.error('Error loading conversations:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const loadMessages = async (conversationId: string) => {
    try {
      const messagesData = await TailorMatesService.getFriendMessages(conversationId);
      setMessages(messagesData);
      
      // Mark conversation as read when loading messages
      await TailorMatesService.markConversationAsRead(conversationId);
      
      // Update conversations state to reflect read status without full reload
      setConversations(prevConversations => 
        prevConversations.map(conv => 
          conv.id === conversationId 
            ? { ...conv, unreadCount: 0 }
            : conv
        )
      );
    } catch (error) {
      console.error('Error loading messages:', error);
    }
  };

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!newMessage.trim() || !selectedConversation || !user || isSending) return;

    try {
      setIsSending(true);
      
      const messageResult = await TailorMatesService.sendFriendMessage(selectedConversation.friendId, newMessage.trim());
      
      if (messageResult) {
        setNewMessage('');
        // Reload messages after sending
        await loadMessages(selectedConversation.id);
        // Update conversations to show new last message without full reload
        setConversations(prevConversations => 
          prevConversations.map(conv => 
            conv.id === selectedConversation.id 
              ? { 
                  ...conv, 
                  lastMessage: messageResult.content,
                  lastMessageAt: messageResult.createdAt,
                  unreadCount: 0
                }
              : conv
          )
        );
      } else {
        alert('Failed to send message. Please try again.');
      }
    } catch (error) {
      console.error('Error sending message:', error);
      alert('Failed to send message. Please try again.');
    } finally {
      setIsSending(false);
    }
  };

  const handleSendBookRecommendation = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!bookRecommendation.title || !bookRecommendation.author || !selectedConversation || !user || isSending) {
      alert('Please fill in at least the book title and author.');
      return;
    }

    try {
      setIsSending(true);
      
      const messageResult = await TailorMatesService.sendBookRecommendation(
        selectedConversation.friendId,
        bookRecommendation.title,
        bookRecommendation.author,
        bookRecommendation.description || undefined,
        bookRecommendation.amazonUrl || undefined
      );
      
      if (messageResult) {
        setBookRecommendation({ title: '', author: '', description: '', amazonUrl: '' });
        setShowBookRecommendation(false);
        // Reload messages after sending
        await loadMessages(selectedConversation.id);
        // Refresh conversations to update last message
        await loadConversations();
      } else {
        alert('Failed to send book recommendation. Please try again.');
      }
    } catch (error) {
      console.error('Error sending book recommendation:', error);
      alert('Failed to send book recommendation. Please try again.');
    } finally {
      setIsSending(false);
    }
  };

  const handleRemoveFriend = async (friendId: string) => {
    if (!confirm('Are you sure you want to remove this friend? This will delete your conversation history.')) {
      return;
    }

    try {
      const result = await TailorMatesService.removeFriend(friendId);
      
      if (result.success) {
        // Refresh conversations
        await loadConversations();
        setSelectedConversation(null);
        setMessages([]);
        alert('Friend removed successfully.');
      } else {
        alert(result.error || 'Failed to remove friend.');
      }
    } catch (error) {
      console.error('Error removing friend:', error);
      alert('Failed to remove friend. Please try again.');
    }
  };

  const handleBlockFriend = async (friendId: string) => {
    if (!confirm('Are you sure you want to block this friend? This will prevent them from messaging you.')) {
      return;
    }

    try {
      const result = await TailorMatesService.blockFriend(friendId);
      
      if (result.success) {
        // Refresh conversations
        await loadConversations();
        setSelectedConversation(null);
        setMessages([]);
        alert('Friend blocked successfully.');
      } else {
        alert(result.error || 'Failed to block friend.');
      }
    } catch (error) {
      console.error('Error blocking friend:', error);
      alert('Failed to block friend. Please try again.');
    }
  };

  const filteredConversations = conversations.filter(conv =>
    conv.friendName.toLowerCase().includes(searchTerm.toLowerCase()) ||
    conv.friendUsername.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="min-h-screen py-8 px-4 relative overflow-hidden">
      {/* Background Elements */}
      <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900" />
      <div className="absolute top-20 left-20 w-72 h-72 bg-purple-500/10 rounded-full blur-3xl" />
      <div className="absolute bottom-20 right-20 w-96 h-96 bg-pink-500/10 rounded-full blur-3xl" />
      
      <div className="max-w-7xl mx-auto relative z-10">
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <button
            onClick={onBack}
            className="flex items-center space-x-2 bg-white/10 backdrop-blur-md border border-white/20 hover:bg-white/20 text-white p-3 rounded-xl transition-all duration-300"
          >
            <ArrowLeft className="w-5 h-5" />
            <span>Back to Friends</span>
          </button>
          
          <h1 className="text-3xl font-bold text-white">Messages</h1>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 h-[calc(100vh-200px)]">
          {/* Conversations List */}
          <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6 flex flex-col">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-xl font-bold text-white flex items-center space-x-2">
                <Users className="w-5 h-5" />
                <span>Conversations</span>
              </h2>
            </div>

            {/* Search */}
            <div className="relative mb-4">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-white/50 w-4 h-4" />
              <input
                type="text"
                placeholder="Search friends..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full bg-white/10 border border-white/20 rounded-xl pl-10 pr-4 py-2 text-white placeholder-white/50 focus:outline-none focus:ring-2 focus:ring-pink-500/50"
              />
            </div>

            {/* Conversations */}
            <div className="flex-1 overflow-y-auto space-y-2">
              {isLoading ? (
                <div className="text-center py-8">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-pink-400 mx-auto"></div>
                  <p className="text-white/60 mt-2">Loading conversations...</p>
                </div>
              ) : filteredConversations.length === 0 ? (
                <div className="text-center py-8">
                  <MessageCircle className="w-12 h-12 text-white/30 mx-auto mb-3" />
                  <p className="text-white/60">No conversations yet</p>
                  <p className="text-white/40 text-sm">Start chatting with your friends!</p>
                </div>
              ) : (
                filteredConversations.map((conversation) => (
                  <div
                    key={conversation.id}
                    onClick={() => setSelectedConversation(conversation)}
                    className={`p-3 rounded-xl cursor-pointer transition-all duration-200 ${
                      selectedConversation?.id === conversation.id
                        ? 'bg-pink-500/20 border border-pink-500/30'
                        : 'bg-white/5 hover:bg-white/10 border border-white/10'
                    }`}
                  >
                    <div className="flex items-center space-x-3">
                      <div className="relative">
                        {conversation.friendImageUrl ? (
                          <img 
                            src={conversation.friendImageUrl} 
                            alt={conversation.friendName}
                            className="w-10 h-10 rounded-full object-cover"
                          />
                        ) : (
                          <div className="w-10 h-10 bg-gradient-to-r from-pink-500 to-purple-600 rounded-full flex items-center justify-center">
                            <span className="text-white text-sm font-medium">
                              {conversation.friendName.charAt(0).toUpperCase()}
                            </span>
                          </div>
                        )}
                        {conversation.isOnline && (
                          <div className="absolute -bottom-1 -right-1 w-3 h-3 bg-green-400 rounded-full border border-slate-900"></div>
                        )}
                      </div>
                      
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center justify-between">
                          <h3 className="text-white font-medium truncate">
                            {conversation.friendName}
                          </h3>
                          {conversation.unreadCount > 0 && (
                            <span className="bg-pink-500 text-white text-xs px-2 py-1 rounded-full">
                              {conversation.unreadCount}
                            </span>
                          )}
                        </div>
                        <p className="text-white/60 text-sm truncate">
                          {conversation.lastMessage || 'No messages yet'}
                        </p>
                        {conversation.lastMessageAt && (
                          <p className="text-white/40 text-xs">
                            {TailorMatesService.formatDate(conversation.lastMessageAt)}
                          </p>
                        )}
                      </div>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>

          {/* Chat Area */}
          <div className="lg:col-span-2 bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl flex flex-col">
            {selectedConversation ? (
              <>
                {/* Chat Header */}
                <div className="p-6 border-b border-white/10">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-3">
                      {selectedConversation.friendImageUrl ? (
                        <img 
                          src={selectedConversation.friendImageUrl} 
                          alt={selectedConversation.friendName}
                          className="w-10 h-10 rounded-full object-cover"
                        />
                      ) : (
                        <div className="w-10 h-10 bg-gradient-to-r from-pink-500 to-purple-600 rounded-full flex items-center justify-center">
                          <span className="text-white font-medium">
                            {selectedConversation.friendName.charAt(0).toUpperCase()}
                          </span>
                        </div>
                      )}
                      <div>
                        <h3 className="text-white font-medium">{selectedConversation.friendName}</h3>
                        <p className="text-white/60 text-sm">@{selectedConversation.friendUsername}</p>
                      </div>
                    </div>
                    
                    <div className="flex space-x-2">
                      <button
                        onClick={() => handleRemoveFriend(selectedConversation.friendId)}
                        className="p-2 bg-red-500/20 hover:bg-red-500/30 border border-red-500/30 text-red-300 rounded-lg transition-colors"
                        title="Remove Friend"
                      >
                        <UserMinus className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => handleBlockFriend(selectedConversation.friendId)}
                        className="p-2 bg-red-600/20 hover:bg-red-600/30 border border-red-600/40 text-red-300 rounded-lg transition-colors"
                        title="Block Friend"
                      >
                        <UserX className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                </div>

                {/* Messages */}
                <div className="flex-1 p-6 overflow-y-auto max-h-96">
                  {messages.length === 0 ? (
                    <div className="text-center py-12">
                      <MessageCircle className="w-16 h-16 text-white/30 mx-auto mb-4" />
                      <p className="text-white/60">No messages yet</p>
                      <p className="text-white/40 text-sm">Start the conversation!</p>
                    </div>
                  ) : (
                    <div className="space-y-4">
                      {messages.map((message) => {
                        const isCurrentUser = message.senderId === currentInternalUserId;
                        console.log('Message debug:', { 
                          messageSenderId: message.senderId, 
                          currentInternalUserId: currentInternalUserId, 
                          isCurrentUser,
                          senderName: message.senderName 
                        });
                        
                        return (
                        <div
                          key={message.id}
                          className={`flex ${isCurrentUser ? 'justify-end' : 'justify-start'}`}
                        >
                          <div className={`max-w-xs lg:max-w-md ${
                            isCurrentUser
                              ? 'bg-gradient-to-r from-blue-500 to-blue-600 text-white'
                              : 'bg-gradient-to-r from-gray-600 to-gray-700 text-white'
                          } rounded-2xl p-4 shadow-lg`}>
                            {message.messageType === 'book_recommendation' && message.bookRecommendation ? (
                              <div className="space-y-3">
                                <div className="flex items-center space-x-2 text-amber-400">
                                  <Book className="w-4 h-4" />
                                  <span className="text-sm font-medium">Book Recommendation</span>
                                </div>
                                <div>
                                  <h4 className="font-medium">{message.bookRecommendation.title}</h4>
                                  <p className="text-sm opacity-80">by {message.bookRecommendation.author}</p>
                                  {message.bookRecommendation.description && (
                                    <p className="text-sm mt-2 opacity-90">{message.bookRecommendation.description}</p>
                                  )}
                                  {message.bookRecommendation.amazonUrl && (
                                    <a
                                      href={message.bookRecommendation.amazonUrl}
                                      target="_blank"
                                      rel="noopener noreferrer"
                                      className="inline-block mt-2 text-sm underline hover:no-underline"
                                    >
                                      View on Amazon
                                    </a>
                                  )}
                                </div>
                              </div>
                            ) : (
                              <p>{message.content}</p>
                            )}
                            <div className="flex justify-between items-center mt-2">
                              <p className="text-xs opacity-60">
                                {isCurrentUser ? 'You' : message.senderName}
                              </p>
                              <p className="text-xs opacity-60 ml-2">
                                {TailorMatesService.formatDate(message.createdAt)}
                              </p>
                            </div>
                          </div>
                        </div>
                        );
                      })}
                      <div ref={messagesEndRef} />
                    </div>
                  )}
                </div>

                {/* Message Input */}
                <div className="p-6 border-t border-white/10">
                  {showBookRecommendation ? (
                    <form onSubmit={handleSendBookRecommendation} className="space-y-3">
                      <div className="flex items-center justify-between">
                        <h4 className="text-white font-medium flex items-center space-x-2">
                          <Book className="w-4 h-4" />
                          <span>Recommend a Book</span>
                        </h4>
                        <button
                          type="button"
                          onClick={() => setShowBookRecommendation(false)}
                          className="text-white/60 hover:text-white"
                        >
                          Cancel
                        </button>
                      </div>
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                        <input
                          type="text"
                          placeholder="Book title *"
                          value={bookRecommendation.title}
                          onChange={(e) => setBookRecommendation({...bookRecommendation, title: e.target.value})}
                          className="bg-white/10 border border-white/20 rounded-xl px-4 py-2 text-white placeholder-white/50 focus:outline-none focus:ring-2 focus:ring-pink-500/50"
                          required
                        />
                        <input
                          type="text"
                          placeholder="Author *"
                          value={bookRecommendation.author}
                          onChange={(e) => setBookRecommendation({...bookRecommendation, author: e.target.value})}
                          className="bg-white/10 border border-white/20 rounded-xl px-4 py-2 text-white placeholder-white/50 focus:outline-none focus:ring-2 focus:ring-pink-500/50"
                          required
                        />
                      </div>
                      <textarea
                        placeholder="Why do you recommend this book? (optional)"
                        value={bookRecommendation.description}
                        onChange={(e) => setBookRecommendation({...bookRecommendation, description: e.target.value})}
                        className="w-full bg-white/10 border border-white/20 rounded-xl px-4 py-2 text-white placeholder-white/50 focus:outline-none focus:ring-2 focus:ring-pink-500/50 resize-none"
                        rows={2}
                      />
                      <input
                        type="url"
                        placeholder="Amazon link (optional)"
                        value={bookRecommendation.amazonUrl}
                        onChange={(e) => setBookRecommendation({...bookRecommendation, amazonUrl: e.target.value})}
                        className="w-full bg-white/10 border border-white/20 rounded-xl px-4 py-2 text-white placeholder-white/50 focus:outline-none focus:ring-2 focus:ring-pink-500/50"
                      />
                      <button
                        type="submit"
                        disabled={isSending || !bookRecommendation.title || !bookRecommendation.author}
                        className="w-full bg-gradient-to-r from-pink-500 to-purple-600 hover:from-pink-600 hover:to-purple-700 text-white py-2 rounded-xl font-medium transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed"
                      >
                        {isSending ? 'Sending...' : 'Send Recommendation'}
                      </button>
                    </form>
                  ) : (
                    <div className="space-y-3">
                      <form onSubmit={handleSendMessage} className="flex space-x-3">
                        <input
                          type="text"
                          value={newMessage}
                          onChange={(e) => setNewMessage(e.target.value)}
                          placeholder="Type your message..."
                          className="flex-1 bg-white/10 border border-white/20 rounded-xl px-4 py-3 text-white placeholder-white/50 focus:outline-none focus:ring-2 focus:ring-pink-500/50"
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
                      <button
                        onClick={() => setShowBookRecommendation(true)}
                        className="flex items-center space-x-2 text-amber-400 hover:text-amber-300 text-sm transition-colors"
                      >
                        <Book className="w-4 h-4" />
                        <span>Recommend a book</span>
                      </button>
                    </div>
                  )}
                </div>
              </>
            ) : (
              <div className="flex-1 flex items-center justify-center">
                <div className="text-center">
                  <MessageCircle className="w-16 h-16 text-white/30 mx-auto mb-4" />
                  <h3 className="text-xl font-medium text-white mb-2">Select a Conversation</h3>
                  <p className="text-white/60">Choose a friend to start messaging</p>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default FriendsMessagingPage;
