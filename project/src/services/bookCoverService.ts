export interface BookCoverData {
  id: string;
  title: string;
  author: string;
  coverUrl: string;
  thumbnailUrl: string;
  width: number;
  height: number;
  source: 'google' | 'openlibrary' | 'goodreads' | 'amazon' | 'placeholder' | 'manual';
  quality: 'high' | 'medium' | 'low';
  cached: boolean;
  lastUpdated: number;
}

export interface CoverSearchResult {
  success: boolean;
  data?: BookCoverData;
  error?: string;
  source: string;
}

export interface CoverCacheConfig {
  maxMemorySize: number; // MB
  maxDiskSize: number; // MB
  cacheExpiry: number; // hours
  enableProgressiveLoading: boolean;
  enableOfflineSupport: boolean;
  batchSize: number; // Number of concurrent requests
  retryAttempts: number;
  retryDelay: number; // ms
}

class BookCoverService {
  private memoryCache: Map<string, BookCoverData> = new Map();
  private apiCallTracker: Map<string, number> = new Map(); // Track API calls per hour
  private pendingRequests: Map<string, Promise<CoverSearchResult>> = new Map(); // Prevent duplicate requests
  private requestQueue: Array<{ title: string; author: string; resolve: (result: CoverSearchResult) => void; reject: (error: Error) => void }> = [];
  private isProcessingQueue = false;
  
  private config: CoverCacheConfig = {
    maxMemorySize: 100, // Increased to 100MB
    maxDiskSize: 500, // Increased to 500MB
    cacheExpiry: 48, // Increased to 48 hours
    enableProgressiveLoading: true,
    enableOfflineSupport: true,
    batchSize: 5, // Process 5 requests concurrently
    retryAttempts: 3,
    retryDelay: 1000
  };

  private readonly GOOGLE_BOOKS_API_KEY = import.meta.env.VITE_GOOGLE_BOOKS_API_KEY;
  private readonly AMAZON_API_KEY = import.meta.env.VITE_AMAZON_API_KEY;
  private readonly AMAZON_SECRET_KEY = import.meta.env.VITE_AMAZON_SECRET_KEY;
  private readonly AMAZON_ASSOCIATE_TAG = import.meta.env.VITE_AMAZON_ASSOCIATE_TAG;

  // Rate limiting configuration - Increased limits for better performance
  private readonly MAX_GOOGLE_API_CALLS_PER_HOUR = 2000; // Increased from 1000
  private readonly MAX_OPENLIBRARY_CALLS_PER_HOUR = 10000; // Increased from 5000

  // Performance monitoring
  private performanceMetrics = {
    totalRequests: 0,
    cacheHits: 0,
    apiCalls: 0,
    averageResponseTime: 0,
    errors: 0
  };

  constructor(config?: Partial<CoverCacheConfig>) {
    if (config) {
      this.config = { ...this.config, ...config };
    }
    this.initializeCache();
    this.startPerformanceMonitoring();
  }

  private async initializeCache(): Promise<void> {
    if (this.config.enableOfflineSupport && 'caches' in window) {
      try {
        const cache = await caches.open('book-covers-v3'); // Updated cache version
        // Pre-warm cache with frequently accessed covers
        await this.preloadFrequentCovers();
      } catch (error) {
        console.warn('Failed to initialize cache:', error);
      }
    }
  }

  private async preloadFrequentCovers(): Promise<void> {
    const frequentBooks = [
      { title: 'Fourth Wing', author: 'Rebecca Yarros' },
      { title: 'Atomic Habits', author: 'James Clear' },
      { title: 'It Ends with Us', author: 'Colleen Hoover' },
      { title: 'The Midnight Library', author: 'Matt Haig' },
      { title: 'The Seven Husbands of Evelyn Hugo', author: 'Taylor Jenkins Reid' },
      { title: 'Lessons in Chemistry', author: 'Bonnie Garmus' },
      { title: 'Tomorrow, and Tomorrow, and Tomorrow', author: 'Gabrielle Zevin' },
      { title: 'A Court of Thorns and Roses', author: 'Sarah J. Maas' }
    ];

    // Batch preload for better performance
    const batches = this.chunkArray(frequentBooks, 3);
    for (const batch of batches) {
      await Promise.allSettled(
        batch.map(book => this.getBookCover(book.title, book.author))
      );
      // Small delay between batches to avoid overwhelming APIs
      await this.delay(200);
    }
  }

  private chunkArray<T>(array: T[], size: number): T[][] {
    const chunks: T[][] = [];
    for (let i = 0; i < array.length; i += size) {
      chunks.push(array.slice(i, i + size));
    }
    return chunks;
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  private isRateLimited(source: 'google' | 'openlibrary'): boolean {
    const now = Date.now();
    const oneHourAgo = now - (60 * 60 * 1000);
    
    // Clean up old entries
    for (const [key, timestamp] of this.apiCallTracker.entries()) {
      if (timestamp < oneHourAgo) {
        this.apiCallTracker.delete(key);
      }
    }

    const sourceKey = `${source}-${Math.floor(now / (60 * 60 * 1000))}`; // Hour-based key
    const currentCalls = this.apiCallTracker.get(sourceKey) || 0;
    
    const limit = source === 'google' ? this.MAX_GOOGLE_API_CALLS_PER_HOUR : this.MAX_OPENLIBRARY_CALLS_PER_HOUR;
    
    if (currentCalls >= limit) {
      console.warn(`Rate limit reached for ${source} API (${currentCalls}/${limit} calls per hour)`);
      return true;
    }

    this.apiCallTracker.set(sourceKey, currentCalls + 1);
    return false;
  }

  public async getBookCover(title: string, author: string): Promise<CoverSearchResult> {
    const startTime = performance.now();
    this.performanceMetrics.totalRequests++;
    
    console.log(`Getting book cover for: "${title}" by "${author}"`);
    
    const cacheKey = this.generateCacheKey(title, author);
    
    // Check memory cache first
    const cached = this.memoryCache.get(cacheKey);
    if (cached && !this.isExpired(cached.lastUpdated)) {
      this.performanceMetrics.cacheHits++;
      console.log(`Found cached cover for: ${title}`);
      return { success: true, data: cached, source: 'memory-cache' };
    }

    // Check if there's already a pending request for this book
    if (this.pendingRequests.has(cacheKey)) {
      console.log(`Waiting for pending request for: ${title}`);
      return this.pendingRequests.get(cacheKey)!;
    }

    // Create new request promise
    const requestPromise = this.executeBookCoverRequest(title, author, cacheKey);
    this.pendingRequests.set(cacheKey, requestPromise);

    try {
      const result = await requestPromise;
      const endTime = performance.now();
      this.updatePerformanceMetrics(endTime - startTime);
      return result;
    } finally {
      this.pendingRequests.delete(cacheKey);
    }
  }

  private async executeBookCoverRequest(title: string, author: string, cacheKey: string): Promise<CoverSearchResult> {
    // Try multiple sources with intelligent fallback
    const sources = [
      { name: 'Open Library', fn: () => this.searchOpenLibrary(title, author), priority: 1 },
      { name: 'Google Books', fn: () => this.searchGoogleBooks(title, author), priority: 2 },
      { name: 'Placeholder', fn: () => this.generatePlaceholder(title, author), priority: 3 }
    ];

    // Sort by priority and try each source
    sources.sort((a, b) => a.priority - b.priority);

    for (const source of sources) {
      try {
        console.log(`Trying ${source.name} for: ${title}`);
        const result = await this.retryWithBackoff(() => source.fn(), this.config.retryAttempts);
        
        if (result.success && result.data) {
          console.log(`Successfully got cover from ${source.name} for: ${title}`);
          // Cache the result
          this.cacheCover(cacheKey, result.data);
          return result;
        }
      } catch (error) {
        console.warn(`Failed to fetch cover from ${source.name}:`, error);
        this.performanceMetrics.errors++;
        continue;
      }
    }

    // Fallback to placeholder
    console.log(`Using placeholder for: ${title}`);
    const placeholder = await this.generatePlaceholder(title, author);
    this.cacheCover(cacheKey, placeholder.data!);
    return placeholder;
  }

  private async retryWithBackoff<T>(fn: () => Promise<T>, attempts: number): Promise<T> {
    for (let i = 0; i < attempts; i++) {
      try {
        return await fn();
      } catch (error) {
        if (i === attempts - 1) throw error;
        
        const delay = this.config.retryDelay * Math.pow(2, i); // Exponential backoff
        console.log(`Retry ${i + 1}/${attempts} after ${delay}ms`);
        await this.delay(delay);
      }
    }
    throw new Error('All retry attempts failed');
  }

  private async searchGoogleBooks(title: string, author: string): Promise<CoverSearchResult> {
    if (!this.GOOGLE_BOOKS_API_KEY) {
      throw new Error('Google Books API key not configured');
    }

    // Check rate limiting
    if (this.isRateLimited('google')) {
      throw new Error('Google Books API rate limit reached');
    }

    this.performanceMetrics.apiCalls++;

    try {
      const query = encodeURIComponent(`${title} ${author}`);
      const url = `https://www.googleapis.com/books/v1/volumes?q=${query}&key=${this.GOOGLE_BOOKS_API_KEY}&maxResults=1`;

      console.log(`Fetching from Google Books: ${url}`);
      
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 10000); // 10 second timeout
      
      const response = await fetch(url, { 
        signal: controller.signal,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'TailorPage/1.0'
        }
      });
      
      clearTimeout(timeoutId);
      
      if (!response.ok) {
        if (response.status === 429) {
          throw new Error('Google Books API rate limit exceeded (429)');
        }
        throw new Error(`Google Books API error: ${response.status} ${response.statusText}`);
      }
      
      const data = await response.json();
      console.log('Google Books response:', data);

      if (data.items && data.items[0]?.volumeInfo?.imageLinks) {
        const book = data.items[0];
        const imageLinks = book.volumeInfo.imageLinks;
        
        // Get the highest quality image available
        const coverUrl = imageLinks.extraLarge || 
                        imageLinks.large || 
                        imageLinks.medium || 
                        imageLinks.small ||
                        imageLinks.thumbnail;

        if (coverUrl) {
          // Ensure HTTPS
          const finalUrl = coverUrl.replace('http://', 'https://');
          console.log(`Found cover URL: ${finalUrl}`);
          
          return {
            success: true,
            data: {
              id: book.id,
              title: book.volumeInfo.title,
              author: book.volumeInfo.authors?.[0] || author,
              coverUrl: finalUrl,
              thumbnailUrl: finalUrl,
              width: 600,
              height: 900,
              source: 'google',
              quality: this.determineQuality(coverUrl),
              cached: false,
              lastUpdated: Date.now()
            },
            source: 'google-books'
          };
        }
      }

      throw new Error('No cover found in Google Books');
    } catch (error) {
      console.error('Google Books API error:', error);
      throw error;
    }
  }

  private async searchOpenLibrary(title: string, author: string): Promise<CoverSearchResult> {
    // Check rate limiting
    if (this.isRateLimited('openlibrary')) {
      throw new Error('Open Library API rate limit reached');
    }

    this.performanceMetrics.apiCalls++;

    try {
      // Try different search strategies with better matching
      const searchQueries = [
        `${title} ${author}`,
        title,
        `${title} author:${author}`,
        `${title} by ${author}`,
        `${title} ${author.split(' ')[0]}` // Try with first name only
      ];

      for (const query of searchQueries) {
        try {
          const encodedQuery = encodeURIComponent(query);
          const url = `https://openlibrary.org/search.json?q=${encodedQuery}&limit=5&fields=key,title,author_name,cover_i`;

          console.log(`Fetching from Open Library: ${url}`);
          
          const controller = new AbortController();
          const timeoutId = setTimeout(() => controller.abort(), 8000); // 8 second timeout
          
          const response = await fetch(url, { 
            signal: controller.signal,
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'TailorPage/1.0'
            }
          });
          
          clearTimeout(timeoutId);
          
          if (!response.ok) {
            console.warn(`Open Library API error for query "${query}": ${response.status} ${response.statusText}`);
            continue;
          }
          
          const data = await response.json();
          console.log(`Open Library response for "${query}":`, data);

          if (data.docs && data.docs.length > 0) {
            // Find the best match using improved matching logic
            const bestMatch = this.findBestOpenLibraryMatch(data.docs, title, author);

            if (bestMatch) {
              const book = bestMatch;
              const coverId = book.cover_i;
              const coverUrl = `https://covers.openlibrary.org/b/id/${coverId}-L.jpg`;

              console.log(`Found Open Library cover URL: ${coverUrl}`);

              return {
                success: true,
                data: {
                  id: book.key,
                  title: book.title,
                  author: book.author_name[0],
                  coverUrl,
                  thumbnailUrl: `https://covers.openlibrary.org/b/id/${coverId}-M.jpg`,
                  width: 600,
                  height: 900,
                  source: 'openlibrary',
                  quality: 'high',
                  cached: false,
                  lastUpdated: Date.now()
                },
                source: 'open-library'
              };
            }
          }
        } catch (error) {
          console.warn(`Open Library search failed for query "${query}":`, error);
          continue;
        }
      }

      throw new Error('No cover found in Open Library');
    } catch (error) {
      console.error('Open Library API error:', error);
      throw error;
    }
  }

  private findBestOpenLibraryMatch(docs: any[], title: string, author: string): any {
    // Improved matching algorithm
    const titleLower = title.toLowerCase();
    const authorLower = author.toLowerCase();
    
    return docs.find((doc: any) => {
      if (!doc.cover_i || !doc.title || !doc.author_name || doc.author_name.length === 0) {
        return false;
      }

      const docTitle = doc.title.toLowerCase();
      const docAuthor = doc.author_name[0].toLowerCase();
      
      // Exact match gets highest priority
      if (docTitle === titleLower && docAuthor === authorLower) {
        return true;
      }
      
      // Partial title match with author match
      if (docTitle.includes(titleLower) && docAuthor.includes(authorLower)) {
        return true;
      }
      
      // Title match with partial author match
      if (docTitle.includes(titleLower) && authorLower.includes(docAuthor.split(' ')[0])) {
        return true;
      }
      
      return false;
    }) || docs[0]; // Fallback to first result if no good match
  }

  private async searchGoodreads(title: string, author: string): Promise<CoverSearchResult> {
    // Goodreads API is deprecated, but we can try to scrape their website
    // This is a simplified implementation
    const query = encodeURIComponent(`${title} ${author}`);
    const url = `https://www.goodreads.com/search?q=${query}`;

    try {
      // Note: This would require a proxy service due to CORS restrictions
      // For now, we'll throw an error to fall back to other sources
      throw new Error('Goodreads API not implemented');
    } catch (error) {
      throw new Error('No cover found in Goodreads');
    }
  }

  private async searchAmazon(title: string, author: string): Promise<CoverSearchResult> {
    if (!this.AMAZON_API_KEY || !this.AMAZON_SECRET_KEY) {
      throw new Error('Amazon API credentials not configured');
    }

    // Amazon Product Advertising API implementation
    // This is a simplified version - full implementation would require proper AWS SDK
    const query = encodeURIComponent(`${title} ${author}`);
    
    // For now, we'll use a placeholder implementation
    // In production, you would use the AWS SDK to make proper API calls
    throw new Error('Amazon API not fully implemented');
  }

  private async generatePlaceholder(title: string, author: string): Promise<CoverSearchResult> {
    // Generate a beautiful placeholder cover
    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d')!;
    
    canvas.width = 600;
    canvas.height = 900;

    // Create gradient background
    const gradient = ctx.createLinearGradient(0, 0, 600, 900);
    gradient.addColorStop(0, '#1e293b');
    gradient.addColorStop(1, '#334155');
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, 600, 900);

    // Add decorative elements
    ctx.fillStyle = 'rgba(251, 191, 36, 0.1)';
    ctx.fillRect(50, 50, 500, 800);

    // Add title
    ctx.fillStyle = '#ffffff';
    ctx.font = 'bold 32px Arial';
    ctx.textAlign = 'center';
    
    const words = title.split(' ');
    let y = 300;
    for (const word of words) {
      ctx.fillText(word, 300, y);
      y += 40;
    }

    // Add author
    ctx.fillStyle = '#fbbf24';
    ctx.font = '24px Arial';
    ctx.fillText(`by ${author}`, 300, y + 40);

    // Add decorative line
    ctx.strokeStyle = '#fbbf24';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(100, y + 80);
    ctx.lineTo(500, y + 80);
    ctx.stroke();

    const dataUrl = canvas.toDataURL('image/jpeg', 0.8);

    return {
      success: true,
      data: {
        id: this.generateCacheKey(title, author),
        title,
        author,
        coverUrl: dataUrl,
        thumbnailUrl: dataUrl,
        width: 600,
        height: 900,
        source: 'placeholder',
        quality: 'medium',
        cached: false,
        lastUpdated: Date.now()
      },
      source: 'placeholder'
    };
  }

  private generateCacheKey(title: string, author: string): string {
    return `${title.toLowerCase().replace(/[^a-z0-9]/g, '')}-${author.toLowerCase().replace(/[^a-z0-9]/g, '')}`;
  }

  private determineQuality(coverUrl: string): 'high' | 'medium' | 'low' {
    if (coverUrl.includes('extraLarge') || coverUrl.includes('-L.jpg')) {
      return 'high';
    } else if (coverUrl.includes('large') || coverUrl.includes('-M.jpg')) {
      return 'medium';
    } else {
      return 'low';
    }
  }

  private isExpired(timestamp: number): boolean {
    const expiryTime = this.config.cacheExpiry * 60 * 60 * 1000; // Convert hours to milliseconds
    return Date.now() - timestamp > expiryTime;
  }

  private cacheCover(key: string, data: BookCoverData): void {
    // Check memory cache size
    if (this.memoryCache.size > 100) { // Limit to 100 items
      const firstKey = this.memoryCache.keys().next().value;
      if (firstKey) {
        this.memoryCache.delete(firstKey);
      }
    }

    this.memoryCache.set(key, data);

    // Also cache in browser cache if available
    if (this.config.enableOfflineSupport && 'caches' in window) {
      this.cacheInBrowser(data).catch(console.warn);
    }
  }

  private async cacheInBrowser(data: BookCoverData): Promise<void> {
    try {
      const cache = await caches.open('book-covers-v3');
      const response = await fetch(data.coverUrl);
      await cache.put(data.coverUrl, response);
    } catch (error) {
      console.warn('Failed to cache cover in browser:', error);
    }
  }

  public async preloadCovers(books: Array<{ title: string; author: string }>): Promise<void> {
    const promises = books.map(book => 
      this.getBookCover(book.title, book.author).catch(() => {
        // Silently fail for preloading
      })
    );
    
    await Promise.allSettled(promises);
  }

  public clearCache(): void {
    this.memoryCache.clear();
    this.apiCallTracker.clear();
    if ('caches' in window) {
      caches.delete('book-covers-v3').catch(console.warn);
    }
  }

  public getCacheStats(): { memorySize: number; diskSize?: number; apiCalls: number } {
    const memorySize = this.memoryCache.size;
    const apiCalls = Array.from(this.apiCallTracker.values()).reduce((sum, count) => sum + count, 0);
    return { memorySize, apiCalls };
  }

  public getRateLimitStatus(): { google: { current: number; limit: number }; openlibrary: { current: number; limit: number } } {
    const now = Date.now();
    
    const googleKey = `google-${Math.floor(now / (60 * 60 * 1000))}`;
    const openlibraryKey = `openlibrary-${Math.floor(now / (60 * 60 * 1000))}`;
    
    return {
      google: {
        current: this.apiCallTracker.get(googleKey) || 0,
        limit: this.MAX_GOOGLE_API_CALLS_PER_HOUR
      },
      openlibrary: {
        current: this.apiCallTracker.get(openlibraryKey) || 0,
        limit: this.MAX_OPENLIBRARY_CALLS_PER_HOUR
      }
    };
  }

  private startPerformanceMonitoring(): void {
    setInterval(() => {
      if (this.performanceMetrics.totalRequests > 0) {
        console.log('Performance Metrics:', this.performanceMetrics);
      }
    }, 30000); // Log every 30 seconds instead of every second
  }

  private updatePerformanceMetrics(responseTime: number): void {
    this.performanceMetrics.averageResponseTime = (
      (this.performanceMetrics.averageResponseTime * this.performanceMetrics.totalRequests) +
      responseTime
    ) / (this.performanceMetrics.totalRequests + 1);
  }
}

// Export singleton instance
export const bookCoverService = new BookCoverService();
