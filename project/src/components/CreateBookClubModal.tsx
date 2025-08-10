import React, { useState } from 'react';
import { X, BookOpen, Users, Calendar, Lock, Unlock, Tag, Plus, Minus } from 'lucide-react';
import { CreateBookClubData } from '../types';

interface CreateBookClubModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (clubData: CreateBookClubData) => Promise<void>;
}

const PERSONALITY_TRAITS = [
  'Openness',
  'Conscientiousness', 
  'Extraversion',
  'Agreeableness',
  'Emotional Stability',
  'Rational Thinking',
  'Core Values',
  'Lifestyle',
  'Social Style',
  'Self Expression'
];

const GENRE_TAGS = [
  'Fantasy', 'Romance', 'Thriller', 'Mystery', 'Sci-Fi', 'Historical Fiction',
  'Contemporary', 'Self-Help', 'Biography', 'Memoir', 'Poetry', 'Drama',
  'Adventure', 'Horror', 'Comedy', 'Philosophy', 'Psychology', 'Science'
];

const CreateBookClubModal: React.FC<CreateBookClubModalProps> = ({ isOpen, onClose, onSubmit }) => {
  const [formData, setFormData] = useState<CreateBookClubData>({
    name: '',
    description: '',
    currentBookTitle: '',
    currentBookAuthor: '',
    maxMembers: 20,
    personalityTraits: [],
    meetingTime: '',
    nextMeetingDate: '',
    isPrivate: false,
    tags: []
  });

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [customTag, setCustomTag] = useState('');

  const handleInputChange = (field: keyof CreateBookClubData, value: any) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  const handlePersonalityTraitToggle = (trait: string) => {
    setFormData(prev => ({
      ...prev,
      personalityTraits: prev.personalityTraits.includes(trait)
        ? prev.personalityTraits.filter(t => t !== trait)
        : [...prev.personalityTraits, trait]
    }));
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
    
    if (!formData.name.trim() || !formData.description.trim()) {
      alert('Please fill in all required fields');
      return;
    }

    if (formData.personalityTraits.length === 0) {
      alert('Please select at least one personality trait');
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
        name: '',
        description: '',
        currentBookTitle: '',
        currentBookAuthor: '',
        maxMembers: 20,
        personalityTraits: [],
        meetingTime: '',
        nextMeetingDate: '',
        isPrivate: false,
        tags: []
      });
    } catch (error) {
      console.error('Error creating book club:', error);
      alert('Failed to create book club. Please try again.');
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
              <BookOpen className="w-5 h-5 text-white" />
            </div>
            <div>
              <h2 className="text-xl font-bold text-gray-900">Create Book Club</h2>
              <p className="text-sm text-gray-600">Start a new reading community</p>
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
          {/* Basic Information */}
          <div className="space-y-4">
            <h3 className="text-lg font-semibold text-gray-900">Basic Information</h3>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Club Name *
              </label>
              <input
                type="text"
                value={formData.name}
                onChange={(e) => handleInputChange('name', e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-pink-500 focus:border-transparent"
                placeholder="Enter club name"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Description *
              </label>
              <textarea
                value={formData.description}
                onChange={(e) => handleInputChange('description', e.target.value)}
                rows={3}
                className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-pink-500 focus:border-transparent"
                placeholder="Describe your book club's purpose and focus"
                required
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Current Book Title
                </label>
                <input
                  type="text"
                  value={formData.currentBookTitle}
                  onChange={(e) => handleInputChange('currentBookTitle', e.target.value)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-pink-500 focus:border-transparent"
                  placeholder="What are you reading?"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Author
                </label>
                <input
                  type="text"
                  value={formData.currentBookAuthor}
                  onChange={(e) => handleInputChange('currentBookAuthor', e.target.value)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-pink-500 focus:border-transparent"
                  placeholder="Book author"
                />
              </div>
            </div>
          </div>

          {/* Club Settings */}
          <div className="space-y-4">
            <h3 className="text-lg font-semibold text-gray-900">Club Settings</h3>
            
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <Users className="w-5 h-5 text-gray-500" />
                <span className="text-sm font-medium text-gray-700">Max Members</span>
              </div>
              <div className="flex items-center space-x-3">
                <button
                  type="button"
                  onClick={() => handleInputChange('maxMembers', Math.max(5, formData.maxMembers - 5))}
                  className="w-8 h-8 bg-gray-100 hover:bg-gray-200 rounded-lg flex items-center justify-center transition-colors"
                >
                  <Minus className="w-4 h-4 text-gray-600" />
                </button>
                <span className="w-12 text-center font-medium">{formData.maxMembers}</span>
                <button
                  type="button"
                  onClick={() => handleInputChange('maxMembers', Math.min(100, formData.maxMembers + 5))}
                  className="w-8 h-8 bg-gray-100 hover:bg-gray-200 rounded-lg flex items-center justify-center transition-colors"
                >
                  <Plus className="w-4 h-4 text-gray-600" />
                </button>
              </div>
            </div>

            <div className="flex items-center space-x-3">
              <button
                type="button"
                onClick={() => handleInputChange('isPrivate', !formData.isPrivate)}
                className={`flex items-center space-x-2 px-4 py-2 rounded-xl border transition-colors ${
                  formData.isPrivate
                    ? 'bg-pink-50 border-pink-200 text-pink-700'
                    : 'bg-gray-50 border-gray-200 text-gray-700'
                }`}
              >
                {formData.isPrivate ? (
                  <Lock className="w-4 h-4" />
                ) : (
                  <Unlock className="w-4 h-4" />
                )}
                <span className="text-sm font-medium">
                  {formData.isPrivate ? 'Private Club' : 'Public Club'}
                </span>
              </button>
            </div>
          </div>

          {/* Personality Traits */}
          <div className="space-y-4">
            <h3 className="text-lg font-semibold text-gray-900">Target Personality Traits *</h3>
            <p className="text-sm text-gray-600">Select traits that best describe your ideal club members</p>
            
            <div className="grid grid-cols-2 gap-3">
              {PERSONALITY_TRAITS.map((trait) => (
                <button
                  key={trait}
                  type="button"
                  onClick={() => handlePersonalityTraitToggle(trait)}
                  className={`p-3 rounded-xl border text-sm font-medium transition-colors ${
                    formData.personalityTraits.includes(trait)
                      ? 'bg-pink-50 border-pink-200 text-pink-700'
                      : 'bg-gray-50 border-gray-200 text-gray-700 hover:bg-gray-100'
                  }`}
                >
                  {trait}
                </button>
              ))}
            </div>
          </div>

          {/* Tags */}
          <div className="space-y-4">
            <h3 className="text-lg font-semibold text-gray-900">Tags *</h3>
            <p className="text-sm text-gray-600">Select genres and topics that interest your club</p>
            
            <div className="grid grid-cols-3 gap-2">
              {GENRE_TAGS.map((tag) => (
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

          {/* Meeting Information */}
          <div className="space-y-4">
            <h3 className="text-lg font-semibold text-gray-900">Meeting Information</h3>
            
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Meeting Time
                </label>
                <input
                  type="text"
                  value={formData.meetingTime}
                  onChange={(e) => handleInputChange('meetingTime', e.target.value)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-pink-500 focus:border-transparent"
                  placeholder="e.g., Every Tuesday 7 PM"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Next Meeting Date
                </label>
                <input
                  type="date"
                  value={formData.nextMeetingDate}
                  onChange={(e) => handleInputChange('nextMeetingDate', e.target.value)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-pink-500 focus:border-transparent"
                />
              </div>
            </div>
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
              {isSubmitting ? 'Creating...' : 'Create Club'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default CreateBookClubModal;
