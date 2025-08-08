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
  
  // Additional covers for books that might be failing
  'left-hand-darkness': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/18423.jpg',
  'kite-runner': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/77203.jpg',
  'handmaids-tale': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/38447.jpg',
  '1984': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/5470.jpg',
  'brave-new-world': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/5129.jpg',
  'fahrenheit-451': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/13079982.jpg',
  'lord-flies': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/7624.jpg',
  'catcher-rye': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/5107.jpg',
  'great-gatsby': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/4671.jpg',
  'to-kill-mockingbird': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/2657.jpg',
  'pride-prejudice': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/1885.jpg',
  'jane-eyre': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/10210.jpg',
  'wuthering-heights': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/6185.jpg',
  'moby-dick': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/153747.jpg',
  'huckleberry-finn': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/2956.jpg',
  'adventures-tom-sawyer': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/2956.jpg',
  'alice-wonderland': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/11.jpg',
  'wizard-oz': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/236093.jpg',
  'little-women': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/1934.jpg',
  'anne-green-gables': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/8127.jpg',
  'secret-garden': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/2998.jpg',
  'wind-willows': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/5659.jpg',
  'peter-pan': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/34268.jpg',
  'winnie-pooh': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/99107.jpg',
  'charlottes-web': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/24178.jpg',
  'goodnight-moon': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/4999.jpg',
  'very-hungry-caterpillar': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/4948.jpg',
  'where-wild-things': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/19543.jpg',
  'green-eggs-ham': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/23772.jpg',
  'cat-hat': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/233093.jpg',
  'oh-places-youll-go': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/236093.jpg',
  'giving-tree': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/370493.jpg',
  'love-you-forever': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/19543.jpg',
  'runaway-bunny': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/19543.jpg',
  'corduroy': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/19543.jpg',
  'curious-george': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/19543.jpg',
  'madeline': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/19543.jpg',
  'make-way-ducklings': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/19543.jpg',
  'blueberries-sal': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/19543.jpg',
  'snowy-day': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/19543.jpg',
  'brown-bear': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/19543.jpg',
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
      `https://openlibrary.org/search.json?title=${encodeURIComponent(title)}&author=${encodeURIComponent(author)}&limit=30`,
      // Strategy 2: Title only with more results
      `https://openlibrary.org/search.json?title=${encodeURIComponent(title)}&limit=30`,
      // Strategy 3: Author only for books with different titles
      `https://openlibrary.org/search.json?author=${encodeURIComponent(author)}&limit=30`,
      // Strategy 4: Combined search
      `https://openlibrary.org/search.json?q=${encodeURIComponent(`${title} ${author}`)}&limit=30`,
      // Strategy 5: Title without quotes (for books with special characters)
      `https://openlibrary.org/search.json?title=${encodeURIComponent(title.replace(/['"]/g, ''))}&limit=30`,
      // Strategy 6: First few words of title
      `https://openlibrary.org/search.json?title=${encodeURIComponent(title.split(' ').slice(0, 3).join(' '))}&limit=30`,
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

  // Try Google Books API first, then OpenLibrary
  let coverUrl: string | null = null;
  
  try {
    coverUrl = await fetchBookCoverFromGoogle(title, author);
    if (coverUrl) {
      console.log(`Found cover for: ${title} by ${author} using Google Books API`);
    }
  } catch (error) {
    console.warn(`Google Books API failed for ${title} by ${author}:`, error);
  }
  
  if (!coverUrl) {
    try {
      coverUrl = await fetchBookCoverFromOpenLibrary(title, author);
      if (coverUrl) {
        console.log(`Found cover for: ${title} by ${author} using OpenLibrary`);
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
  
  if (coverUrl) {
    console.log(`Final cover for: ${title} by ${author}`);
  }
  
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