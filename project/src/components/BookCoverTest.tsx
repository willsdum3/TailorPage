import React, { useState, useEffect } from 'react';
import { BookCover } from './BookCover';
import { bookCoverService } from '../services/bookCoverService';

const BookCoverTest: React.FC = () => {
  const [testResults, setTestResults] = useState<Array<{
    title: string;
    author: string;
    result: string;
    coverData?: any;
    error?: string;
  }>>([]);
  const [loading, setLoading] = useState(false);
  const [rateLimitStatus, setRateLimitStatus] = useState<any>(null);
  const [cacheStats, setCacheStats] = useState<any>(null);

  const testBooks = [
    { title: 'The Midnight Library', author: 'Matt Haig' },
    { title: 'Atomic Habits', author: 'James Clear' },
    { title: 'Fourth Wing', author: 'Rebecca Yarros' },
    { title: 'It Ends with Us', author: 'Colleen Hoover' },
    { title: 'The Seven Husbands of Evelyn Hugo', author: 'Taylor Jenkins Reid' }
  ];

  const runTests = async () => {
    setLoading(true);
    setTestResults([]);

    for (const book of testBooks) {
      try {
        console.log(`Testing: ${book.title} by ${book.author}`);
        const result = await bookCoverService.getBookCover(book.title, book.author);
        
        setTestResults(prev => [...prev, {
          title: book.title,
          author: book.author,
          result: result.success ? 'Success' : 'Failed',
          coverData: result.data,
          error: result.error
        }]);

        console.log(`Result for ${book.title}:`, result);
      } catch (error) {
        console.error(`Error testing ${book.title}:`, error);
        setTestResults(prev => [...prev, {
          title: book.title,
          author: book.author,
          result: 'Error',
          error: error instanceof Error ? error.message : 'Unknown error'
        }]);
      }
    }

    setLoading(false);
  };

  useEffect(() => {
    runTests();
    
    // Update rate limit status and cache stats
    const updateStats = () => {
      setRateLimitStatus(bookCoverService.getRateLimitStatus());
      setCacheStats(bookCoverService.getCacheStats());
    };
    
    updateStats();
    const interval = setInterval(updateStats, 5000); // Update every 5 seconds
    
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="p-6 bg-white/5 rounded-lg">
      <h2 className="text-xl font-bold text-white mb-4">Book Cover System Test (Optimized)</h2>
      
      {/* API Key Status */}
      <div className="mb-4 p-3 bg-blue-900/20 rounded">
        <h3 className="font-semibold text-blue-300 mb-2">API Configuration</h3>
        <div className="text-sm space-y-1">
          <div>Google Books API Key: {import.meta.env.VITE_GOOGLE_BOOKS_API_KEY ? '✅ Configured' : '❌ Missing'}</div>
          <div>Amazon API Key: {import.meta.env.VITE_AMAZON_API_KEY ? '✅ Configured' : '❌ Missing'}</div>
          <div>Goodreads API Key: {import.meta.env.VITE_GOODREADS_API_KEY ? '✅ Configured' : '❌ Missing'}</div>
        </div>
      </div>

      {/* Rate Limit Status */}
      {rateLimitStatus && (
        <div className="mb-4 p-3 bg-yellow-900/20 rounded">
          <h3 className="font-semibold text-yellow-300 mb-2">Rate Limit Status</h3>
          <div className="text-sm space-y-1">
            <div>Google Books: {rateLimitStatus.google.current}/{rateLimitStatus.google.limit} calls per hour</div>
            <div>Open Library: {rateLimitStatus.openlibrary.current}/{rateLimitStatus.openlibrary.limit} calls per hour</div>
          </div>
        </div>
      )}

      {/* Cache Stats */}
      {cacheStats && (
        <div className="mb-4 p-3 bg-green-900/20 rounded">
          <h3 className="font-semibold text-green-300 mb-2">Cache Statistics</h3>
          <div className="text-sm space-y-1">
            <div>Memory Cache: {cacheStats.memorySize} items</div>
            <div>Total API Calls: {cacheStats.apiCalls}</div>
          </div>
        </div>
      )}

      {/* Test Results */}
      <div className="mb-4">
        <h3 className="font-semibold text-white mb-2">Service Test Results</h3>
        {loading && <div className="text-yellow-300">Running tests...</div>}
        
        <div className="space-y-2">
          {testResults.map((test, index) => (
            <div key={index} className="p-2 bg-white/5 rounded text-sm">
              <div className="font-medium text-white">
                {test.title} by {test.author}
              </div>
              <div className={`text-xs ${test.result === 'Success' ? 'text-green-300' : 'text-red-300'}`}>
                Status: {test.result}
              </div>
              {test.coverData && (
                <div className="text-xs text-gray-300 mt-1">
                  Source: {test.coverData.source} | Quality: {test.coverData.quality}
                </div>
              )}
              {test.error && (
                <div className="text-xs text-red-400 mt-1">
                  Error: {test.error}
                </div>
              )}
            </div>
          ))}
        </div>
      </div>

      {/* Visual Test */}
      <div className="mb-4">
        <h3 className="font-semibold text-white mb-2">Visual Test</h3>
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4">
          {testBooks.map((book, index) => (
            <div key={index} className="text-center">
              <BookCover
                title={book.title}
                author={book.author}
                size="md"
                priority="high"
                lazy={false}
              />
              <div className="text-xs text-white/70 mt-1">
                {book.title.length > 15 ? book.title.substring(0, 15) + '...' : book.title}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Manual Test */}
      <div className="mb-4">
        <h3 className="font-semibold text-white mb-2">Manual Test</h3>
        <div className="flex gap-4">
          <BookCover
            title="Test Book"
            author="Test Author"
            size="lg"
            priority="high"
            lazy={false}
          />
          <div className="text-white">
            <p>This should show a placeholder if no API key is configured</p>
          </div>
        </div>
      </div>

      <div className="flex gap-2">
        <button
          onClick={runTests}
          disabled={loading}
          className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
        >
          {loading ? 'Running...' : 'Run Tests Again'}
        </button>
        
        <button
          onClick={() => {
            bookCoverService.clearCache();
            setRateLimitStatus(bookCoverService.getRateLimitStatus());
            setCacheStats(bookCoverService.getCacheStats());
          }}
          className="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
        >
          Clear Cache
        </button>
      </div>
    </div>
  );
};

export default BookCoverTest;
