import { BookSummaryData } from '../components/BookSummaryModal';

// Cache for book information to avoid repeated API calls
const bookInfoCache = new Map<string, BookSummaryData>();
const CACHE_EXPIRY = 24 * 60 * 60 * 1000; // 24 hours

interface CachedBookInfo {
  data: BookSummaryData;
  timestamp: number;
}

export class BookInfoService {
  private static instance: BookInfoService;
  private pendingRequests = new Map<string, Promise<BookSummaryData>>();

  static getInstance(): BookInfoService {
    if (!BookInfoService.instance) {
      BookInfoService.instance = new BookInfoService();
    }
    return BookInfoService.instance;
  }

  private getCacheKey(title: string, author: string): string {
    return `${title.toLowerCase()}-${author.toLowerCase()}`;
  }

  private isCacheValid(timestamp: number): boolean {
    return Date.now() - timestamp < CACHE_EXPIRY;
  }

  async getBookInfo(title: string, author: string): Promise<BookSummaryData> {
    const cacheKey = this.getCacheKey(title, author);

    // Check cache first
    const cached = bookInfoCache.get(cacheKey);
    if (cached && this.isCacheValid(cached.timestamp)) {
      console.log('Book info found in cache for:', title);
      return cached.data;
    }

    // Check if there's already a pending request
    if (this.pendingRequests.has(cacheKey)) {
      console.log('Using pending request for:', title);
      return this.pendingRequests.get(cacheKey)!;
    }

    // Create new request
    const requestPromise = this.fetchBookInfo(title, author);
    this.pendingRequests.set(cacheKey, requestPromise);

    try {
      const result = await requestPromise;
      
      // Cache the result
      bookInfoCache.set(cacheKey, {
        data: result,
        timestamp: Date.now()
      });

      return result;
    } finally {
      this.pendingRequests.delete(cacheKey);
    }
  }

  private async fetchBookInfo(title: string, author: string): Promise<BookSummaryData> {
    console.log('Fetching book info for:', title, 'by', author);

    // Try Google Books API first
    try {
      const googleData = await this.fetchFromGoogleBooks(title, author);
      if (googleData) {
        return googleData;
      }
    } catch (error) {
      console.log('Google Books API failed for:', title, error);
    }

    // Try Open Library API as fallback
    try {
      const openLibraryData = await this.fetchFromOpenLibrary(title, author);
      if (openLibraryData) {
        return openLibraryData;
      }
    } catch (error) {
      console.log('Open Library API failed for:', title, error);
    }

    // Return basic info if no API data available
    return this.createBasicBookInfo(title, author);
  }

  private async fetchFromGoogleBooks(title: string, author: string): Promise<BookSummaryData | null> {
    const query = encodeURIComponent(`${title} ${author}`);
    const url = `https://www.googleapis.com/books/v1/volumes?q=${query}&maxResults=1`;

    try {
      const response = await fetch(url);
      if (!response.ok) throw new Error('Google Books API request failed');

      const data = await response.json();
      
      if (data.items && data.items.length > 0) {
        const book = data.items[0];
        const volumeInfo = book.volumeInfo;
        const saleInfo = book.saleInfo;

        return {
          title: volumeInfo.title || title,
          author: volumeInfo.authors?.[0] || author,
          description: volumeInfo.description,
          genre: volumeInfo.categories?.[0],
          publishedYear: volumeInfo.publishedDate ? new Date(volumeInfo.publishedDate).getFullYear() : undefined,
          rating: volumeInfo.averageRating,
          reviewCount: volumeInfo.ratingsCount,
          pageCount: volumeInfo.pageCount,
          isbn: volumeInfo.industryIdentifiers?.[0]?.identifier,
          publisher: volumeInfo.publisher,
          language: volumeInfo.language,
          amazonLink: saleInfo?.buyLink || this.generateAmazonLink(title, author)
        };
      }
    } catch (error) {
      console.log('Error fetching from Google Books:', error);
    }

    return null;
  }

  private async fetchFromOpenLibrary(title: string, author: string): Promise<BookSummaryData | null> {
    const query = encodeURIComponent(`${title} ${author}`);
    const url = `https://openlibrary.org/search.json?q=${query}&limit=1`;

    try {
      const response = await fetch(url);
      if (!response.ok) throw new Error('Open Library API request failed');

      const data = await response.json();
      
      if (data.docs && data.docs.length > 0) {
        const book = data.docs[0];

        return {
          title: book.title || title,
          author: book.author_name?.[0] || author,
          description: book.description,
          genre: book.subject?.[0],
          publishedYear: book.first_publish_year,
          rating: book.ratings_average,
          reviewCount: book.ratings_count,
          pageCount: book.number_of_pages_median,
          isbn: book.isbn?.[0],
          publisher: book.publisher?.[0],
          language: book.language?.[0],
          amazonLink: this.generateAmazonLink(title, author)
        };
      }
    } catch (error) {
      console.log('Error fetching from Open Library:', error);
    }

    return null;
  }

  private createBasicBookInfo(title: string, author: string): BookSummaryData {
    return {
      title,
      author,
      description: `A book by ${author}. Click to learn more about this title.`,
      amazonLink: this.generateAmazonLink(title, author)
    };
  }

  private generateAmazonLink(title: string, author: string): string {
    const searchQuery = encodeURIComponent(`${title} ${author}`);
    return `https://www.amazon.com/s?k=${searchQuery}`;
  }

  // Clear cache (useful for testing or memory management)
  clearCache(): void {
    bookInfoCache.clear();
    this.pendingRequests.clear();
  }

  // Get cache statistics
  getCacheStats(): { size: number; keys: string[] } {
    return {
      size: bookInfoCache.size,
      keys: Array.from(bookInfoCache.keys())
    };
  }
}

export const bookInfoService = BookInfoService.getInstance();
