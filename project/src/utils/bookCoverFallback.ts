// Book Cover Fallback System
// Ensures all books have covers by providing multiple fallback strategies

export interface FallbackCoverInfo {
  url: string;
  source: 'manual' | 'placeholder' | 'generated';
  quality: 'high' | 'medium' | 'low';
}

/**
 * Generate a comprehensive list of fallback covers for any book
 */
export const generateFallbackCovers = (title: string, author: string): FallbackCoverInfo[] => {
  const fallbacks: FallbackCoverInfo[] = [];
  
  // Clean title and author for URL generation
  const cleanTitle = title.replace(/[^a-zA-Z0-9\s]/g, '').trim();
  const cleanAuthor = author.replace(/[^a-zA-Z0-9\s]/g, '').trim();
  
  // Strategy 1: Placeholder service with title/author
  fallbacks.push({
    url: `https://via.placeholder.com/300x400/1f2937/ffffff?text=${encodeURIComponent(cleanTitle)}+by+${encodeURIComponent(cleanAuthor)}`,
    source: 'placeholder',
    quality: 'medium'
  });
  
  // Strategy 2: Placeholder with just title
  fallbacks.push({
    url: `https://via.placeholder.com/300x400/1f2937/ffffff?text=${encodeURIComponent(cleanTitle)}`,
    source: 'placeholder',
    quality: 'medium'
  });
  
  // Strategy 3: Generated cover with gradient background
  fallbacks.push({
    url: `https://via.placeholder.com/300x400/4f46e5/ffffff?text=${encodeURIComponent(cleanTitle)}`,
    source: 'generated',
    quality: 'medium'
  });
  
  // Strategy 4: Simple text-based cover
  fallbacks.push({
    url: `https://via.placeholder.com/300x400/059669/ffffff?text=${encodeURIComponent(cleanTitle.split(' ').slice(0, 2).join(' '))}`,
    source: 'generated',
    quality: 'low'
  });
  
  return fallbacks;
};

/**
 * Get the best available fallback cover
 */
export const getBestFallbackCover = (title: string, author: string): string => {
  const fallbacks = generateFallbackCovers(title, author);
  return fallbacks[0].url; // Return the highest quality fallback
};

/**
 * Comprehensive book cover resolver that always returns a cover
 */
export const resolveBookCover = async (
  bookId: string,
  title: string,
  author: string,
  getBookCoverFn: (bookId: string, title: string, author: string) => Promise<string | null>
): Promise<string> => {
  try {
    // Try the main book cover service first
    const coverUrl = await getBookCoverFn(bookId, title, author);
    
    if (coverUrl) {
      return coverUrl;
    }
    
    // If no cover found, use fallback
    console.log(`Using fallback cover for: ${title} by ${author}`);
    return getBestFallbackCover(title, author);
    
  } catch (error) {
    console.warn(`Error fetching cover for ${title} by ${author}, using fallback:`, error);
    return getBestFallbackCover(title, author);
  }
};

/**
 * Validate if a cover URL is accessible
 */
export const validateCoverUrl = async (url: string): Promise<boolean> => {
  try {
    const response = await fetch(url, { method: 'HEAD' });
    return response.ok;
  } catch (error) {
    return false;
  }
};

/**
 * Get a guaranteed working cover URL
 */
export const getGuaranteedCover = async (
  bookId: string,
  title: string,
  author: string,
  getBookCoverFn: (bookId: string, title: string, author: string) => Promise<string | null>
): Promise<string> => {
  // Try main service
  const mainCover = await getBookCoverFn(bookId, title, author);
  if (mainCover && await validateCoverUrl(mainCover)) {
    return mainCover;
  }
  
  // Try fallbacks
  const fallbacks = generateFallbackCovers(title, author);
  
  for (const fallback of fallbacks) {
    if (await validateCoverUrl(fallback.url)) {
      return fallback.url;
    }
  }
  
  // If all else fails, return the first fallback (placeholder services are usually reliable)
  return fallbacks[0].url;
};
