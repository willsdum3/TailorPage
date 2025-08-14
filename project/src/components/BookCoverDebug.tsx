import React, { useState, useEffect } from 'react';
import { BookCover } from './BookCover';
import { bookCoverService } from '../services/bookCoverService';

const BookCoverDebug: React.FC = () => {
  const [apiKeyStatus, setApiKeyStatus] = useState<string>('Checking...');
  const [testResult, setTestResult] = useState<string>('');

  useEffect(() => {
    // Check if API key is available
    const apiKey = import.meta.env.VITE_GOOGLE_BOOKS_API_KEY;
    if (apiKey && apiKey !== 'your_google_books_api_key_here') {
      setApiKeyStatus('✅ API Key Found');
    } else {
      setApiKeyStatus('❌ API Key Missing or Invalid');
    }

    // Test book cover service
    const testCover = async () => {
      try {
        const result = await bookCoverService.getBookCover('The Midnight Library', 'Matt Haig');
        setTestResult(`✅ Cover loaded: ${result.success ? 'Success' : 'Failed'} - Source: ${result.source}`);
      } catch (error) {
        setTestResult(`❌ Error: ${error instanceof Error ? error.message : 'Unknown error'}`);
      }
    };

    testCover();
  }, []);

  return (
    <div className="p-4 bg-white/10 rounded-lg">
      <h3 className="text-lg font-bold text-white mb-4">Book Cover Debug</h3>
      <div className="space-y-2 text-sm">
        <div>API Key Status: {apiKeyStatus}</div>
        <div>Test Result: {testResult}</div>
      </div>
      
      <div className="mt-4">
        <BookCover
          title="The Midnight Library"
          author="Matt Haig"
          size="md"
          priority="high"
          lazy={false}
        />
      </div>
    </div>
  );
};

export default BookCoverDebug;


