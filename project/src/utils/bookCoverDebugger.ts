// Book Cover Debugger
// Helps identify and fix book cover loading issues

import { getBookCover, clearBookCoverFromCache, getCacheStats } from './bookCoverService';

export interface BookCoverDebugInfo {
  bookId: string;
  title: string;
  author: string;
  coverUrl: string | null;
  cacheKey: string;
  overrideKey: string;
  hasOverride: boolean;
  cacheHit: boolean;
  loadTime: number;
  error?: string;
}

/**
 * Debug a specific book's cover loading process
 */
export const debugBookCover = async (
  bookId: string, 
  title: string, 
  author: string
): Promise<BookCoverDebugInfo> => {
  const startTime = Date.now();
  
  // Generate keys
  const cacheKey = `${title.toLowerCase()}-${author.toLowerCase()}`;
  const overrideKey = bookId.toLowerCase().replace(/[^a-z0-9]/g, '-');
  
  // Check cache
  const cacheStats = getCacheStats();
  const cacheHit = cacheStats.entries.includes(cacheKey);
  
  // Check manual overrides
  const manualOverrides = {
    'mans-search-for-meaning': '/book-covers/MansSearchForMeaning.jpg',
    'stillness-is-the-key': '/book-covers/StillnessIsTheKey.jpg',
    'wonder': '/book-covers/Wonder.jpg',
    'where-the-crawdads-sing': '/book-covers/WhereTheCrawdadsSing.jpg',
    'invisible-cities': '/book-covers/InvisibleCities.jpg',
    'steve-jobs': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1511288482i/11084145.jpg',
    'atonement': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/6867.jpg',
    'the-goldfinch': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1378714833i/17333223.jpg',
    'beloved': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327959502i/6149.jpg',
    'wild': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/12262741.jpg',
    'midnight-library': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1602190253i/52578297.jpg',
    'seven-husbands-evelyn-hugo': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1674739970i/32620332.jpg',
    'alchemist': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1483412266i/865.jpg',
    'normal-people': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1578028274i/41057294.jpg',
    'klara-and-sun': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1602190253i/54120408.jpg',
    'circe': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1529033999i/35959740.jpg',
    'song-of-achilles': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1331154660i/11250317.jpg',
    'little-fires-everywhere': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1494197999i/34273236.jpg',
    'kitchen-confidential': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/33313.jpg',
    'secret-history': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/29044.jpg',
    'big-magic': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1440559032i/24453082.jpg',
    'evelyn-hugo': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1674739970i/32620332.jpg',
    'seven-husbands': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1674739970i/32620332.jpg',
  };
  
  const hasOverride = overrideKey in manualOverrides;
  
  try {
    // Clear cache to force fresh fetch
    clearBookCoverFromCache(bookId, title, author);
    
    // Fetch cover
    const coverUrl = await getBookCover(bookId, title, author);
    
    return {
      bookId,
      title,
      author,
      coverUrl,
      cacheKey,
      overrideKey,
      hasOverride,
      cacheHit,
      loadTime: Date.now() - startTime,
    };
  } catch (error) {
    return {
      bookId,
      title,
      author,
      coverUrl: null,
      cacheKey,
      overrideKey,
      hasOverride,
      cacheHit,
      loadTime: Date.now() - startTime,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
};

/**
 * Debug multiple books at once
 */
export const debugMultipleBookCovers = async (
  books: Array<{ bookId: string; title: string; author: string }>
): Promise<BookCoverDebugInfo[]> => {
  console.log(`🔍 Debugging ${books.length} book covers...`);
  
  const results: BookCoverDebugInfo[] = [];
  
  for (const book of books) {
    const debugInfo = await debugBookCover(book.bookId, book.title, book.author);
    results.push(debugInfo);
    
    // Log results
    if (debugInfo.coverUrl) {
      console.log(`✅ ${book.title} by ${book.author}: Found cover`);
    } else {
      console.log(`❌ ${book.title} by ${book.author}: No cover found`);
      if (debugInfo.hasOverride) {
        console.log(`   ⚠️  Has manual override but still failed`);
      }
    }
    
    // Small delay to avoid overwhelming APIs
    await new Promise(resolve => setTimeout(resolve, 100));
  }
  
  // Summary
  const successful = results.filter(r => r.coverUrl).length;
  const failed = results.length - successful;
  
  console.log(`\n📊 Debug Summary:`);
  console.log(`   Total: ${results.length}`);
  console.log(`   Successful: ${successful}`);
  console.log(`   Failed: ${failed}`);
  console.log(`   Success Rate: ${((successful / results.length) * 100).toFixed(1)}%`);
  
  // Show failed books
  if (failed > 0) {
    console.log(`\n❌ Failed Books:`);
    results.filter(r => !r.coverUrl).forEach(r => {
      console.log(`   - ${r.title} by ${r.author} (ID: ${r.bookId})`);
      if (r.error) {
        console.log(`     Error: ${r.error}`);
      }
    });
  }
  
  return results;
};

/**
 * Generate a report of all book cover issues
 */
export const generateBookCoverReport = (debugInfos: BookCoverDebugInfo[]): string => {
  const successful = debugInfos.filter(r => r.coverUrl).length;
  const failed = debugInfos.length - successful;
  const successRate = ((successful / debugInfos.length) * 100).toFixed(1);
  
  let report = `# Book Cover Loading Report\n\n`;
  report += `## Summary\n`;
  report += `- **Total Books**: ${debugInfos.length}\n`;
  report += `- **Successful**: ${successful}\n`;
  report += `- **Failed**: ${failed}\n`;
  report += `- **Success Rate**: ${successRate}%\n\n`;
  
  if (failed > 0) {
    report += `## Failed Books\n\n`;
    debugInfos.filter(r => !r.coverUrl).forEach(r => {
      report += `### ${r.title} by ${r.author}\n`;
      report += `- **Book ID**: ${r.bookId}\n`;
      report += `- **Cache Key**: ${r.cacheKey}\n`;
      report += `- **Override Key**: ${r.overrideKey}\n`;
      report += `- **Has Override**: ${r.hasOverride}\n`;
      report += `- **Load Time**: ${r.loadTime}ms\n`;
      if (r.error) {
        report += `- **Error**: ${r.error}\n`;
      }
      report += `\n`;
    });
  }
  
  return report;
};

/**
 * Test specific books that are known to fail
 */
export const testKnownProblemBooks = async (): Promise<void> => {
  const problemBooks = [
    { bookId: 'where-crawdads-sing', title: 'Where the Crawdads Sing', author: 'Delia Owens' },
    { bookId: 'wild', title: 'Wild', author: 'Cheryl Strayed' },
    { bookId: 'song-of-achilles', title: 'The Song of Achilles', author: 'Madeline Miller' },
    { bookId: 'seven-husbands-evelyn-hugo', title: 'The Seven Husbands of Evelyn Hugo', author: 'Taylor Jenkins Reid' },
    { bookId: 'kitchen-confidential', title: 'Kitchen Confidential', author: 'Anthony Bourdain' },
    { bookId: 'secret-history', title: 'The Secret History', author: 'Donna Tartt' },
    { bookId: 'big-magic', title: 'Big Magic', author: 'Elizabeth Gilbert' },
  ];
  
  console.log('🧪 Testing known problem books...');
  const results = await debugMultipleBookCovers(problemBooks);
  
  // Generate report
  const report = generateBookCoverReport(results);
  console.log('\n📄 Report:');
  console.log(report);
};
