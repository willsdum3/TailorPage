import React from 'react';
import { X, UserPlus, MessageCircle, UserX, User } from 'lucide-react';

interface UserActionModalProps {
  isOpen: boolean;
  onClose: () => void;
  user: {
    id: string;
    name: string;
    username: string;
    avatarUrl?: string;
  };
  isFriend: boolean;
  onSendFriendRequest: () => void;
  onBlockUser: () => void;
  onSendMessage: () => void;
  isCurrentUser?: boolean;
}

const UserActionModal: React.FC<UserActionModalProps> = ({
  isOpen,
  onClose,
  user,
  isFriend,
  onSendFriendRequest,
  onBlockUser,
  onSendMessage,
  isCurrentUser = false
}) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
      <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6 w-full max-w-md">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-xl font-bold text-white">User Actions</h3>
          <button
            onClick={onClose}
            className="text-white/50 hover:text-white transition-colors"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        {/* User Info */}
        <div className="flex items-center space-x-4 mb-6">
          <div className="w-16 h-16 rounded-full bg-gradient-to-br from-pink-500 to-purple-600 flex items-center justify-center">
            {user.avatarUrl ? (
              <img
                src={user.avatarUrl}
                alt={user.name}
                className="w-16 h-16 rounded-full object-cover"
                onError={(e) => {
                  const target = e.target as HTMLImageElement;
                  target.style.display = 'none';
                  const parent = target.parentElement;
                  if (parent) {
                    parent.innerHTML = `<span class="text-white font-bold text-xl">${user.name.charAt(0).toUpperCase()}</span>`;
                  }
                }}
              />
            ) : (
              <span className="text-white font-bold text-xl">
                {user.name.charAt(0).toUpperCase()}
              </span>
            )}
          </div>
          <div>
            <h4 className="text-white font-medium text-lg">{user.name}</h4>
            <p className="text-white/60">@{user.username}</p>
          </div>
        </div>

        {/* Actions */}
        <div className="space-y-3">
          {isCurrentUser ? (
            <div className="text-center py-4">
              <p className="text-white/70">This is your own profile</p>
            </div>
          ) : (
            <>
              {isFriend ? (
                <>
                  {/* Friend Actions */}
                  <button
                    onClick={() => {
                      onSendMessage();
                      onClose();
                    }}
                    className="w-full bg-gradient-to-r from-blue-500 to-cyan-600 hover:from-blue-600 hover:to-cyan-700 text-white px-4 py-3 rounded-xl font-medium transition-all duration-300 flex items-center justify-center space-x-2"
                  >
                    <MessageCircle className="w-5 h-5" />
                    <span>Send Message</span>
                  </button>
                  
                  <button
                    onClick={() => {
                      onBlockUser();
                      onClose();
                    }}
                    className="w-full bg-red-500/20 hover:bg-red-500/30 border border-red-500/30 text-red-300 px-4 py-3 rounded-xl font-medium transition-all duration-300 flex items-center justify-center space-x-2"
                  >
                    <UserX className="w-5 h-5" />
                    <span>Block User</span>
                  </button>
                </>
              ) : (
                <>
                  {/* Non-Friend Actions */}
                  <button
                    onClick={() => {
                      onSendFriendRequest();
                      onClose();
                    }}
                    className="w-full bg-gradient-to-r from-pink-500 to-purple-600 hover:from-pink-600 hover:to-purple-700 text-white px-4 py-3 rounded-xl font-medium transition-all duration-300 flex items-center justify-center space-x-2"
                  >
                    <UserPlus className="w-5 h-5" />
                    <span>Send Friend Request</span>
                  </button>
                  
                  <button
                    onClick={() => {
                      onBlockUser();
                      onClose();
                    }}
                    className="w-full bg-red-500/20 hover:bg-red-500/30 border border-red-500/30 text-red-300 px-4 py-3 rounded-xl font-medium transition-all duration-300 flex items-center justify-center space-x-2"
                  >
                    <UserX className="w-5 h-5" />
                    <span>Block User</span>
                  </button>
                </>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
};

export default UserActionModal;
