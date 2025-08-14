import React, { useState, useEffect } from 'react';
import { BookCover } from './BookCover';
import { bookCoverService } from '../services/bookCoverService';

const SimpleBookCoverTest: React.FC = () => {
  const [testResults, setTestResults] = useState<string[]>([]);
  const [loading, setLoading] = useState(false);

  const testBooks = [
    { title: 'The Midnight Library', author: 'Matt Haig' },
    { title: 'Atomic Habits', author: 'James Clear' },
    { title: 'Fourth Wing', author: 'Rebecca Yarros' }
  ];

  const runQuickTest = async () => {
    setLoading(true);
    setTestResults([]);

    for (const book of testBooks) {
      try {
        setTestResults(prev => [...prev, `Testing: ${book.title} by ${book.author}`]);
        
        const result = await bookCoverService.getBookCover(book.title, book.author);
        
        if (result.success) {
          setTestResults(prev => [...prev, `✅ Success: ${book.title} - Source: ${result.source}`]);
        } else {
          setTestResults(prev => [...prev, `❌ Failed: ${book.title} - ${result.error}`]);
        }
      } catch (error) {
        setTestResults(prev => [...prev, `❌ Error: ${book.title} - ${error instanceof Error ? error.message : 'Unknown error'}`]);
      }
    }

    setLoading(false);
  };

  useEffect(() => {
    runQuickTest();
  }, []);

  return (
    <div className="p-4 bg-white/10 rounded-lg">
      <h3 className="text-lg font-bold text-white mb-4">Quick Book Cover Test</h3>
      
      {/* Test Results */}
      <div className="mb-4">
        <h4 className="text-md font-semibold text-white mb-2">Test Results:</h4>
        <div className="space-y-1">
          {testResults.map((result, index) => (
            <div key={index} className="text-sm text-white/80">
              {result}
            </div>
          ))}
        </div>
        {loading && <div className="text-yellow-300 text-sm">Running tests...</div>}
      </div>

      {/* Visual Test */}
      <div className="mb-4">
        <h4 className="text-md font-semibold text-white mb-2">Visual Test:</h4>
        <div className="grid grid-cols-3 gap-4">
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
                {book.title}
              </div>
            </div>
          ))}
        </div>
      </div>

      <button
        onClick={runQuickTest}
        disabled={loading}
        className="px-3 py-1 bg-blue-600 text-white rounded text-sm hover:bg-blue-700 disabled:opacity-50"
      >
        {loading ? 'Testing...' : 'Run Test Again'}
      </button>
    </div>
  );
};

export default SimpleBookCoverTest;


