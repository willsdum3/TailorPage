import React, { useState } from 'react';
import { X, UserPlus, User as UserIcon } from 'lucide-react';
import { TailorMatesService } from '../services/tailorMatesService';

interface AddFriendModalProps {
  isOpen: boolean;
  onClose: () => void;
  targetUserId: string;
  targetUserName: string;
  targetUserUsername: string;
  targetUserImageUrl?: string;
  onFriendRequestSent?: () => void;
}

const AddFriendModal: React.FC<AddFriendModalProps> = ({
  isOpen,
  onClose,
  targetUserId,
  targetUserName,
  targetUserUsername,
  targetUserImageUrl,
  onFriendRequestSent
}) => {
  const [isLoading, setIsLoading] = useState(false);
  const [message, setMessage] = useState('');

  if (!isOpen) return null;

  const handleSendFriendRequest = async () => {
    try {
      setIsLoading(true);
      
      const result = await TailorMatesService.sendFriendRequest(targetUserId, message || undefined);
      
      if (result.success) {
        alert(`Friend request sent to ${targetUserName}!`);
        if (onFriendRequestSent) {
          onFriendRequestSent();
        }
        onClose();
      } else {
        // Provide helpful error message
        const errorMessage = result.error || 'Failed to send friend request.';
        if (errorMessage.includes('already sent')) {
          alert(`${errorMessage}\n\nYou can cancel it from the "Pending" filter in the Friends section.`);
        } else {
          alert(errorMessage);
        }
      }
    } catch (error) {
      console.error('Error sending friend request:', error);
      alert('Failed to send friend request. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="bg-slate-900 rounded-2xl border border-white/20 w-full max-w-md">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-white/10">
          <h2 className="text-xl font-bold text-white flex items-center space-x-2">
            <UserPlus className="w-5 h-5 text-pink-400" />
            <span>Add Friend</span>
          </h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-white/10 rounded-lg transition-colors"
          >
            <X className="w-5 h-5 text-white/60" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6">
          {/* User Info */}
          <div className="flex items-center space-x-4 mb-6 p-4 bg-white/5 rounded-xl border border-white/10">
            {targetUserImageUrl ? (
              <img 
                src={targetUserImageUrl} 
                alt={targetUserName}
                className="w-12 h-12 rounded-full object-cover"
              />
            ) : (
              <div className="w-12 h-12 bg-gradient-to-r from-pink-500 to-purple-600 rounded-full flex items-center justify-center">
                <UserIcon className="w-6 h-6 text-white" />
              </div>
            )}
            <div>
              <h3 className="text-white font-medium">{targetUserName}</h3>
              <p className="text-white/60 text-sm">@{targetUserUsername}</p>
            </div>
          </div>

          {/* Optional Message */}
          <div className="mb-6">
            <label className="block text-white/80 text-sm font-medium mb-2">
              Message (optional)
            </label>
            <textarea
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              placeholder="Say hello or mention how you know each other..."
              className="w-full bg-white/10 border border-white/20 rounded-xl px-4 py-3 text-white placeholder-white/50 focus:outline-none focus:ring-2 focus:ring-pink-500/50 resize-none"
              rows={3}
              maxLength={200}
            />
            <p className="text-white/40 text-xs mt-1">{message.length}/200 characters</p>
          </div>

          {/* Actions */}
          <div className="flex space-x-3">
            <button
              onClick={onClose}
              className="flex-1 bg-white/10 hover:bg-white/20 border border-white/20 text-white px-4 py-3 rounded-xl font-medium transition-all duration-300"
            >
              Cancel
            </button>
            <button
              onClick={handleSendFriendRequest}
              disabled={isLoading}
              className="flex-1 bg-gradient-to-r from-pink-500 to-purple-600 hover:from-pink-600 hover:to-purple-700 text-white px-4 py-3 rounded-xl font-medium transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center space-x-2"
            >
              {isLoading ? (
                <>
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                  <span>Sending...</span>
                </>
              ) : (
                <>
                  <UserPlus className="w-4 h-4" />
                  <span>Send Friend Request</span>
                </>
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AddFriendModal;
