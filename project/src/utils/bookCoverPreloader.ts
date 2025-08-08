// High-Performance Book Cover Preloader
// Loads covers in parallel with aggressive caching for instant loading

import { getBookCover, clearBookCoverFromCache } from './bookCoverService';

export interface PreloadRequest {
  bookId: string;
  title: string;
  author: string;
}

export interface PreloadResult {
  bookId: string;
  title: string;
  author: string;
  coverUrl: string | null;
  success: boolean;
  loadTime: number;
  error?: string;
}

export interface PreloadStats {
  total: number;
  successful: number;
  failed: number;
  averageLoadTime: number;
  totalLoadTime: number;
}

class BookCoverPreloader {
  private preloadCache = new Map<string, Promise<string | null>>();
  private resultCache = new Map<string, { url: string | null; timestamp: number }>();
  private batchSize = 5; // Load 5 covers at once to avoid overwhelming APIs
  private cacheExpiry = 24 * 60 * 60 * 1000; // 24 hours

  /**
   * Preload a single book cover with caching
   */
  async preloadSingle(request: PreloadRequest): Promise<PreloadResult> {
    const startTime = Date.now();
    const cacheKey = this.generateCacheKey(request.title, request.author);
    
    try {
      // Check if we already have a result cached
      const cached = this.resultCache.get(cacheKey);
      if (cached && (Date.now() - cached.timestamp) < this.cacheExpiry) {
        return {
          bookId: request.bookId,
          title: request.title,
          author: request.author,
          coverUrl: cached.url,
          success: !!cached.url,
          loadTime: 0 // Instant from cache
        };
      }

      // Check if we're already loading this cover
      if (this.preloadCache.has(cacheKey)) {
        const url = await this.preloadCache.get(cacheKey)!;
        const loadTime = Date.now() - startTime;
        
        // Cache the result
        this.resultCache.set(cacheKey, { url, timestamp: Date.now() });
        
        return {
          bookId: request.bookId,
          title: request.title,
          author: request.author,
          coverUrl: url,
          success: !!url,
          loadTime
        };
      }

      // Start loading the cover
      const loadPromise = this.loadCoverWithFallback(request.title, request.author);
      this.preloadCache.set(cacheKey, loadPromise);
      
      const url = await loadPromise;
      const loadTime = Date.now() - startTime;
      
      // Cache the result
      this.resultCache.set(cacheKey, { url, timestamp: Date.now() });
      
      // Clean up the loading promise
      this.preloadCache.delete(cacheKey);
      
      return {
        bookId: request.bookId,
        title: request.title,
        author: request.author,
        coverUrl: url,
        success: !!url,
        loadTime
      };
      
    } catch (error) {
      const loadTime = Date.now() - startTime;
      this.preloadCache.delete(cacheKey);
      
      return {
        bookId: request.bookId,
        title: request.title,
        author: request.author,
        coverUrl: null,
        success: false,
        loadTime,
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }

  /**
   * Preload multiple book covers in parallel batches
   */
  async preloadMultiple(requests: PreloadRequest[]): Promise<PreloadResult[]> {
    console.log(`🚀 Preloading ${requests.length} book covers in parallel...`);
    const startTime = Date.now();
    const results: PreloadResult[] = [];
    
    // Process in batches to avoid overwhelming APIs
    for (let i = 0; i < requests.length; i += this.batchSize) {
      const batch = requests.slice(i, i + this.batchSize);
      const batchPromises = batch.map(request => this.preloadSingle(request));
      
      const batchResults = await Promise.allSettled(batchPromises);
      
      for (const result of batchResults) {
        if (result.status === 'fulfilled') {
          results.push(result.value);
        } else {
          // Handle rejected promises
          results.push({
            bookId: 'unknown',
            title: 'unknown',
            author: 'unknown',
            coverUrl: null,
            success: false,
            loadTime: 0,
            error: result.reason?.message || 'Promise rejected'
          });
        }
      }
      
      // Small delay between batches to be respectful to APIs
      if (i + this.batchSize < requests.length) {
        await new Promise(resolve => setTimeout(resolve, 100));
      }
    }
    
    const totalTime = Date.now() - startTime;
    console.log(`✅ Preloaded ${results.length} covers in ${totalTime}ms`);
    
    return results;
  }

  /**
   * Get preload statistics
   */
  getStats(): PreloadStats {
    const successful = Array.from(this.resultCache.values()).filter(r => r.url).length;
    const total = this.resultCache.size;
    const failed = total - successful;
    
    return {
      total,
      successful,
      failed,
      averageLoadTime: 0, // We don't track individual load times in cache
      totalLoadTime: 0
    };
  }

  /**
   * Clear the preload cache
   */
  clearCache(): void {
    this.preloadCache.clear();
    this.resultCache.clear();
  }

  /**
   * Get a cached cover URL instantly (if available)
   */
  getCachedCover(title: string, author: string): string | null {
    const cacheKey = this.generateCacheKey(title, author);
    const cached = this.resultCache.get(cacheKey);
    
    if (cached && (Date.now() - cached.timestamp) < this.cacheExpiry) {
      return cached.url;
    }
    
    return null;
  }

  /**
   * Check if a cover is currently being loaded
   */
  isLoading(title: string, author: string): boolean {
    const cacheKey = this.generateCacheKey(title, author);
    return this.preloadCache.has(cacheKey);
  }

  /**
   * Load cover with immediate fallback
   */
  private async loadCoverWithFallback(title: string, author: string): Promise<string | null> {
    try {
      // Try the main service first
      const url = await getBookCover('temp-id', title, author);
      
      if (url) {
        return url;
      }
      
      // Immediate fallback
      const cleanTitle = title.replace(/[^a-zA-Z0-9\s]/g, '').trim();
      const cleanAuthor = author.replace(/[^a-zA-Z0-9\s]/g, '').trim();
      return `https://via.placeholder.com/300x400/1f2937/ffffff?text=${encodeURIComponent(cleanTitle)}+by+${encodeURIComponent(cleanAuthor)}`;
      
    } catch (error) {
      // Fallback on any error
      const cleanTitle = title.replace(/[^a-zA-Z0-9\s]/g, '').trim();
      const cleanAuthor = author.replace(/[^a-zA-Z0-9\s]/g, '').trim();
      return `https://via.placeholder.com/300x400/1f2937/ffffff?text=${encodeURIComponent(cleanTitle)}+by+${encodeURIComponent(cleanAuthor)}`;
    }
  }

  /**
   * Generate a consistent cache key
   */
  private generateCacheKey(title: string, author: string): string {
    return `${title.toLowerCase().trim()}-${author.toLowerCase().trim()}`;
  }
}

// Export singleton instance
export const bookCoverPreloader = new BookCoverPreloader();

/**
 * Preload covers for a list of books (convenience function)
 */
export const preloadBookCovers = async (books: Array<{ id: string; title: string; author: string }>): Promise<PreloadResult[]> => {
  const requests: PreloadRequest[] = books.map(book => ({
    bookId: book.id,
    title: book.title,
    author: book.author
  }));
  
  return bookCoverPreloader.preloadMultiple(requests);
};

/**
 * Get a cached cover instantly
 */
export const getCachedBookCover = (title: string, author: string): string | null => {
  return bookCoverPreloader.getCachedCover(title, author);
};

/**
 * Check if a cover is currently loading
 */
export const isBookCoverLoading = (title: string, author: string): boolean => {
  return bookCoverPreloader.isLoading(title, author);
};
