import React, { useState } from 'react';
import { X, Send, Lock } from 'lucide-react';

interface JoinRequestModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (message: string) => void;
  isPrivate: boolean;
  clubName: string;
  isSubmitting?: boolean;
}

const JoinRequestModal: React.FC<JoinRequestModalProps> = ({ 
  isOpen, 
  onClose, 
  onSubmit, 
  isPrivate, 
  clubName, 
  isSubmitting = false 
}) => {
  const [message, setMessage] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit(message.trim());
  };

  const handleClose = () => {
    setMessage('');
    onClose();
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="bg-slate-900 rounded-2xl border border-white/20 w-full max-w-md">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-white/10">
          <div className="flex items-center space-x-3">
            <Lock className="w-6 h-6 text-pink-400" />
            <h2 className="text-xl font-bold text-white">
              {isPrivate ? 'Request to Join' : 'Join Club'}
            </h2>
          </div>
          <button
            onClick={handleClose}
            className="p-2 hover:bg-white/10 rounded-lg transition-colors"
          >
            <X className="w-5 h-5 text-white/60" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6">
          <div className="mb-4">
            <h3 className="text-lg font-semibold text-white mb-2">
              {clubName}
            </h3>
            {isPrivate ? (
              <p className="text-white/70 text-sm">
                This is a private club. Your request will be sent to the club admins for approval.
              </p>
            ) : (
              <p className="text-white/70 text-sm">
                You will be added to this public club immediately.
              </p>
            )}
          </div>

          {isPrivate && (
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-white/80 text-sm mb-2">
                  Message (optional)
                </label>
                <textarea
                  value={message}
                  onChange={(e) => setMessage(e.target.value)}
                  placeholder="Tell the admins why you'd like to join..."
                  rows={3}
                  className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder-white/50 focus:outline-none focus:border-pink-400 resize-none"
                />
              </div>
            </form>
          )}
        </div>

        {/* Footer */}
        <div className="flex items-center justify-end space-x-3 p-6 border-t border-white/10">
          <button
            onClick={handleClose}
            className="px-4 py-2 text-white/60 hover:text-white transition-colors"
          >
            Cancel
          </button>
          <button
            onClick={() => onSubmit(message.trim())}
            disabled={isSubmitting}
            className="flex items-center space-x-2 px-4 py-2 bg-pink-500 hover:bg-pink-600 disabled:opacity-50 text-white rounded-lg transition-colors"
          >
            <Send className="w-4 h-4" />
            <span>{isSubmitting ? 'Sending...' : (isPrivate ? 'Send Request' : 'Join Club')}</span>
          </button>
        </div>
      </div>
    </div>
  );
};

export default JoinRequestModal;
