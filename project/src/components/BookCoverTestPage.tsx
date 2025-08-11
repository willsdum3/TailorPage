import React, { useState } from 'react';
import { Home, Settings, RefreshCw, BarChart3, Zap, BookOpen } from 'lucide-react';
import { BookCover, BookCoverGrid } from './BookCover';
import { BookCoverManager } from './BookCoverManager';
import { useBookCovers } from '../hooks/useBookCovers';
import { bookCoverService } from '../services/bookCoverService';
import BookCoverDebug from './BookCoverDebug';
import BookCoverTest from './BookCoverTest';
import SimpleBookCoverTest from './SimpleBookCoverTest';

interface BookCoverTestPageProps {
  onBack: () => void;
}

const testBooks = [
  { title: 'Fourth Wing', author: 'Rebecca Yarros', id: 'fourth-wing' },
  { title: 'Atomic Habits', author: 'James Clear', id: 'atomic-habits' },
  { title: 'It Ends with Us', author: 'Colleen Hoover', id: 'it-ends-with-us' },
  { title: 'The Midnight Library', author: 'Matt Haig', id: 'midnight-library' },
  { title: 'The Seven Husbands of Evelyn Hugo', author: 'Taylor Jenkins Reid', id: 'seven-husbands' },
  { title: 'Verity', author: 'Colleen Hoover', id: 'verity' },
  { title: 'The Housemaid', author: 'Freida McFadden', id: 'housemaid' },
  { title: 'Lessons in Chemistry', author: 'Bonnie Garmus', id: 'lessons-chemistry' },
  { title: 'The Silent Patient', author: 'Alex Michaelides', id: 'silent-patient' },
  { title: 'The Guest List', author: 'Lucy Foley', id: 'guest-list' },
  { title: 'Normal People', author: 'Sally Rooney', id: 'normal-people' },
  { title: 'Circe', author: 'Madeline Miller', id: 'circe' }
];

const BookCoverTestPage: React.FC<BookCoverTestPageProps> = ({ onBack }) => {
  const [selectedSize, setSelectedSize] = useState<'sm' | 'md' | 'lg' | 'xl'>('lg');
  const [showTitles, setShowTitles] = useState(true);
  const [showAuthors, setShowAuthors] = useState(true);
  const [testMode, setTestMode] = useState<'single' | 'grid' | 'manager'>('grid');
  const [customBook, setCustomBook] = useState({ title: '', author: '' });

  const { coverState, loadCovers, clearAllCovers, getCacheStats } = useBookCovers({
    preloadCount: 8,
    enableCache: true,
    retryAttempts: 3,
    retryDelay: 1000,
    onCoverLoad: (bookId, coverData) => {
      console.log(`Cover loaded for ${bookId}:`, coverData);
    },
    onCoverError: (bookId, error) => {
      console.error(`Cover error for ${bookId}:`, error);
    }
  });

  const handleLoadCustomBook = () => {
    if (customBook.title && customBook.author) {
      loadCovers([customBook]);
    }
  };

  const handleClearCache = () => {
    clearAllCovers();
    bookCoverService.clearCache();
  };

  const stats = getCacheStats();

  return (
    <div className="min-h-screen py-8 px-4 relative overflow-hidden">
      {/* Background Elements */}
      <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900" />
      <div className="absolute top-20 left-20 w-72 h-72 bg-purple-500/10 rounded-full blur-3xl" />
      <div className="absolute bottom-20 right-20 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl" />
      
      {/* Home Button */}
      <button
        onClick={onBack}
        className="fixed top-6 left-6 z-50 bg-white/10 backdrop-blur-md border border-white/20 hover:bg-white/20 text-white p-3 rounded-xl transition-all duration-300 transform hover:scale-105"
        aria-label="Go to Home"
      >
        <Home className="w-6 h-6" />
      </button>

      <div className="max-w-7xl mx-auto relative z-10">
        {/* Header */}
        <div className="text-center mb-12">
          <div className="inline-flex items-center space-x-2 bg-white/10 backdrop-blur-sm border border-white/20 rounded-full px-4 py-2 mb-6">
            <BookOpen className="w-4 h-4 text-amber-400" />
            <span className="text-sm font-medium text-white/80">Book Cover System Test</span>
          </div>
          
          <h1 className="text-5xl md:text-6xl font-bold text-white mb-6 leading-tight">
            Book Cover <span className="bg-gradient-to-r from-amber-400 to-orange-500 bg-clip-text text-transparent">System</span>
          </h1>
          
          <p className="text-xl text-white/70 mb-8 max-w-3xl mx-auto leading-relaxed">
            Test and demonstrate the comprehensive book cover system with multiple sources, caching, and performance optimization.
          </p>
        </div>

        {/* Controls */}
        <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6 mb-8">
          <h2 className="text-2xl font-bold text-white mb-6 flex items-center space-x-2">
            <Settings className="w-6 h-6" />
            <span>Test Controls</span>
          </h2>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            {/* Test Mode */}
            <div>
              <label className="block text-sm font-medium text-white/80 mb-2">Test Mode</label>
              <select
                value={testMode}
                onChange={(e) => setTestMode(e.target.value as 'single' | 'grid' | 'manager')}
                className="w-full bg-white/10 border border-white/20 rounded-lg px-3 py-2 text-white focus:outline-none focus:ring-2 focus:ring-amber-400"
              >
                <option value="single">Single Cover</option>
                <option value="grid">Cover Grid</option>
                <option value="manager">Advanced Manager</option>
              </select>
            </div>

            {/* Size */}
            <div>
              <label className="block text-sm font-medium text-white/80 mb-2">Cover Size</label>
              <select
                value={selectedSize}
                onChange={(e) => setSelectedSize(e.target.value as 'sm' | 'md' | 'lg' | 'xl')}
                className="w-full bg-white/10 border border-white/20 rounded-lg px-3 py-2 text-white focus:outline-none focus:ring-2 focus:ring-amber-400"
              >
                <option value="sm">Small</option>
                <option value="md">Medium</option>
                <option value="lg">Large</option>
                <option value="xl">Extra Large</option>
              </select>
            </div>

            {/* Show Titles */}
            <div>
              <label className="block text-sm font-medium text-white/80 mb-2">Display Options</label>
              <div className="space-y-2">
                <label className="flex items-center space-x-2">
                  <input
                    type="checkbox"
                    checked={showTitles}
                    onChange={(e) => setShowTitles(e.target.checked)}
                    className="rounded border-white/20 bg-white/10 text-amber-400 focus:ring-amber-400"
                  />
                  <span className="text-sm text-white/70">Show Titles</span>
                </label>
                <label className="flex items-center space-x-2">
                  <input
                    type="checkbox"
                    checked={showAuthors}
                    onChange={(e) => setShowAuthors(e.target.checked)}
                    className="rounded border-white/20 bg-white/10 text-amber-400 focus:ring-amber-400"
                  />
                  <span className="text-sm text-white/70">Show Authors</span>
                </label>
              </div>
            </div>

            {/* Actions */}
            <div>
              <label className="block text-sm font-medium text-white/80 mb-2">Actions</label>
              <div className="space-y-2">
                <button
                  onClick={handleClearCache}
                  className="w-full bg-red-500 hover:bg-red-600 text-white px-3 py-2 rounded-lg text-sm font-medium transition-all duration-200"
                >
                  Clear Cache
                </button>
                <button
                  onClick={() => loadCovers(testBooks)}
                  className="w-full bg-blue-500 hover:bg-blue-600 text-white px-3 py-2 rounded-lg text-sm font-medium transition-all duration-200"
                >
                  Load All
                </button>
              </div>
            </div>
          </div>

          {/* Custom Book Input */}
          <div className="mt-6 p-4 bg-white/5 rounded-lg">
            <h3 className="text-lg font-semibold text-white mb-3">Test Custom Book</h3>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <input
                type="text"
                placeholder="Book Title"
                value={customBook.title}
                onChange={(e) => setCustomBook(prev => ({ ...prev, title: e.target.value }))}
                className="bg-white/10 border border-white/20 rounded-lg px-3 py-2 text-white placeholder-white/50 focus:outline-none focus:ring-2 focus:ring-amber-400"
              />
              <input
                type="text"
                placeholder="Author"
                value={customBook.author}
                onChange={(e) => setCustomBook(prev => ({ ...prev, author: e.target.value }))}
                className="bg-white/10 border border-white/20 rounded-lg px-3 py-2 text-white placeholder-white/50 focus:outline-none focus:ring-2 focus:ring-amber-400"
              />
              <button
                onClick={handleLoadCustomBook}
                disabled={!customBook.title || !customBook.author}
                className="bg-amber-500 hover:bg-amber-600 disabled:bg-amber-500/50 text-white px-4 py-2 rounded-lg font-medium transition-all duration-200"
              >
                Load Cover
              </button>
            </div>
          </div>
        </div>

                    {/* Debug Information */}
            <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6 mb-8">
              <BookCoverDebug />
            </div>

            {/* Simple Test */}
            <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6 mb-8">
              <SimpleBookCoverTest />
            </div>

            {/* Comprehensive Test */}
            <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6 mb-8">
              <BookCoverTest />
            </div>

        {/* Cache Statistics */}
        <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6 mb-8">
          <h2 className="text-2xl font-bold text-white mb-6 flex items-center space-x-2">
            <BarChart3 className="w-6 h-6" />
            <span>Cache Statistics</span>
          </h2>

          <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
            <div className="bg-white/5 rounded-lg p-4 text-center">
              <div className="text-2xl font-bold text-white">{stats.total}</div>
              <div className="text-sm text-white/70">Total Covers</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 text-center">
              <div className="text-2xl font-bold text-green-400">{stats.cached}</div>
              <div className="text-sm text-white/70">Cached</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 text-center">
              <div className="text-2xl font-bold text-yellow-400">{stats.loading}</div>
              <div className="text-sm text-white/70">Loading</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 text-center">
              <div className="text-2xl font-bold text-red-400">{stats.errors}</div>
              <div className="text-sm text-white/70">Errors</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 text-center">
              <div className="text-2xl font-bold text-blue-400">{stats.hitRate.toFixed(1)}%</div>
              <div className="text-sm text-white/70">Hit Rate</div>
            </div>
          </div>
        </div>

        {/* Test Content */}
        <div className="mb-8">
          {testMode === 'single' && (
            <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6">
              <h2 className="text-2xl font-bold text-white mb-6 flex items-center space-x-2">
                <BookOpen className="w-6 h-6" />
                <span>Single Cover Test</span>
              </h2>
              <div className="flex justify-center">
                <BookCover
                  title="The Midnight Library"
                  author="Matt Haig"
                  size={selectedSize}
                  showTitle={showTitles}
                  showAuthor={showAuthors}
                  priority="high"
                  lazy={false}
                />
              </div>
            </div>
          )}

          {testMode === 'grid' && (
            <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6">
              <h2 className="text-2xl font-bold text-white mb-6 flex items-center space-x-2">
                <Zap className="w-6 h-6" />
                <span>Cover Grid Test</span>
              </h2>
              <BookCoverGrid
                books={testBooks}
                size={selectedSize}
                columns={4}
                showTitles={showTitles}
                showAuthors={showAuthors}
                onCoverLoad={(bookId, coverData) => {
                  console.log(`Grid cover loaded: ${bookId}`, coverData);
                }}
                onCoverError={(bookId, error) => {
                  console.error(`Grid cover error: ${bookId}`, error);
                }}
              />
            </div>
          )}

          {testMode === 'manager' && (
            <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6">
              <h2 className="text-2xl font-bold text-white mb-6 flex items-center space-x-2">
                <Settings className="w-6 h-6" />
                <span>Advanced Manager Test</span>
              </h2>
              <BookCoverManager
                books={testBooks}
                size={selectedSize}
                showAdminControls={true}
                showStats={true}
                onCoverLoad={(bookId, coverData) => {
                  console.log(`Manager cover loaded: ${bookId}`, coverData);
                }}
                onCoverError={(bookId, error) => {
                  console.error(`Manager cover error: ${bookId}`, error);
                }}
              />
            </div>
          )}
        </div>

        {/* Custom Book Display */}
        {customBook.title && customBook.author && (
          <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6">
            <h2 className="text-2xl font-bold text-white mb-6 flex items-center space-x-2">
              <RefreshCw className="w-6 h-6" />
              <span>Custom Book Test</span>
            </h2>
            <div className="flex justify-center">
              <BookCover
                title={customBook.title}
                author={customBook.author}
                size={selectedSize}
                showTitle={showTitles}
                showAuthor={showAuthors}
                priority="high"
                lazy={false}
              />
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default BookCoverTestPage;
