import React, { useState } from 'react';
import { X, MessageCircle, Book, Tag, Plus } from 'lucide-react';
import { CreateDiscussionData } from '../types';

interface CreateDiscussionModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (discussionData: CreateDiscussionData) => Promise<void>;
}

const DISCUSSION_TAGS = [
  'Book Review', 'Character Analysis', 'Plot Discussion', 'Themes', 'Writing Style',
  'Ending Discussion', 'Spoilers', 'Recommendations', 'Author Discussion', 'Genre Talk',
  'Reading Experience', 'Quotes', 'Adaptations', 'Historical Context', 'Philosophy',
  'Psychology', 'Social Issues', 'Personal Growth', 'Entertainment', 'Education'
];

const CreateDiscussionModal: React.FC<CreateDiscussionModalProps> = ({ isOpen, onClose, onSubmit }) => {
  const [formData, setFormData] = useState<CreateDiscussionData>({
    title: '',
    content: '',
    bookTitle: '',
    bookAuthor: '',
    tags: []
  });

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [customTag, setCustomTag] = useState('');

  const handleInputChange = (field: keyof CreateDiscussionData, value: any) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  const handleTagToggle = (tag: string) => {
    setFormData(prev => ({
      ...prev,
      tags: prev.tags.includes(tag)
        ? prev.tags.filter(t => t !== tag)
        : [...prev.tags, tag]
    }));
  };

  const addCustomTag = () => {
    if (customTag.trim() && !formData.tags.includes(customTag.trim())) {
      handleTagToggle(customTag.trim());
      setCustomTag('');
    }
  };

  const removeTag = (tag: string) => {
    setFormData(prev => ({
      ...prev,
      tags: prev.tags.filter(t => t !== tag)
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!formData.title.trim() || !formData.content.trim()) {
      alert('Please fill in all required fields');
      return;
    }

    if (formData.tags.length === 0) {
      alert('Please select at least one tag');
      return;
    }

    setIsSubmitting(true);
    try {
      await onSubmit(formData);
      onClose();
      setFormData({
        title: '',
        content: '',
        bookTitle: '',
        bookAuthor: '',
        tags: []
      });
    } catch (error) {
      console.error('Error creating discussion:', error);
      alert('Failed to create discussion. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-200">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 bg-gradient-to-r from-pink-500 to-purple-600 rounded-xl flex items-center justify-center">
              <MessageCircle className="w-5 h-5 text-white" />
            </div>
            <div>
              <h2 className="text-xl font-bold text-gray-900">Start Discussion</h2>
              <p className="text-sm text-gray-600">Share your thoughts with the community</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-100 rounded-xl transition-colors"
          >
            <X className="w-5 h-5 text-gray-500" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          {/* Discussion Title */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Discussion Title *
            </label>
            <input
              type="text"
              value={formData.title}
              onChange={(e) => handleInputChange('title', e.target.value)}
              className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-pink-500 focus:border-transparent"
              placeholder="What would you like to discuss?"
              required
            />
          </div>

          {/* Book Information */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Book Title
              </label>
              <input
                type="text"
                value={formData.bookTitle}
                onChange={(e) => handleInputChange('bookTitle', e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-pink-500 focus:border-transparent"
                placeholder="Book title (optional)"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Author
              </label>
              <input
                type="text"
                value={formData.bookAuthor}
                onChange={(e) => handleInputChange('bookAuthor', e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-pink-500 focus:border-transparent"
                placeholder="Author name (optional)"
              />
            </div>
          </div>

          {/* Discussion Content */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Discussion Content *
            </label>
            <textarea
              value={formData.content}
              onChange={(e) => handleInputChange('content', e.target.value)}
              rows={6}
              className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-pink-500 focus:border-transparent"
              placeholder="Share your thoughts, questions, or insights. What would you like to discuss with other readers?"
              required
            />
            <p className="text-sm text-gray-500 mt-2">
              Be respectful and constructive in your discussion. This helps create a positive community environment.
            </p>
          </div>

          {/* Tags */}
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Discussion Tags *
              </label>
              <p className="text-sm text-gray-600 mb-3">Select tags that describe your discussion topic</p>
            </div>
            
            <div className="grid grid-cols-3 gap-2">
              {DISCUSSION_TAGS.map((tag) => (
                <button
                  key={tag}
                  type="button"
                  onClick={() => handleTagToggle(tag)}
                  className={`p-2 rounded-lg border text-xs font-medium transition-colors ${
                    formData.tags.includes(tag)
                      ? 'bg-purple-50 border-purple-200 text-purple-700'
                      : 'bg-gray-50 border-gray-200 text-gray-700 hover:bg-gray-100'
                  }`}
                >
                  {tag}
                </button>
              ))}
            </div>

            {/* Custom Tag */}
            <div className="flex space-x-2">
              <input
                type="text"
                value={customTag}
                onChange={(e) => setCustomTag(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), addCustomTag())}
                className="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                placeholder="Add custom tag"
              />
              <button
                type="button"
                onClick={addCustomTag}
                className="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
              >
                Add
              </button>
            </div>

            {/* Selected Tags */}
            {formData.tags.length > 0 && (
              <div className="flex flex-wrap gap-2">
                {formData.tags.map((tag) => (
                  <span
                    key={tag}
                    className="inline-flex items-center space-x-1 bg-purple-100 text-purple-700 px-3 py-1 rounded-full text-sm"
                  >
                    <span>{tag}</span>
                    <button
                      type="button"
                      onClick={() => removeTag(tag)}
                      className="hover:text-purple-900"
                    >
                      <X className="w-3 h-3" />
                    </button>
                  </span>
                ))}
              </div>
            )}
          </div>

          {/* Guidelines */}
          <div className="bg-blue-50 border border-blue-200 rounded-xl p-4">
            <h4 className="text-sm font-semibold text-blue-900 mb-2">Discussion Guidelines</h4>
            <ul className="text-sm text-blue-800 space-y-1">
              <li>• Be respectful and constructive in your comments</li>
              <li>• Avoid spoilers unless clearly marked</li>
              <li>• Stay on topic and relevant to the discussion</li>
              <li>• Encourage diverse perspectives and opinions</li>
              <li>• Report inappropriate content to moderators</li>
            </ul>
          </div>

          {/* Submit Button */}
          <div className="flex space-x-3 pt-4 border-t border-gray-200">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-6 py-3 border border-gray-300 text-gray-700 rounded-xl font-medium hover:bg-gray-50 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="flex-1 px-6 py-3 bg-gradient-to-r from-pink-500 to-purple-600 text-white rounded-xl font-medium hover:from-pink-600 hover:to-purple-700 transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isSubmitting ? 'Creating...' : 'Start Discussion'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default CreateDiscussionModal;
