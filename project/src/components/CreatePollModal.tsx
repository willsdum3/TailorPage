import React, { useState } from 'react';
import { X, Plus, BookOpen, Calendar } from 'lucide-react';
import { TailorMatesService } from '../services/tailorMatesService';

interface CreatePollModalProps {
  clubId: string;
  onClose: () => void;
  onPollCreated: () => void;
}

interface BookOption {
  title: string;
  author: string;
  coverUrl?: string;
  description?: string;
}

const CreatePollModal: React.FC<CreatePollModalProps> = ({ 
  clubId, 
  onClose, 
  onPollCreated 
}) => {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [bookOptions, setBookOptions] = useState<BookOption[]>([
    { title: '', author: '', coverUrl: '', description: '' },
    { title: '', author: '', coverUrl: '', description: '' }
  ]);
  const [closesAt, setClosesAt] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  const addBookOption = () => {
    setBookOptions([...bookOptions, { title: '', author: '', coverUrl: '', description: '' }]);
  };

  const removeBookOption = (index: number) => {
    if (bookOptions.length > 2) {
      setBookOptions(bookOptions.filter((_, i) => i !== index));
    }
  };

  const updateBookOption = (index: number, field: keyof BookOption, value: string) => {
    const updated = [...bookOptions];
    updated[index] = { ...updated[index], [field]: value };
    setBookOptions(updated);
  };

  const handleCreatePoll = async () => {
    // Validate inputs
    if (!title.trim()) {
      setMessage({ type: 'error', text: 'Please enter a poll title' });
      return;
    }

    const validOptions = bookOptions.filter(option => 
      option.title.trim() && option.author.trim()
    );

    if (validOptions.length < 2) {
      setMessage({ type: 'error', text: 'Please add at least 2 book options' });
      return;
    }

    setIsLoading(true);
    try {
      const result = await TailorMatesService.createBookSelectionPoll(
        clubId,
        title.trim(),
        description.trim(),
        validOptions,
        closesAt ? new Date(closesAt) : undefined
      );

      setMessage({ type: result.success ? 'success' : 'error', text: result.message });
      
      if (result.success) {
        onPollCreated();
        onClose();
      }
    } catch (error) {
      setMessage({ type: 'error', text: 'Failed to create poll' });
    } finally {
      setIsLoading(false);
    }
  };

  const clearMessage = () => setMessage(null);

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="bg-slate-900 rounded-2xl border border-white/20 w-full max-w-2xl max-h-[90vh] overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-white/10">
          <div className="flex items-center space-x-3">
            <BookOpen className="w-6 h-6 text-pink-400" />
            <h2 className="text-2xl font-bold text-white">Create Book Selection Poll</h2>
          </div>
          <button
            onClick={onClose}
            className="p-2 hover:bg-white/10 rounded-lg transition-colors"
          >
            <X className="w-5 h-5 text-white/60" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6 max-h-[70vh] overflow-y-auto">
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
            {/* Poll Details */}
            <div className="space-y-4">
              <div>
                <label className="block text-white/80 text-sm mb-2">Poll Title *</label>
                <input
                  type="text"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="e.g., Choose our next book for March"
                  className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder-white/50 focus:outline-none focus:border-pink-400"
                />
              </div>
              
              <div>
                <label className="block text-white/80 text-sm mb-2">Description</label>
                <textarea
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  placeholder="Optional description for the poll"
                  rows={3}
                  className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder-white/50 focus:outline-none focus:border-pink-400 resize-none"
                />
              </div>

              <div>
                <label className="block text-white/80 text-sm mb-2">Closes At (Optional)</label>
                <div className="relative">
                  <Calendar className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-white/50" />
                  <input
                    type="datetime-local"
                    value={closesAt}
                    onChange={(e) => setClosesAt(e.target.value)}
                    className="w-full bg-white/10 border border-white/20 rounded-lg pl-10 pr-4 py-3 text-white focus:outline-none focus:border-pink-400"
                  />
                </div>
              </div>
            </div>

            {/* Book Options */}
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <label className="block text-white/80 text-sm">Book Options *</label>
                <button
                  onClick={addBookOption}
                  className="flex items-center space-x-2 text-pink-400 hover:text-pink-300 transition-colors"
                >
                  <Plus className="w-4 h-4" />
                  <span>Add Option</span>
                </button>
              </div>

              {bookOptions.map((option, index) => (
                <div key={index} className="bg-white/5 rounded-lg p-4 space-y-3">
                  <div className="flex items-center justify-between">
                    <span className="text-white/80 text-sm">Option {index + 1}</span>
                    {bookOptions.length > 2 && (
                      <button
                        onClick={() => removeBookOption(index)}
                        className="text-red-400 hover:text-red-300 transition-colors"
                      >
                        <X className="w-4 h-4" />
                      </button>
                    )}
                  </div>
                  
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                    <div>
                      <label className="block text-white/60 text-xs mb-1">Book Title *</label>
                      <input
                        type="text"
                        value={option.title}
                        onChange={(e) => updateBookOption(index, 'title', e.target.value)}
                        placeholder="Book title"
                        className="w-full bg-white/10 border border-white/20 rounded-lg px-3 py-2 text-white placeholder-white/50 focus:outline-none focus:border-pink-400 text-sm"
                      />
                    </div>
                    <div>
                      <label className="block text-white/60 text-xs mb-1">Author *</label>
                      <input
                        type="text"
                        value={option.author}
                        onChange={(e) => updateBookOption(index, 'author', e.target.value)}
                        placeholder="Author name"
                        className="w-full bg-white/10 border border-white/20 rounded-lg px-3 py-2 text-white placeholder-white/50 focus:outline-none focus:border-pink-400 text-sm"
                      />
                    </div>
                  </div>
                  
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                    <div>
                      <label className="block text-white/60 text-xs mb-1">Cover URL</label>
                      <input
                        type="url"
                        value={option.coverUrl || ''}
                        onChange={(e) => updateBookOption(index, 'coverUrl', e.target.value)}
                        placeholder="https://..."
                        className="w-full bg-white/10 border border-white/20 rounded-lg px-3 py-2 text-white placeholder-white/50 focus:outline-none focus:border-pink-400 text-sm"
                      />
                    </div>
                    <div>
                      <label className="block text-white/60 text-xs mb-1">Description</label>
                      <input
                        type="text"
                        value={option.description || ''}
                        onChange={(e) => updateBookOption(index, 'description', e.target.value)}
                        placeholder="Brief description"
                        className="w-full bg-white/10 border border-white/20 rounded-lg px-3 py-2 text-white placeholder-white/50 focus:outline-none focus:border-pink-400 text-sm"
                      />
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="flex items-center justify-end space-x-4 p-6 border-t border-white/10 bg-slate-800/50">
          <button
            onClick={onClose}
            disabled={isLoading}
            className="px-8 py-3 bg-white/10 hover:bg-white/20 border border-white/20 text-white rounded-xl font-medium transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Cancel
          </button>
          <button
            onClick={handleCreatePoll}
            disabled={isLoading}
            className="px-8 py-3 bg-gradient-to-r from-pink-500 to-purple-600 hover:from-pink-600 hover:to-purple-700 disabled:opacity-50 disabled:cursor-not-allowed text-white rounded-xl font-medium transition-all duration-300 transform hover:scale-105 disabled:transform-none"
          >
            {isLoading ? 'Creating...' : 'Create Poll'}
          </button>
        </div>
      </div>
    </div>
  );
};

export default CreatePollModal;
