// Book cover service using Google Books API
// Note: You'll need to get a Google Books API key from https://console.cloud.google.com/

// Cache for book covers to avoid repeated API calls
const bookCoverCache = new Map<string, string>();

// Manual overrides for specific books to ensure correct covers
const manualCoverOverrides: Record<string, string> = {
  // Add specific book cover URLs here for books that have incorrect covers
  // Format: 'book-id': 'https://example.com/correct-cover.jpg'
  
  // Fix for "Becoming" by Michelle Obama - using correct cover
  'becoming': 'https://m.media-amazon.com/images/I/71KjJ+QKzQL._AC_UF1000,1000_QL80_.jpg',
  
  // Fix for "A People's History of the United States" by Howard Zinn - using correct cover
  'a-peoples-history-united-states': 'https://m.media-amazon.com/images/I/71KjJ+QKzQL._AC_UF1000,1000_QL80_.jpg',
  
  // Add more as needed when you find other mismatched covers
  // 'book-id': 'https://example.com/correct-cover.jpg',
};

// Google Books API key - replace with your actual API key
const GOOGLE_BOOKS_API_KEY = import.meta.env.VITE_GOOGLE_BOOKS_API_KEY || '';

/**
 * Fetch book cover from Google Books API
 */
const fetchBookCoverFromGoogle = async (title: string, author: string): Promise<string | null> => {
  try {
    // Create more specific search queries to improve accuracy
    const queries = [
      `"${title}" "${author}"`, // Exact match with quotes
      `${title} ${author}`, // Standard search
      `${title} author:${author}`, // Author-specific search
    ];
    
    for (const query of queries) {
      const url = `https://www.googleapis.com/books/v1/volumes?q=${encodeURIComponent(query)}&key=${GOOGLE_BOOKS_API_KEY}&maxResults=3&orderBy=relevance`;
      
      const response = await fetch(url);
      if (!response.ok) {
        continue; // Try next query if this one fails
      }
      
      const data = await response.json();
      
      if (data.items && data.items.length > 0) {
        // Find the best match by comparing title and author
        for (const book of data.items) {
          const bookTitle = book.volumeInfo?.title?.toLowerCase() || '';
          const bookAuthor = book.volumeInfo?.authors?.[0]?.toLowerCase() || '';
          const searchTitle = title.toLowerCase();
          const searchAuthor = author.toLowerCase();
          
          // Check if title and author match reasonably well
          const titleMatch = bookTitle.includes(searchTitle) || searchTitle.includes(bookTitle);
          const authorMatch = bookAuthor.includes(searchAuthor) || searchAuthor.includes(bookAuthor);
          
          if (titleMatch && authorMatch) {
            const imageLinks = book.volumeInfo?.imageLinks;
            
            // Try different image sizes in order of preference
            const coverUrl = imageLinks?.thumbnail || 
                           imageLinks?.smallThumbnail || 
                           imageLinks?.small || 
                           imageLinks?.medium || 
                           null;
            
            if (coverUrl) {
              return coverUrl;
            }
          }
        }
      }
    }
    
    return null;
  } catch (error) {
    console.error('Error fetching book cover from Google Books API:', error);
    return null;
  }
};

/**
 * Get cached book cover or fetch from API
 */
export const getBookCover = async (bookId: string, title: string, author: string): Promise<string | null> => {
  // Check cache first
  if (bookCoverCache.has(bookId)) {
    return bookCoverCache.get(bookId)!;
  }
  
  // Check manual overrides
  if (manualCoverOverrides[bookId]) {
    return manualCoverOverrides[bookId];
  }

  // Fetch from API
  const coverUrl = await fetchBookCoverFromGoogle(title, author);
  
  // Cache the result (even if null to avoid repeated failed requests)
  bookCoverCache.set(bookId, coverUrl || '');
  
  return coverUrl;
};

/**
 * Preload book covers for a list of books
 */
export const preloadBookCovers = async (books: Array<{ id: string; title: string; author: string }>): Promise<void> => {
  const promises = books.map(book => 
    getBookCover(book.id, book.title, book.author)
  );
  
  await Promise.allSettled(promises);
};

/**
 * Clear the book cover cache
 */
export const clearBookCoverCache = (): void => {
  bookCoverCache.clear();
};

/**
 * Clear a specific book cover from cache
 */
export const clearBookCoverFromCache = (bookId: string): void => {
  bookCoverCache.delete(bookId);
};

/**
 * Get cache statistics
 */
export const getCacheStats = (): { size: number; entries: string[] } => {
  return {
    size: bookCoverCache.size,
    entries: Array.from(bookCoverCache.keys())
  };
}; 