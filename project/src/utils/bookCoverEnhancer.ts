// Book Cover Enhancer - Utility to help identify and add missing book covers

import { getBookCover, clearBookCoverFromCache } from './bookCoverService';

interface BookCoverDebugInfo {
  bookId: string;
  title: string;
  author: string;
  success: boolean;
  coverUrl?: string;
  error?: string;
  source?: string;
}

/**
 * Debug function to test book cover loading for a specific book
 */
export const debugBookCover = async (
  bookId: string, 
  title: string, 
  author: string
): Promise<BookCoverDebugInfo> => {
  try {
    console.log(`🔍 Debugging cover for: ${title} by ${author}`);
    
    // Clear any cached version first
    clearBookCoverFromCache(bookId, title, author);
    
    // Try to get the cover
    const coverUrl = await getBookCover(bookId, title, author);
    
    if (coverUrl && !coverUrl.includes('placeholder.com')) {
      return {
        bookId,
        title,
        author,
        success: true,
        coverUrl,
        source: 'API or Manual Override'
      };
    } else {
      return {
        bookId,
        title,
        author,
        success: false,
        coverUrl,
        error: 'Only placeholder cover found',
        source: 'Fallback'
      };
    }
  } catch (error) {
    return {
      bookId,
      title,
      author,
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
};

/**
 * Batch debug multiple books to identify which ones need manual overrides
 */
export const debugBookCovers = async (
  books: Array<{ id: string; title: string; author: string }>
): Promise<{
  successful: BookCoverDebugInfo[];
  failed: BookCoverDebugInfo[];
  summary: {
    total: number;
    successful: number;
    failed: number;
    successRate: number;
  };
}> => {
  console.log(`🔍 Starting batch debug for ${books.length} books...`);
  
  const results = await Promise.all(
    books.map(book => debugBookCover(book.id, book.title, book.author))
  );
  
  const successful = results.filter(r => r.success);
  const failed = results.filter(r => !r.success);
  
  const summary = {
    total: books.length,
    successful: successful.length,
    failed: failed.length,
    successRate: Math.round((successful.length / books.length) * 100)
  };
  
  console.log(`📊 Debug Summary:`, summary);
  console.log(`✅ Successful: ${successful.length}`);
  console.log(`❌ Failed: ${failed.length}`);
  
  if (failed.length > 0) {
    console.log(`📝 Failed books that need manual overrides:`);
    failed.forEach(book => {
      console.log(`  - "${book.title}" by ${book.author} (ID: ${book.bookId})`);
    });
  }
  
  return { successful, failed, summary };
};

/**
 * Generate manual override entries for failed books
 */
export const generateManualOverrides = (
  failedBooks: BookCoverDebugInfo[]
): string => {
  let overrideCode = '\n// Manual overrides for books that failed to load covers\n';
  
  failedBooks.forEach(book => {
    const key = book.title.toLowerCase().replace(/[^a-z0-9]/g, '-');
    overrideCode += `  '${key}': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/[GOODREADS_ID].jpg',\n`;
  });
  
  return overrideCode;
};

/**
 * Test a specific book cover and provide debugging info
 */
export const testBookCover = async (
  title: string,
  author: string,
  bookId?: string
): Promise<void> => {
  const id = bookId || title.toLowerCase().replace(/[^a-z0-9]/g, '-');
  
  console.log(`🧪 Testing book cover for: "${title}" by ${author}`);
  console.log(`📋 Book ID: ${id}`);
  
  const result = await debugBookCover(id, title, author);
  
  if (result.success) {
    console.log(`✅ SUCCESS: Cover found at ${result.coverUrl}`);
    console.log(`📊 Source: ${result.source}`);
  } else {
    console.log(`❌ FAILED: ${result.error}`);
    console.log(`🔧 Suggested manual override key: '${id}'`);
    console.log(`🔗 You'll need to find a Goodreads cover URL for this book`);
  }
  
  return;
};

/**
 * Preload and validate all book covers in your app
 */
export const validateAllBookCovers = async (): Promise<void> => {
  // This would need to be called with your actual book data
  // You can import your book data from various sources and pass it here
  
  console.log(`🔍 Starting comprehensive book cover validation...`);
  
  // Example usage - you would replace this with your actual book data
  const sampleBooks = [
    { id: 'test-1', title: 'The Midnight Library', author: 'Matt Haig' },
    { id: 'test-2', title: 'Klara and the Sun', author: 'Kazuo Ishiguro' },
    // Add more books from your app here
  ];
  
  const results = await debugBookCovers(sampleBooks);
  
  if (results.failed.length > 0) {
    console.log(`\n🔧 To fix missing covers, add these manual overrides to bookCoverService.ts:`);
    console.log(generateManualOverrides(results.failed));
  }
  
  return;
};
