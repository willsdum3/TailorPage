// Book cover service using Google Books API and OpenLibrary as fallback
// Note: You'll need to get a Google Books API key from https://console.cloud.google.com/

// Cache for book covers to avoid repeated API calls
const bookCoverCache = new Map<string, string>();

// Clear cache on module load to ensure fresh manual overrides
bookCoverCache.clear();

// Manual overrides for specific books to ensure correct covers
const manualCoverOverrides: Record<string, string> = {
  // High-quality external covers for books that frequently fail
  'mans-search-for-meaning': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/4069.jpg',
  'stillness-is-the-key': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1552071228i/40534532.jpg',
  'wonder': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1317793965i/11387515.jpg',
  'where-crawdads-sing': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1582133854i/36809135.jpg',
  'invisible-cities': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/37435.jpg',
  
  // High-quality external covers for popular books that often fail
  'steve-jobs': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1511288482i/11084145.jpg',
  'atonement': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/6867.jpg',
  'the-goldfinch': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1378714833i/17333223.jpg',
  'beloved': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327959502i/6149.jpg',
  'wild': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/12262741.jpg',
  'midnight-library': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1602190253i/52578297.jpg',
  'seven-husbands-evelyn-hugo': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1674739970i/32620332.jpg',
  'the-alchemist': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1483412266i/865.jpg',
  'normal-people': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1578028274i/41057294.jpg',
  'klara-and-sun': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1602190253i/54120408.jpg',
  'circe': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1529033999i/35959740.jpg',
  'song-of-achilles': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1331154660i/11250317.jpg',
  'little-fires-everywhere': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1494197999i/34273236.jpg',
  
  // Additional covers for books that are still failing
  'kitchen-confidential': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/33313.jpg',
  'secret-history': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/29044.jpg',
  'big-magic': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1440559032i/24453082.jpg',
  'evelyn-hugo': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1674739970i/32620332.jpg',
  'seven-husbands': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1674739970i/32620332.jpg',
  
  // Books from celebrities.ts and other sources that are failing
  'becoming': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1528206996i/38746485.jpg',
  'never-let-me-go': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/6334.jpg',
  'tao-physics': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/18423.jpg',
  'the-tao-of-physics': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/18423.jpg',
  'siddhartha': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/52036.jpg',
  'book-joy': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1451442486i/27209414.jpg',
  'the-book-of-joy': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1451442486i/27209414.jpg',
  'lean-startup': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/10127019.jpg',
  'the-lean-startup': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/10127019.jpg',
  'color-purple': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/37435.jpg',
  'the-color-purple': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/37435.jpg',
  'foundation-series': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/29579.jpg',
  'the-foundation-series': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/29579.jpg',
};

// Google Books API key - replace with your actual API key
const GOOGLE_BOOKS_API_KEY = import.meta.env.VITE_GOOGLE_BOOKS_API_KEY || '';

/**
 * Get cached book cover or fetch from API
 */
export const getBookCover = async (bookId: string, title: string, author: string): Promise<string | null> => {
  // Create a cache key based on title and author to avoid duplicates
  const cacheKey = `${title.toLowerCase()}-${author.toLowerCase()}`;
  
  // Check cache first
  if (bookCoverCache.has(cacheKey)) {
    const cachedUrl = bookCoverCache.get(cacheKey)!;
    if (cachedUrl && cachedUrl.trim() !== '') {
      return cachedUrl;
    }
  }
  
  // Check manual overrides first (most reliable)
  // Try multiple override keys for better matching
  const possibleOverrideKeys = [
    bookId.toLowerCase().replace(/[^a-z0-9]/g, '-'),
    title.toLowerCase().replace(/[^a-z0-9]/g, '-'),
    `${title.toLowerCase().replace(/[^a-z0-9]/g, '-')}-${author.toLowerCase().replace(/[^a-z0-9]/g, '-')}`,
    title.toLowerCase().replace(/[^a-z0-9]/g, '-').replace(/\s+/g, '-'),
    title.toLowerCase().replace(/[^a-z0-9]/g, '-').replace(/\s+/g, ''),
  ];
  
  for (const overrideKey of possibleOverrideKeys) {
    if (manualCoverOverrides[overrideKey]) {
      const overrideUrl = manualCoverOverrides[overrideKey];
      bookCoverCache.set(cacheKey, overrideUrl);
      console.log(`Using manual override for: ${title} by ${author} (key: ${overrideKey})`);
      return overrideUrl;
    }
  }

  // Try Google Books API first, then OpenLibrary with simplified logic
  let coverUrl: string | null = null;
  
  // Try Google Books API
  if (GOOGLE_BOOKS_API_KEY) {
    try {
      const query = `${title} ${author}`;
      const url = `https://www.googleapis.com/books/v1/volumes?q=${encodeURIComponent(query)}&key=${GOOGLE_BOOKS_API_KEY}&maxResults=5`;
      
      const response = await fetch(url);
      if (response.ok) {
        const data = await response.json();
        if (data.items && data.items.length > 0) {
          const book = data.items[0]; // Take the first result
          const imageLinks = book.volumeInfo?.imageLinks;
          if (imageLinks && imageLinks.thumbnail) {
            coverUrl = imageLinks.thumbnail.replace('&edge=curl', '');
            console.log(`Found cover for: ${title} by ${author} using Google Books API`);
          }
        }
      }
    } catch (error) {
      console.warn(`Google Books API failed for ${title} by ${author}:`, error);
    }
  }
  
  // Try OpenLibrary if Google Books failed
  if (!coverUrl) {
    try {
      const query = `${title} ${author}`;
      const url = `https://openlibrary.org/search.json?q=${encodeURIComponent(query)}&limit=10`;
      
      const response = await fetch(url);
      if (response.ok) {
        const data = await response.json();
        if (data.docs && data.docs.length > 0) {
          // Find first book with a cover
          for (const book of data.docs) {
            if (book.cover_i) {
              coverUrl = `https://covers.openlibrary.org/b/id/${book.cover_i}-L.jpg`;
              console.log(`Found cover for: ${title} by ${author} using OpenLibrary`);
              break;
            }
          }
        }
      }
    } catch (error) {
      console.warn(`OpenLibrary failed for ${title} by ${author}:`, error);
    }
  }
  
  // If still no cover found, generate a professional fallback
  if (!coverUrl) {
    const cleanTitle = title.replace(/[^a-zA-Z0-9\s]/g, '').trim();
    const cleanAuthor = author.replace(/[^a-zA-Z0-9\s]/g, '').trim();
    coverUrl = `https://via.placeholder.com/300x400/1f2937/ffffff?text=${encodeURIComponent(cleanTitle)}+by+${encodeURIComponent(cleanAuthor)}`;
    console.log(`Generated fallback cover for: ${title} by ${author}`);
  }
  
  // Cache the result (always cache, even fallback covers)
  bookCoverCache.set(cacheKey, coverUrl);
  
  return coverUrl;
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
export const clearBookCoverFromCache = (bookId: string, title?: string, author?: string): void => {
  if (title && author) {
    // Use title-author key if available
    const cacheKey = `${title.toLowerCase()}-${author.toLowerCase()}`;
    bookCoverCache.delete(cacheKey);
  } else {
    // Fallback to bookId (for backward compatibility)
    bookCoverCache.delete(bookId);
  }
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
