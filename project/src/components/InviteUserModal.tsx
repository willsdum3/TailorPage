import React, { useState, useEffect } from 'react';
import { X, Search, UserPlus, Send, Users, AlertCircle, CheckCircle } from 'lucide-react';
import { TailorMatesService } from '../services/tailorMatesService';
import { UserSearchResult } from '../types';

interface InviteUserModalProps {
  isOpen: boolean;
  onClose: () => void;
  clubId: string;
  clubName: string;
  onInviteSent?: () => void;
}

const InviteUserModal: React.FC<InviteUserModalProps> = ({ 
  isOpen, 
  onClose, 
  clubId, 
  clubName,
  onInviteSent 
}) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [searchResults, setSearchResults] = useState<UserSearchResult[]>([]);
  const [isSearching, setIsSearching] = useState(false);
  const [selectedUser, setSelectedUser] = useState<UserSearchResult | null>(null);
  const [inviteMessage, setInviteMessage] = useState('');
  const [isSending, setIsSending] = useState(false);
  const [feedbackMessage, setFeedbackMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  // Search users with debouncing
  useEffect(() => {
    const searchUsers = async () => {
      if (searchTerm.trim().length < 2) {
        setSearchResults([]);
        return;
      }

      setIsSearching(true);
      try {
        const results = await TailorMatesService.searchUsersByUsername(searchTerm);
        console.log('Search results received:', results);
        results.forEach((user, index) => {
          console.log(`User ${index + 1}:`, {
            username: user.username,
            name: user.name,
            avatarUrl: user.avatarUrl,
            hasAvatar: !!user.avatarUrl
          });
        });
        setSearchResults(results);
      } catch (error) {
        console.error('Error searching users:', error);
        setSearchResults([]);
      } finally {
        setIsSearching(false);
      }
    };

    const timeoutId = setTimeout(searchUsers, 300);
    return () => clearTimeout(timeoutId);
  }, [searchTerm]);

  const handleUserSelect = (user: UserSearchResult) => {
    setSelectedUser(user);
    setSearchTerm(user.username);
    setSearchResults([]);
  };

  const handleSendInvite = async () => {
    if (!selectedUser) return;

    setIsSending(true);
    setFeedbackMessage(null);

    try {
      const result = await TailorMatesService.inviteUserToClub(
        clubId,
        selectedUser.username,
        inviteMessage.trim() || undefined
      );

      if (result.success) {
        setFeedbackMessage({
          type: 'success',
          text: `Invitation sent to @${selectedUser.username}!`
        });
        
        // Reset form after successful invite
        setTimeout(() => {
          setSearchTerm('');
          setSelectedUser(null);
          setInviteMessage('');
          setFeedbackMessage(null);
          onInviteSent?.();
        }, 2000);
      } else {
        setFeedbackMessage({
          type: 'error',
          text: result.message
        });
      }
    } catch (error) {
      console.error('Error sending invitation:', error);
      setFeedbackMessage({
        type: 'error',
        text: 'Failed to send invitation. Please try again.'
      });
    } finally {
      setIsSending(false);
    }
  };

  const resetModal = () => {
    setSearchTerm('');
    setSearchResults([]);
    setSelectedUser(null);
    setInviteMessage('');
    setFeedbackMessage(null);
    setIsSending(false);
    setIsSearching(false);
  };

  const handleClose = () => {
    resetModal();
    onClose();
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl max-w-md w-full max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-200">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 bg-gradient-to-r from-blue-500 to-purple-600 rounded-xl flex items-center justify-center">
              <UserPlus className="w-5 h-5 text-white" />
            </div>
            <div>
              <h2 className="text-xl font-bold text-gray-900">Invite User</h2>
              <p className="text-sm text-gray-600">Invite someone to {clubName}</p>
            </div>
          </div>
          <button
            onClick={handleClose}
            className="p-2 hover:bg-gray-100 rounded-xl transition-colors"
          >
            <X className="w-5 h-5 text-gray-500" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6 space-y-6">
          {/* Feedback Message */}
          {feedbackMessage && (
            <div className={`p-4 rounded-xl flex items-center space-x-3 ${
              feedbackMessage.type === 'success' 
                ? 'bg-green-50 text-green-700 border border-green-200' 
                : 'bg-red-50 text-red-700 border border-red-200'
            }`}>
              {feedbackMessage.type === 'success' ? (
                <CheckCircle className="w-5 h-5" />
              ) : (
                <AlertCircle className="w-5 h-5" />
              )}
              <span className="text-sm font-medium">{feedbackMessage.text}</span>
            </div>
          )}

          {/* User Search */}
          <div className="space-y-2">
            <label className="block text-sm font-medium text-gray-700">
              Search by Username
            </label>
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
              <input
                type="text"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder="Enter username to search..."
                className="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                disabled={isSending}
              />
              {isSearching && (
                <div className="absolute right-3 top-1/2 transform -translate-y-1/2">
                  <div className="animate-spin w-4 h-4 border-2 border-blue-500 border-t-transparent rounded-full"></div>
                </div>
              )}
            </div>

            {/* Search Results */}
            {searchResults.length > 0 && !selectedUser && (
              <div className="mt-2 border border-gray-200 rounded-xl bg-white shadow-lg max-h-48 overflow-y-auto">
                {searchResults.map((user) => (
                  <button
                    key={user.id}
                    onClick={() => handleUserSelect(user)}
                    className="w-full p-3 text-left hover:bg-gray-50 flex items-center space-x-3 border-b border-gray-100 last:border-b-0"
                  >
                    {user.avatarUrl ? (
                      <img
                        src={user.avatarUrl}
                        alt={user.name}
                        className="w-8 h-8 rounded-full object-cover"
                        onError={(e) => {
                          console.log('Avatar load error for user:', user.username, 'URL:', user.avatarUrl);
                          // Hide the broken image and show fallback
                          (e.target as HTMLImageElement).style.display = 'none';
                          if ((e.target as HTMLImageElement).nextElementSibling) {
                            ((e.target as HTMLImageElement).nextElementSibling as HTMLElement).style.display = 'flex';
                          }
                        }}
                        onLoad={() => {
                          console.log('Avatar loaded successfully for user:', user.username);
                        }}
                      />
                    ) : (
                      console.log('No avatar URL for user:', user.username, 'avatarUrl:', user.avatarUrl) || null
                    )}
                    <div className={`w-8 h-8 bg-gray-200 rounded-full flex items-center justify-center ${user.avatarUrl ? 'hidden' : ''}`}>
                      <Users className="w-4 h-4 text-gray-500" />
                    </div>
                    <div>
                      <p className="font-medium text-gray-900">@{user.username}</p>
                      <p className="text-sm text-gray-600">{user.name}</p>
                    </div>
                  </button>
                ))}
              </div>
            )}

            {/* Selected User */}
            {selectedUser && (
              <div className="mt-2 p-3 border border-blue-200 bg-blue-50 rounded-xl flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  {selectedUser.avatarUrl ? (
                    <img
                      src={selectedUser.avatarUrl}
                      alt={selectedUser.name}
                      className="w-8 h-8 rounded-full object-cover"
                      onError={(e) => {
                        console.log('Selected user avatar load error:', selectedUser.username, 'URL:', selectedUser.avatarUrl);
                        (e.target as HTMLImageElement).style.display = 'none';
                        if ((e.target as HTMLImageElement).nextElementSibling) {
                          ((e.target as HTMLImageElement).nextElementSibling as HTMLElement).style.display = 'flex';
                        }
                      }}
                      onLoad={() => {
                        console.log('Selected user avatar loaded successfully:', selectedUser.username);
                      }}
                    />
                  ) : (
                    console.log('Selected user has no avatar URL:', selectedUser.username, 'avatarUrl:', selectedUser.avatarUrl) || null
                  )}
                  <div className={`w-8 h-8 bg-blue-200 rounded-full flex items-center justify-center ${selectedUser.avatarUrl ? 'hidden' : ''}`}>
                    <Users className="w-4 h-4 text-blue-600" />
                  </div>
                  <div>
                    <p className="font-medium text-blue-900">@{selectedUser.username}</p>
                    <p className="text-sm text-blue-700">{selectedUser.name}</p>
                  </div>
                </div>
                <button
                  onClick={() => {
                    setSelectedUser(null);
                    setSearchTerm('');
                  }}
                  className="text-blue-600 hover:text-blue-800"
                  disabled={isSending}
                >
                  <X className="w-4 h-4" />
                </button>
              </div>
            )}

            {/* No Results */}
            {searchTerm.length >= 2 && searchResults.length === 0 && !isSearching && !selectedUser && (
              <p className="text-sm text-gray-500 text-center py-4">
                No users found with username "{searchTerm}"
              </p>
            )}
          </div>

          {/* Personal Message */}
          {selectedUser && (
            <div className="space-y-2">
              <label className="block text-sm font-medium text-gray-700">
                Personal Message (Optional)
              </label>
              <textarea
                value={inviteMessage}
                onChange={(e) => setInviteMessage(e.target.value)}
                placeholder="Add a personal message to your invitation..."
                rows={3}
                maxLength={500}
                className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
                disabled={isSending}
              />
              <p className="text-xs text-gray-500 text-right">
                {inviteMessage.length}/500 characters
              </p>
            </div>
          )}

          {/* Send Button */}
          {selectedUser && (
            <button
              onClick={handleSendInvite}
              disabled={isSending}
              className="w-full bg-gradient-to-r from-blue-500 to-purple-600 text-white py-3 px-4 rounded-xl font-medium hover:from-blue-600 hover:to-purple-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center space-x-2 transition-all"
            >
              {isSending ? (
                <>
                  <div className="animate-spin w-4 h-4 border-2 border-white border-t-transparent rounded-full"></div>
                  <span>Sending...</span>
                </>
              ) : (
                <>
                  <Send className="w-4 h-4" />
                  <span>Send Invitation</span>
                </>
              )}
            </button>
          )}

          {/* Instructions */}
          {!selectedUser && searchTerm.length < 2 && (
            <div className="text-center py-8 text-gray-500">
              <Users className="w-12 h-12 mx-auto mb-3 text-gray-300" />
              <p className="text-sm">Start typing a username to search for users to invite</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default InviteUserModal;
