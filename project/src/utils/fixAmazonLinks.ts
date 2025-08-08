// Amazon Link Fixer
// This utility helps fix existing Amazon links in data files

import { fixAmazonUrl, extractAmazonProductId } from './amazonLinkValidator';

/**
 * Fix Amazon links in trending books data
 */
export const fixTrendingBooksLinks = () => {
  const books = [
    {
      id: 'fourth-wing',
      title: 'Fourth Wing',
      author: 'Rebecca Yarros',
      originalLink: 'https://amzn.eu/d/0GWJJxz',
      fixedLink: 'https://www.amazon.co.uk/dp/0GWJJxz'
    },
    {
      id: 'iron-flame',
      title: 'Iron Flame',
      author: 'Rebecca Yarros',
      originalLink: 'https://amzn.eu/d/9Tz3OSX',
      fixedLink: 'https://www.amazon.co.uk/dp/9Tz3OSX'
    },
    {
      id: 'it-starts-with-us',
      title: 'It Starts with Us',
      author: 'Colleen Hoover',
      originalLink: 'https://amzn.eu/d/bLm3fls',
      fixedLink: 'https://www.amazon.co.uk/dp/bLm3fls'
    },
    {
      id: 'verity',
      title: 'Verity',
      author: 'Colleen Hoover',
      originalLink: 'https://amzn.eu/d/gbSNGgf',
      fixedLink: 'https://www.amazon.co.uk/dp/gbSNGgf'
    },
    {
      id: 'lessons-in-chemistry',
      title: 'Lessons in Chemistry',
      author: 'Bonnie Garmus',
      originalLink: 'https://amzn.eu/d/6NCOTQ1',
      fixedLink: 'https://www.amazon.co.uk/dp/6NCOTQ1'
    }
  ];

  return books.map(book => ({
    ...book,
    fixedLink: fixAmazonUrl(book.originalLink)
  }));
};

/**
 * Generate reliable Amazon links for books
 */
export const generateReliableLinks = (books: Array<{ title: string; author: string; originalLink?: string }>) => {
  return books.map(book => {
    const fixedLink = book.originalLink ? fixAmazonUrl(book.originalLink) : null;
    const searchLink = `https://www.amazon.co.uk/s?k=${encodeURIComponent(`${book.title} ${book.author}`)}`;
    
    return {
      ...book,
      fixedLink,
      searchLink,
      recommendedLink: fixedLink || searchLink
    };
  });
};

/**
 * Validate and report on Amazon links
 */
export const validateAmazonLinksReport = async (links: string[]) => {
  const results = [];
  
  for (const link of links) {
    const productId = extractAmazonProductId(link);
    const fixedLink = fixAmazonUrl(link);
    
    results.push({
      original: link,
      fixed: fixedLink,
      productId,
      isShortened: link.includes('amzn.eu') || link.includes('amzn.to'),
      needsFixing: link !== fixedLink
    });
  }
  
  return results;
};

/**
 * Get recommended Amazon link format
 */
export const getRecommendedLinkFormat = (title: string, author: string, productId?: string) => {
  if (productId) {
    return `https://www.amazon.co.uk/dp/${productId}`;
  }
  
  return `https://www.amazon.co.uk/s?k=${encodeURIComponent(`${title} ${author}`)}`;
};
