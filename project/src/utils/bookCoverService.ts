// Book cover service using Google Books API
// Note: You'll need to get a Google Books API key from https://console.cloud.google.com/

// Cache for book covers to avoid repeated API calls
const bookCoverCache = new Map<string, string>();

// Google Books API key - replace with your actual API key
const GOOGLE_BOOKS_API_KEY = process.env.REACT_APP_GOOGLE_BOOKS_API_KEY || '';

/**
 * Fetch book cover from Google Books API
 */
const fetchBookCoverFromGoogle = async (title: string, author: string): Promise<string | null> => {
  try {
    const query = `${title} ${author}`;
    const url = `https://www.googleapis.com/books/v1/volumes?q=${encodeURIComponent(query)}&key=${GOOGLE_BOOKS_API_KEY}&maxResults=1`;
    
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    const data = await response.json();
    
    if (data.items && data.items.length > 0) {
      const book = data.items[0];
      const imageLinks = book.volumeInfo?.imageLinks;
      
      // Try different image sizes in order of preference
      return imageLinks?.thumbnail || 
             imageLinks?.smallThumbnail || 
             imageLinks?.small || 
             imageLinks?.medium || 
             null;
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
 * Get cache statistics
 */
export const getCacheStats = (): { size: number; entries: string[] } => {
  return {
    size: bookCoverCache.size,
    entries: Array.from(bookCoverCache.keys())
  };
}; 