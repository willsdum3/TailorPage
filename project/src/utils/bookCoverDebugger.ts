// Book Cover Debugger - Interactive debugging tool for missing book covers

import { getBookCover, clearBookCoverFromCache, getCacheStats } from './bookCoverService';

interface DebugResult {
  bookId: string;
  title: string;
  author: string;
  success: boolean;
  coverUrl?: string;
  error?: string;
  needsManualOverride: boolean;
}

/**
 * Interactive debugger for book covers
 * Run this in your browser console to debug missing covers
 */
export const debugBookCoverInteractive = async (
  title: string,
  author: string,
  bookId?: string
): Promise<DebugResult> => {
  const id = bookId || title.toLowerCase().replace(/[^a-z0-9]/g, '-');
  
  console.log(`🔍 Debugging: "${title}" by ${author}`);
  console.log(`📋 Book ID: ${id}`);
  
  // Clear any cached version
  clearBookCoverFromCache(id, title, author);
  
  try {
    const coverUrl = await getBookCover(id, title, author);
    
    const isPlaceholder = coverUrl?.includes('placeholder.com');
    const success = !isPlaceholder;
    
    const result: DebugResult = {
      bookId: id,
      title,
      author,
      success,
      coverUrl,
      needsManualOverride: isPlaceholder || false
    };
    
    if (success) {
      console.log(`✅ SUCCESS: Cover found!`);
      console.log(`🔗 URL: ${coverUrl}`);
    } else {
      console.log(`❌ FAILED: Only placeholder cover found`);
      console.log(`🔧 Needs manual override`);
      console.log(`📝 Suggested override key: '${id}'`);
    }
    
    return result;
  } catch (error) {
    const result: DebugResult = {
      bookId: id,
      title,
      author,
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      needsManualOverride: true
    };
    
    console.log(`💥 ERROR: ${result.error}`);
    console.log(`🔧 Needs manual override`);
    
    return result;
  }
};

/**
 * Batch debug all books in your app
 * This will help you identify which books need manual overrides
 */
export const debugAllBookCovers = async (): Promise<{
  successful: DebugResult[];
  failed: DebugResult[];
  summary: {
    total: number;
    successful: number;
    failed: number;
    successRate: number;
  };
}> => {
  console.log(`🔍 Starting comprehensive book cover audit...`);
  
  // Import your book data here
  // You'll need to replace this with your actual book data
  const allBooks = [
    // Add your books here, for example:
    { id: 'midnight-library', title: 'The Midnight Library', author: 'Matt Haig' },
    { id: 'klara-sun', title: 'Klara and the Sun', author: 'Kazuo Ishiguro' },
    { id: 'evelyn-hugo', title: 'The Seven Husbands of Evelyn Hugo', author: 'Taylor Jenkins Reid' },
    { id: 'normal-people', title: 'Normal People', author: 'Sally Rooney' },
    { id: 'circe', title: 'Circe', author: 'Madeline Miller' },
    { id: 'song-achilles', title: 'The Song of Achilles', author: 'Madeline Miller' },
    { id: 'little-fires', title: 'Little Fires Everywhere', author: 'Celeste Ng' },
    { id: 'becoming', title: 'Becoming', author: 'Michelle Obama' },
    { id: 'long-walk-freedom', title: 'Long Walk to Freedom', author: 'Nelson Mandela' },
    { id: 'martian', title: 'The Martian', author: 'Andy Weir' },
    { id: 'yes-please', title: 'Yes Please', author: 'Amy Poehler' },
    { id: 'never-let-me-go', title: 'Never Let Me Go', author: 'Kazuo Ishiguro' },
    { id: 'tao-physics', title: 'The Tao of Physics', author: 'Fritjof Capra' },
    { id: 'siddhartha', title: 'Siddhartha', author: 'Hermann Hesse' },
    { id: 'book-joy', title: 'The Book of Joy', author: 'Dalai Lama & Desmond Tutu' },
    // Add more books from your app here...
  ];
  
  console.log(`📚 Testing ${allBooks.length} books...`);
  
  const results = await Promise.all(
    allBooks.map(book => debugBookCoverInteractive(book.title, book.author, book.id))
  );
  
  const successful = results.filter(r => r.success);
  const failed = results.filter(r => !r.success);
  
  const summary = {
    total: allBooks.length,
    successful: successful.length,
    failed: failed.length,
    successRate: Math.round((successful.length / allBooks.length) * 100)
  };
  
  console.log(`\n📊 AUDIT SUMMARY:`);
  console.log(`📚 Total books: ${summary.total}`);
  console.log(`✅ Successful: ${summary.successful}`);
  console.log(`❌ Failed: ${summary.failed}`);
  console.log(`📈 Success rate: ${summary.successRate}%`);
  
  if (failed.length > 0) {
    console.log(`\n🔧 BOOKS NEEDING MANUAL OVERRIDES:`);
    failed.forEach(book => {
      console.log(`  - "${book.title}" by ${book.author}`);
      console.log(`    Key: '${book.bookId}'`);
      console.log(`    Error: ${book.error || 'Placeholder only'}`);
    });
    
    console.log(`\n📝 MANUAL OVERRIDE CODE:`);
    console.log(`Add these to src/utils/bookCoverService.ts:`);
    console.log(`\nconst manualCoverOverrides: Record<string, string> = {`);
    failed.forEach(book => {
      const key = book.title.toLowerCase().replace(/[^a-z0-9]/g, '-');
      console.log(`  '${key}': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/[GOODREADS_ID].jpg',`);
    });
    console.log(`};`);
  }
  
  return { successful, failed, summary };
};

/**
 * Quick test for a specific book
 * Use this in browser console to test individual books
 */
export const quickTest = async (title: string, author: string): Promise<void> => {
  console.log(`🧪 Quick test for: "${title}" by ${author}`);
  
  const result = await debugBookCoverInteractive(title, author);
  
  if (result.success) {
    console.log(`✅ Book cover is working correctly!`);
  } else {
    console.log(`❌ Book needs manual override`);
    console.log(`🔧 Add this to manualCoverOverrides:`);
    const key = title.toLowerCase().replace(/[^a-z0-9]/g, '-');
    console.log(`'${key}': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/[GOODREADS_ID].jpg',`);
  }
};

/**
 * Check cache status
 */
export const checkCacheStatus = (): void => {
  const stats = getCacheStats();
  console.log(`📊 Cache Status:`);
  console.log(`📦 Cached covers: ${stats.size}`);
  console.log(`📋 Cached books:`, stats.entries);
};

/**
 * Clear cache and retest
 */
export const clearCacheAndRetest = async (title: string, author: string): Promise<void> => {
  console.log(`🧹 Clearing cache and retesting: "${title}" by ${author}`);
  
  clearBookCoverFromCache('', title, author);
  
  // Wait a moment for cache to clear
  await new Promise(resolve => setTimeout(resolve, 100));
  
  await quickTest(title, author);
};

// Export for browser console usage
if (typeof window !== 'undefined') {
  (window as any).bookCoverDebugger = {
    debugBookCoverInteractive,
    debugAllBookCovers,
    quickTest,
    checkCacheStatus,
    clearCacheAndRetest
  };
  
  console.log(`🔧 Book Cover Debugger loaded!`);
  console.log(`📝 Available commands:`);
  console.log(`  - bookCoverDebugger.quickTest('Book Title', 'Author Name')`);
  console.log(`  - bookCoverDebugger.debugAllBookCovers()`);
  console.log(`  - bookCoverDebugger.checkCacheStatus()`);
  console.log(`  - bookCoverDebugger.clearCacheAndRetest('Book Title', 'Author Name')`);
}
