// Amazon Link Validator and Fixer
// This utility ensures all Amazon links are working and properly formatted

export interface AmazonLinkInfo {
  originalUrl: string;
  fixedUrl: string;
  isValid: boolean;
  error?: string;
  validationMethod?: string;
}

/**
 * Enhanced validation with multiple strategies
 */
export const validateAmazonLink = async (url: string): Promise<AmazonLinkInfo> => {
  try {
    // Strategy 1: Fix and validate the original URL
    const fixedUrl = fixAmazonUrl(url);
    
    // Strategy 2: Try multiple validation approaches
    const validationResults = await Promise.allSettled([
      validateWithHeadRequest(fixedUrl),
      validateWithFetchRequest(fixedUrl),
      validateWithTimeout(fixedUrl, 3000)
    ]);
    
    // Check if any validation succeeded
    const successfulValidation = validationResults.find(result => 
      result.status === 'fulfilled' && result.value
    );
    
    if (successfulValidation) {
      return {
        originalUrl: url,
        fixedUrl: fixedUrl,
        isValid: true,
        validationMethod: 'direct'
      };
    }
    
    // Strategy 3: If direct validation fails, assume it might be broken
    // and return false to trigger fallback
    return {
      originalUrl: url,
      fixedUrl: fixedUrl,
      isValid: false,
      error: 'Link validation failed - using fallback',
      validationMethod: 'fallback'
    };
    
  } catch (error) {
    return {
      originalUrl: url,
      fixedUrl: url,
      isValid: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      validationMethod: 'error'
    };
  }
};

/**
 * Validate with HEAD request
 */
const validateWithHeadRequest = async (url: string): Promise<boolean> => {
  try {
    const response = await fetch(url, { 
      method: 'HEAD',
      mode: 'no-cors',
      cache: 'no-cache'
    });
    return true; // If no error, assume it's valid
  } catch {
    return false;
  }
};

/**
 * Validate with GET request
 */
const validateWithFetchRequest = async (url: string): Promise<boolean> => {
  try {
    const response = await fetch(url, { 
      method: 'GET',
      mode: 'no-cors',
      cache: 'no-cache'
    });
    return true;
  } catch {
    return false;
  }
};

/**
 * Validate with timeout
 */
const validateWithTimeout = async (url: string, timeout: number): Promise<boolean> => {
  return new Promise((resolve) => {
    const timer = setTimeout(() => resolve(false), timeout);
    
    fetch(url, { 
      method: 'HEAD',
      mode: 'no-cors',
      cache: 'no-cache'
    })
    .then(() => {
      clearTimeout(timer);
      resolve(true);
    })
    .catch(() => {
      clearTimeout(timer);
      resolve(false);
    });
  });
};

/**
 * Enhanced URL fixing with more aggressive strategies
 */
export const fixAmazonUrl = (url: string): string => {
  let fixedUrl = url.trim();
  
  // Remove any trailing slashes and query parameters that might cause issues
  fixedUrl = fixedUrl.replace(/\/$/, '').split('?')[0];
  
  // Handle shortened Amazon links (amzn.eu, amzn.to, etc.)
  if (fixedUrl.includes('amzn.eu/d/') || fixedUrl.includes('amzn.to/')) {
    return convertShortAmazonUrl(fixedUrl);
  }
  
  // Ensure proper protocol
  if (!fixedUrl.startsWith('http')) {
    fixedUrl = 'https://' + fixedUrl;
  }
  
  // Standardize Amazon UK domain
  if (fixedUrl.includes('amazon.com')) {
    fixedUrl = fixedUrl.replace('amazon.com', 'amazon.co.uk');
  }
  
  // Clean up any malformed URLs
  fixedUrl = fixedUrl.replace(/\/+/g, '/'); // Remove multiple slashes
  fixedUrl = fixedUrl.replace(/https:\/\/www\.amazon\.co\.uk\/www\.amazon\.co\.uk/, 'https://www.amazon.co.uk'); // Fix double domains
  
  return fixedUrl;
};

/**
 * Convert shortened Amazon URLs to direct product links
 */
const convertShortAmazonUrl = (shortUrl: string): string => {
  // Extract the product ID from shortened URLs
  const match = shortUrl.match(/amzn\.(eu|to)\/d\/([A-Za-z0-9]+)/);
  if (match) {
    const productId = match[2];
    // Convert to direct product link format
    return `https://www.amazon.co.uk/dp/${productId}`;
  }
  
  return shortUrl; // Return original if we can't parse it
};

/**
 * Generate multiple reliable Amazon search URLs as fallbacks
 */
export const generateAmazonSearchUrl = (title: string, author: string): string => {
  // Clean the title and author for better search results
  const cleanTitle = title.replace(/[^\w\s]/g, ' ').replace(/\s+/g, ' ').trim();
  const cleanAuthor = author.replace(/[^\w\s]/g, ' ').replace(/\s+/g, ' ').trim();
  
  // Create multiple search strategies
  const searchQueries = [
    `${cleanTitle} ${cleanAuthor}`,
    `"${cleanTitle}" "${cleanAuthor}"`,
    `${cleanTitle} by ${cleanAuthor}`,
    cleanTitle // Title only as last resort
  ];
  
  // Use the first query for now, but we could implement a strategy to try multiple
  const searchQuery = encodeURIComponent(searchQueries[0]);
  return `https://www.amazon.co.uk/s?k=${searchQuery}`;
};

/**
 * Batch validate multiple Amazon links with enhanced error handling
 */
export const validateAmazonLinks = async (links: string[]): Promise<AmazonLinkInfo[]> => {
  const results = await Promise.allSettled(
    links.map(link => validateAmazonLink(link))
  );
  
  return results.map(result => {
    if (result.status === 'fulfilled') {
      return result.value;
    } else {
      return {
        originalUrl: 'unknown',
        fixedUrl: 'unknown',
        isValid: false,
        error: result.reason?.message || 'Validation failed',
        validationMethod: 'error'
      };
    }
  });
};

/**
 * Get a reliable Amazon link with aggressive fallback strategy
 */
export const getReliableAmazonLink = async (
  title: string, 
  author: string, 
  originalLink?: string
): Promise<string> => {
  // Strategy 1: If we have an original link, try to validate it
  if (originalLink) {
    try {
      const validation = await validateAmazonLink(originalLink);
      
      // If validation succeeds, use the fixed URL
      if (validation.isValid) {
        return validation.fixedUrl;
      }
      
      // If validation fails but we have a fixed URL, try it anyway
      if (validation.fixedUrl && validation.fixedUrl !== originalLink) {
        const fixedValidation = await validateAmazonLink(validation.fixedUrl);
        if (fixedValidation.isValid) {
          return fixedValidation.fixedUrl;
        }
      }
    } catch (error) {
      console.warn('Error validating original link:', error);
    }
  }
  
  // Strategy 2: Always fallback to search URL for maximum reliability
  return generateAmazonSearchUrl(title, author);
};

/**
 * Enhanced check for valid Amazon product links
 */
export const isAmazonProductLink = (url: string): boolean => {
  const amazonPatterns = [
    /amazon\.co\.uk\/dp\//,
    /amazon\.co\.uk\/gp\/product\//,
    /amazon\.co\.uk\/[^\/]+\/dp\//,
    /amzn\.eu\/d\//,
    /amzn\.to\//
  ];
  
  return amazonPatterns.some(pattern => pattern.test(url));
};

/**
 * Extract product ID from Amazon URL with enhanced patterns
 */
export const extractAmazonProductId = (url: string): string | null => {
  const patterns = [
    /amazon\.co\.uk\/dp\/([A-Z0-9]{10})/,
    /amazon\.co\.uk\/gp\/product\/([A-Z0-9]{10})/,
    /amzn\.eu\/d\/([A-Za-z0-9]+)/,
    /amzn\.to\/([A-Za-z0-9]+)/,
    /amazon\.co\.uk\/[^\/]+\/dp\/([A-Z0-9]{10})/
  ];
  
  for (const pattern of patterns) {
    const match = url.match(pattern);
    if (match) {
      return match[1];
    }
  }
  
  return null;
};

/**
 * Generate multiple fallback URLs for maximum reliability
 */
export const generateFallbackUrls = (title: string, author: string): string[] => {
  const cleanTitle = title.replace(/[^\w\s]/g, ' ').replace(/\s+/g, ' ').trim();
  const cleanAuthor = author.replace(/[^\w\s]/g, ' ').replace(/\s+/g, ' ').trim();
  
  return [
    `https://www.amazon.co.uk/s?k=${encodeURIComponent(`${cleanTitle} ${cleanAuthor}`)}`,
    `https://www.amazon.co.uk/s?k=${encodeURIComponent(`"${cleanTitle}" "${cleanAuthor}"`)}`,
    `https://www.amazon.co.uk/s?k=${encodeURIComponent(`${cleanTitle} by ${cleanAuthor}`)}`,
    `https://www.amazon.co.uk/s?k=${encodeURIComponent(cleanTitle)}`
  ];
};
