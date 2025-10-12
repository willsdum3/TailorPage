import React, { useState, useEffect } from 'react';
import { X, Save, BookOpen, Calendar, Users } from 'lucide-react';
import { TailorMatesService } from '../services/tailorMatesService';
import { BookClub } from '../types';

interface EditClubModalProps {
  club: BookClub | null;
  onClose: () => void;
  onClubUpdated: () => void;
}

const EditClubModal: React.FC<EditClubModalProps> = ({ 
  club, 
  onClose, 
  onClubUpdated 
}) => {
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    currentBookTitle: '',
    currentBookAuthor: '',
    meetingInfo: ''
  });
  const [isLoading, setIsLoading] = useState(false);
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  useEffect(() => {
    if (club) {
      setFormData({
        name: club.name || '',
        description: club.description || '',
        currentBookTitle: club.currentBookTitle || '',
        currentBookAuthor: club.currentBookAuthor || '',
        meetingInfo: club.meetingInfo || ''
      });
    }
  }, [club]);

  const handleInputChange = (field: keyof typeof formData, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  const handleSave = async () => {
    if (!club) return;

    // Validate required fields
    if (!formData.name.trim()) {
      setMessage({ type: 'error', text: 'Club name is required' });
      return;
    }

    setIsLoading(true);
    try {
      const result = await TailorMatesService.updateBookClubDetails(club.id, {
        name: formData.name.trim(),
        description: formData.description.trim() || undefined,
        currentBookTitle: formData.currentBookTitle.trim() || undefined,
        currentBookAuthor: formData.currentBookAuthor.trim() || undefined,
        meetingInfo: formData.meetingInfo.trim() || undefined
      });

      setMessage({ type: result.success ? 'success' : 'error', text: result.message });
      
      if (result.success) {
        onClubUpdated();
        onClose();
      }
    } catch (error) {
      setMessage({ type: 'error', text: 'Failed to update club details' });
    } finally {
      setIsLoading(false);
    }
  };

  const clearMessage = () => setMessage(null);

  if (!club) return null;

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="bg-slate-900 rounded-2xl border border-white/20 w-full max-w-2xl max-h-[90vh] overflow-hidden flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-white/10 flex-shrink-0">
          <div className="flex items-center space-x-3">
            <BookOpen className="w-6 h-6 text-pink-400" />
            <h2 className="text-2xl font-bold text-white">Edit Club Details</h2>
          </div>
          <button
            onClick={onClose}
            className="p-2 hover:bg-white/10 rounded-lg transition-colors"
          >
            <X className="w-5 h-5 text-white/60" />
          </button>
        </div>

        {/* Content - Scrollable area */}
        <div className="flex-1 overflow-y-auto p-6">
          {message && (
            <div className={`mb-4 p-4 rounded-lg ${
              message.type === 'success' 
                ? 'bg-green-500/20 text-green-300 border border-green-500/30' 
                : 'bg-red-500/20 text-red-300 border border-red-500/30'
            }`}>
              <div className="flex items-center justify-between">
                <span>{message.text}</span>
                <button onClick={clearMessage} className="text-white/60 hover:text-white">
                  <X className="w-4 h-4" />
                </button>
              </div>
            </div>
          )}

          <div className="space-y-6">
            {/* Basic Info */}
            <div className="space-y-4">
              <h3 className="text-lg font-semibold text-white flex items-center space-x-2">
                <Users className="w-5 h-5 text-pink-400" />
                <span>Basic Information</span>
              </h3>
              
              <div>
                <label className="block text-white/80 text-sm mb-2">Club Name *</label>
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) => handleInputChange('name', e.target.value)}
                  placeholder="Enter club name"
                  className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder-white/50 focus:outline-none focus:border-pink-400"
                />
              </div>
              
              <div>
                <label className="block text-white/80 text-sm mb-2">Description</label>
                <textarea
                  value={formData.description}
                  onChange={(e) => handleInputChange('description', e.target.value)}
                  placeholder="Describe your book club"
                  rows={3}
                  className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder-white/50 focus:outline-none focus:border-pink-400 resize-none"
                />
              </div>
            </div>

            {/* Current Book */}
            <div className="space-y-4">
              <h3 className="text-lg font-semibold text-white flex items-center space-x-2">
                <BookOpen className="w-5 h-5 text-pink-400" />
                <span>Current Book</span>
              </h3>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-white/80 text-sm mb-2">Book Title</label>
                  <input
                    type="text"
                    value={formData.currentBookTitle}
                    onChange={(e) => handleInputChange('currentBookTitle', e.target.value)}
                    placeholder="Current book title"
                    className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder-white/50 focus:outline-none focus:border-pink-400"
                  />
                </div>
                <div>
                  <label className="block text-white/80 text-sm mb-2">Author</label>
                  <input
                    type="text"
                    value={formData.currentBookAuthor}
                    onChange={(e) => handleInputChange('currentBookAuthor', e.target.value)}
                    placeholder="Author name"
                    className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder-white/50 focus:outline-none focus:border-pink-400"
                  />
                </div>
              </div>
            </div>

            {/* Meeting Info */}
            <div className="space-y-4">
              <h3 className="text-lg font-semibold text-white flex items-center space-x-2">
                <Calendar className="w-5 h-5 text-pink-400" />
                <span>Meeting Information</span>
              </h3>
              
              <div>
                <label className="block text-white/80 text-sm mb-2">Meeting Details</label>
                <textarea
                  value={formData.meetingInfo}
                  onChange={(e) => handleInputChange('meetingInfo', e.target.value)}
                  placeholder="e.g., Every Tuesday at 7 PM, Location: Community Center"
                  rows={3}
                  className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder-white/50 focus:outline-none focus:border-pink-400 resize-none"
                />
              </div>
            </div>
          </div>
        </div>

        {/* Footer - Fixed at bottom */}
        <div className="flex items-center justify-end space-x-3 p-6 border-t border-white/10 flex-shrink-0">
          <button
            onClick={onClose}
            className="px-6 py-3 text-white/60 hover:text-white transition-colors"
          >
            Cancel
          </button>
          <button
            onClick={handleSave}
            disabled={isLoading}
            className="flex items-center space-x-2 px-6 py-3 bg-pink-500 hover:bg-pink-600 disabled:opacity-50 text-white rounded-lg transition-colors"
          >
            <Save className="w-4 h-4" />
            <span>{isLoading ? 'Saving...' : 'Save Changes'}</span>
          </button>
        </div>
      </div>
    </div>
  );
};

export default EditClubModal;
