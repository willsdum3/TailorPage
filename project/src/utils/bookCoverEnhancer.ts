// Book Cover Enhancer
// Provides advanced book cover loading, validation, and fallback strategies

import { getBookCover, clearBookCoverFromCache } from './bookCoverService';

export interface BookCoverInfo {
  bookId: string;
  title: string;
  author: string;
  coverUrl: string | null;
  isValid: boolean;
  source: 'manual' | 'google' | 'openlibrary' | 'alternative' | 'generic' | 'none';
  loadTime: number;
  error?: string;
}

/**
 * Validate if a book cover URL is accessible
 */
export const validateBookCover = async (url: string): Promise<boolean> => {
  try {
    const response = await fetch(url, { method: 'HEAD' });
    return response.ok && response.headers.get('content-type')?.includes('image');
  } catch (error) {
    console.warn(`Failed to validate book cover: ${url}`, error);
    return false;
  }
};

/**
 * Enhanced book cover fetching with validation and multiple fallbacks
 */
export const getEnhancedBookCover = async (
  bookId: string, 
  title: string, 
  author: string
): Promise<BookCoverInfo> => {
  const startTime = Date.now();
  
  try {
    // Try to get cover from the main service
    const coverUrl = await getBookCover(bookId, title, author);
    
    if (coverUrl) {
      // Validate the cover URL
      const isValid = await validateBookCover(coverUrl);
      
      return {
        bookId,
        title,
        author,
        coverUrl: isValid ? coverUrl : null,
        isValid,
        source: isValid ? 'google' : 'none', // Simplified for now
        loadTime: Date.now() - startTime,
        error: isValid ? undefined : 'Cover URL validation failed'
      };
    }
    
    return {
      bookId,
      title,
      author,
      coverUrl: null,
      isValid: false,
      source: 'none',
      loadTime: Date.now() - startTime,
      error: 'No cover found'
    };
    
  } catch (error) {
    return {
      bookId,
      title,
      author,
      coverUrl: null,
      isValid: false,
      source: 'none',
      loadTime: Date.now() - startTime,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
};

/**
 * Batch load and validate book covers
 */
export const batchLoadBookCovers = async (
  books: Array<{ bookId: string; title: string; author: string }>
): Promise<BookCoverInfo[]> => {
  console.log(`Starting batch load of ${books.length} book covers...`);
  
  const results: BookCoverInfo[] = [];
  
  // Process books in batches to avoid overwhelming the APIs
  const batchSize = 5;
  for (let i = 0; i < books.length; i += batchSize) {
    const batch = books.slice(i, i + batchSize);
    
    const batchPromises = batch.map(book => 
      getEnhancedBookCover(book.bookId, book.title, book.author)
    );
    
    const batchResults = await Promise.allSettled(batchPromises);
    
    batchResults.forEach((result, index) => {
      if (result.status === 'fulfilled') {
        results.push(result.value);
      } else {
        const book = batch[index];
        results.push({
          bookId: book.bookId,
          title: book.title,
          author: book.author,
          coverUrl: null,
          isValid: false,
          source: 'none',
          loadTime: 0,
          error: result.reason?.message || 'Failed to load cover'
        });
      }
    });
    
    // Small delay between batches to be respectful to APIs
    if (i + batchSize < books.length) {
      await new Promise(resolve => setTimeout(resolve, 500));
    }
  }
  
  const successCount = results.filter(r => r.isValid).length;
  console.log(`Batch load complete: ${successCount}/${books.length} covers loaded successfully`);
  
  return results;
};

/**
 * Generate a fallback cover URL using a placeholder service
 */
export const generateFallbackCover = (title: string, author: string): string => {
  // Use a placeholder service that generates covers based on title/author
  const cleanTitle = encodeURIComponent(title.replace(/[^a-zA-Z0-9\s]/g, ''));
  const cleanAuthor = encodeURIComponent(author.replace(/[^a-zA-Z0-9\s]/g, ''));
  
  return `https://via.placeholder.com/300x400/1f2937/ffffff?text=${cleanTitle}+by+${cleanAuthor}`;
};

/**
 * Get cover loading statistics
 */
export const getCoverLoadingStats = (coverInfos: BookCoverInfo[]) => {
  const total = coverInfos.length;
  const successful = coverInfos.filter(info => info.isValid).length;
  const failed = total - successful;
  const avgLoadTime = coverInfos.reduce((sum, info) => sum + info.loadTime, 0) / total;
  
  const sourceBreakdown = coverInfos.reduce((acc, info) => {
    acc[info.source] = (acc[info.source] || 0) + 1;
    return acc;
  }, {} as Record<string, number>);
  
  return {
    total,
    successful,
    failed,
    successRate: (successful / total) * 100,
    avgLoadTime,
    sourceBreakdown
  };
};

/**
 * Retry failed book covers with different strategies
 */
export const retryFailedCovers = async (
  failedCovers: BookCoverInfo[]
): Promise<BookCoverInfo[]> => {
  console.log(`Retrying ${failedCovers.length} failed covers...`);
  
  const retryResults: BookCoverInfo[] = [];
  
  for (const failedCover of failedCovers) {
    // Clear from cache to force re-fetch
    clearBookCoverFromCache(failedCover.bookId, failedCover.title, failedCover.author);
    
    // Wait a bit before retrying
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    // Try again
    const retryResult = await getEnhancedBookCover(
      failedCover.bookId,
      failedCover.title,
      failedCover.author
    );
    
    retryResults.push(retryResult);
  }
  
  const retrySuccessCount = retryResults.filter(r => r.isValid).length;
  console.log(`Retry complete: ${retrySuccessCount}/${failedCovers.length} covers now successful`);
  
  return retryResults;
};
