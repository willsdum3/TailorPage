// Book cover service using Google Books API and OpenLibrary as fallback
// Note: You'll need to get a Google Books API key from https://console.cloud.google.com/

// Cache for book covers to avoid repeated API calls
const bookCoverCache = new Map<string, string>();

// Manual overrides for specific books to ensure correct covers
const manualCoverOverrides: Record<string, string> = {
  // Local book covers from public folder
  'mans-search-for-meaning': '/book-covers/MansSearchForMeaning.jpg',
  'stillness-is-the-key': '/book-covers/StillnessIsTheKey.jpg',
  'wonder': '/book-covers/Wonder.jpg',
  'where-the-crawdads-sing': '/book-covers/WhereTheCrawdadsSing.jpg',
  'invisible-cities': '/book-covers/InvisibleCities.jpg',
  
  // High-quality external covers for popular books that often fail
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
  
  // Additional covers for books that are still failing
  'kitchen-confidential': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/33313.jpg',
  'secret-history': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/29044.jpg',
  'big-magic': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1440559032i/24453082.jpg',
  'evelyn-hugo': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1674739970i/32620332.jpg',
  'seven-husbands': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1674739970i/32620332.jpg',
  
  // Add more as needed when you find other mismatched covers
  // 'book-id': 'https://example.com/correct-cover.jpg',
};

// Google Books API key - replace with your actual API key
const GOOGLE_BOOKS_API_KEY = import.meta.env.VITE_GOOGLE_BOOKS_API_KEY || '';

/**
 * Clean and normalize book title for better search results
 */
const normalizeTitle = (title: string): string => {
  return title
    .toLowerCase()
    .replace(/[^\w\s]/g, '') // Remove special characters
    .replace(/\s+/g, ' ') // Normalize whitespace
    .trim();
};

/**
 * Clean and normalize author name for better search results
 */
const normalizeAuthor = (author: string): string => {
  return author
    .toLowerCase()
    .replace(/[^\w\s]/g, '') // Remove special characters
    .replace(/\s+/g, ' ') // Normalize whitespace
    .trim();
};

/**
 * Calculate similarity score between two strings
 */
const calculateSimilarity = (str1: string, str2: string): number => {
  const words1 = str1.split(' ').filter(word => word.length > 2);
  const words2 = str2.split(' ').filter(word => word.length > 2);
  
  if (words1.length === 0 || words2.length === 0) return 0;
  
  const commonWords = words1.filter(word => words2.includes(word));
  return commonWords.length / Math.max(words1.length, words2.length);
};

/**
 * Fetch book cover from OpenLibrary API with improved search strategies
 */
const fetchBookCoverFromOpenLibrary = async (title: string, author: string): Promise<string | null> => {
  try {
    const normalizedTitle = normalizeTitle(title);
    const normalizedAuthor = normalizeAuthor(author);
    
    // Create multiple search strategies to improve coverage
    const searchStrategies = [
      // Strategy 1: Exact title and author match
      `https://openlibrary.org/search.json?title=${encodeURIComponent(title)}&author=${encodeURIComponent(author)}&limit=20`,
      // Strategy 2: Title only with more results
      `https://openlibrary.org/search.json?title=${encodeURIComponent(title)}&limit=20`,
      // Strategy 3: Author only for books with different titles
      `https://openlibrary.org/search.json?author=${encodeURIComponent(author)}&limit=20`,
      // Strategy 4: Combined search
      `https://openlibrary.org/search.json?q=${encodeURIComponent(`${title} ${author}`)}&limit=20`,
      // Strategy 5: ISBN search if available (future enhancement)
    ];

    let bestMatch: { book: any; score: number; coverUrl: string } | null = null;

    for (const url of searchStrategies) {
      const response = await fetch(url);
      if (!response.ok) {
        continue;
      }
      
      const data = await response.json();
      
      if (data.docs && data.docs.length > 0) {
        // Find the best match using multiple criteria
        for (const book of data.docs) {
          if (!book.cover_i) continue; // Skip books without covers
          
          const bookTitle = normalizeTitle(book.title || '');
          const bookAuthor = normalizeAuthor(book.author_name?.[0] || '');
          
          // Calculate similarity scores
          const titleSimilarity = calculateSimilarity(normalizedTitle, bookTitle);
          const authorSimilarity = calculateSimilarity(normalizedAuthor, bookAuthor);
          
          // Combined score (weighted towards title match)
          const combinedScore = (titleSimilarity * 0.7) + (authorSimilarity * 0.3);
          
          // Only consider matches with reasonable similarity
          if (combinedScore > 0.3) {
            const coverUrl = `https://covers.openlibrary.org/b/id/${book.cover_i}-L.jpg`;
            
            // Update best match if this score is higher
            if (!bestMatch || combinedScore > bestMatch.score) {
              bestMatch = {
                book,
                score: combinedScore,
                coverUrl
              };
            }
          }
        }
      }
    }
    
    return bestMatch?.coverUrl || null;
  } catch (error) {
    console.error('Error fetching book cover from OpenLibrary:', error);
    return null;
  }
};

/**
 * Fetch book cover from Google Books API with improved search
 */
const fetchBookCoverFromGoogle = async (title: string, author: string): Promise<string | null> => {
  // Check if API key is available
  if (!GOOGLE_BOOKS_API_KEY) {
    console.warn('Google Books API key not configured. Skipping Google Books API.');
    return null;
  }

  try {
    const normalizedTitle = normalizeTitle(title);
    const normalizedAuthor = normalizeAuthor(author);
    
    // Create more specific search queries to improve accuracy
    const queries = [
      `"${title}" "${author}"`, // Exact match with quotes
      `${title} ${author}`, // Standard search
      `intitle:${title} inauthor:${author}`, // Google Books specific syntax
      `${title} author:${author}`, // Author-specific search
      `${title}`, // Title only (fallback)
    ];
    
    let bestMatch: { book: any; score: number; coverUrl: string } | null = null;
    
    for (const query of queries) {
      const url = `https://www.googleapis.com/books/v1/volumes?q=${encodeURIComponent(query)}&key=${GOOGLE_BOOKS_API_KEY}&maxResults=10&orderBy=relevance`;
      
      const response = await fetch(url);
      if (!response.ok) {
        continue; // Try next query if this one fails
      }
      
      const data = await response.json();
      
      if (data.items && data.items.length > 0) {
        // Find the best match by comparing title and author
        for (const book of data.items) {
          const bookTitle = normalizeTitle(book.volumeInfo?.title || '');
          const bookAuthor = normalizeAuthor(book.volumeInfo?.authors?.[0] || '');
          const imageLinks = book.volumeInfo?.imageLinks;
          
          if (!imageLinks) continue; // Skip books without covers
          
          // Calculate similarity scores
          const titleSimilarity = calculateSimilarity(normalizedTitle, bookTitle);
          const authorSimilarity = calculateSimilarity(normalizedAuthor, bookAuthor);
          
          // Combined score (weighted towards title match)
          const combinedScore = (titleSimilarity * 0.7) + (authorSimilarity * 0.3);
          
          // Only consider matches with reasonable similarity
          if (combinedScore > 0.3) {
            // Try different image sizes in order of preference (highest quality first)
            const coverUrl = imageLinks.thumbnail?.replace('&edge=curl', '') || 
                           imageLinks.smallThumbnail?.replace('&edge=curl', '') || 
                           imageLinks.small || 
                           imageLinks.medium || 
                           null;
            
            if (coverUrl && (!bestMatch || combinedScore > bestMatch.score)) {
              bestMatch = {
                book,
                score: combinedScore,
                coverUrl
              };
            }
          }
        }
      }
    }
    
    return bestMatch?.coverUrl || null;
  } catch (error) {
    console.error('Error fetching book cover from Google Books API:', error);
    return null;
  }
};

/**
 * Fetch book cover from a generic book cover service
 */
const fetchBookCoverFromGeneric = async (title: string, author: string): Promise<string | null> => {
  try {
    // Try to get cover from a generic book cover service
    // This is a fallback that uses a different approach
    const searchQuery = `${title} ${author}`.replace(/[^a-zA-Z0-9\s]/g, '');
    const url = `https://www.googleapis.com/customsearch/v1?key=${GOOGLE_BOOKS_API_KEY}&cx=YOUR_CUSTOM_SEARCH_ENGINE_ID&q=${encodeURIComponent(searchQuery + ' book cover')}&searchType=image&num=1`;
    
    // For now, we'll skip this as it requires additional setup
    // But this shows how you could add another fallback
    return null;
  } catch (error) {
    console.error('Error fetching book cover from generic service:', error);
    return null;
  }
};

/**
 * Fetch alternative cover using different search strategies
 */
const fetchAlternativeCover = async (title: string, author: string): Promise<string | null> => {
  try {
    // Try different title variations
    const titleVariations = [
      title,
      title.replace(/['"]/g, ''), // Remove quotes
      title.split(' ').slice(0, 3).join(' '), // First 3 words
      title.split(' ').slice(0, 2).join(' '), // First 2 words
    ];

    for (const titleVar of titleVariations) {
      // Try OpenLibrary with different title variations
      const url = `https://openlibrary.org/search.json?title=${encodeURIComponent(titleVar)}&author=${encodeURIComponent(author)}&limit=5`;
      const response = await fetch(url);
      
      if (response.ok) {
        const data = await response.json();
        if (data.docs && data.docs.length > 0) {
          for (const book of data.docs) {
            if (book.cover_i) {
              return `https://covers.openlibrary.org/b/id/${book.cover_i}-L.jpg`;
            }
          }
        }
      }
    }
    
    return null;
  } catch (error) {
    console.warn('Alternative cover search failed:', error);
    return null;
  }
};

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
  const overrideKey = bookId.toLowerCase().replace(/[^a-z0-9]/g, '-');
  if (manualCoverOverrides[overrideKey]) {
    const overrideUrl = manualCoverOverrides[overrideKey];
    bookCoverCache.set(cacheKey, overrideUrl);
    console.log(`Using manual override for: ${title} by ${author}`);
    return overrideUrl;
  }

  // Try multiple fallback strategies
  const strategies = [
    () => fetchBookCoverFromGoogle(title, author),
    () => fetchBookCoverFromOpenLibrary(title, author),
    () => fetchAlternativeCover(title, author),
    () => fetchBookCoverFromGeneric(title, author),
    () => generateFallbackCover(title, author), // New fallback
  ];

  let coverUrl: string | null = null;
  
  for (const strategy of strategies) {
    try {
      coverUrl = await strategy();
      if (coverUrl) {
        console.log(`Found cover for: ${title} by ${author} using strategy`);
        break;
      }
    } catch (error) {
      console.warn(`Strategy failed for ${title} by ${author}:`, error);
      continue;
    }
  }
  
  // Cache the result (only if we have a valid URL)
  if (coverUrl) {
    bookCoverCache.set(cacheKey, coverUrl);
  }
  
  if (coverUrl) {
    console.log(`Found cover for: ${title} by ${author}`);
  } else {
    console.warn(`No cover found for: ${title} by ${author} (ID: ${bookId})`);
  }
  
  return coverUrl;
};

/**
 * Generate a fallback cover using a placeholder service
 */
const generateFallbackCover = async (title: string, author: string): Promise<string | null> => {
  try {
    // Use a placeholder service that generates covers based on title/author
    const cleanTitle = encodeURIComponent(title.replace(/[^a-zA-Z0-9\s]/g, ''));
    const cleanAuthor = encodeURIComponent(author.replace(/[^a-zA-Z0-9\s]/g, ''));
    
    return `https://via.placeholder.com/300x400/1f2937/ffffff?text=${cleanTitle}+by+${cleanAuthor}`;
  } catch (error) {
    console.warn('Fallback cover generation failed:', error);
    return null;
  }
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