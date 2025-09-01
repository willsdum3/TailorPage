// Favorites Utilities
// Handles consistent book ID management and favorites operations

import { FavoriteBook, BookRecommendation } from '../types';

/**
 * Generate a consistent book ID from title and author
 * This ensures the same book always has the same ID regardless of database storage
 */
export const generateBookId = (title: string, author: string): string => {
  const normalizedTitle = title.toLowerCase().replace(/[^a-z0-9]/g, '-');
  const normalizedAuthor = author.toLowerCase().replace(/[^a-z0-9]/g, '-');
  return `${normalizedTitle}-${normalizedAuthor}`;
};

/**
 * Create a FavoriteBook from a BookRecommendation with consistent ID
 */
export const createFavoriteBook = (book: BookRecommendation): FavoriteBook => {
  return {
    ...book,
    id: generateBookId(book.title, book.author), // Use consistent ID
    dateAdded: new Date().toISOString()
  };
};

/**
 * Find a favorite book by title and author (more reliable than ID)
 */
export const findFavoriteByTitleAuthor = (
  favorites: FavoriteBook[], 
  title: string, 
  author: string
): FavoriteBook | undefined => {
  return favorites.find(fav => 
    fav.title.toLowerCase() === title.toLowerCase() && 
    fav.author.toLowerCase() === author.toLowerCase()
  );
};

/**
 * Remove a favorite book by title and author (more reliable than ID)
 */
export const removeFavoriteByTitleAuthor = (
  favorites: FavoriteBook[], 
  title: string, 
  author: string
): FavoriteBook[] => {
  return favorites.filter(fav => 
    !(fav.title.toLowerCase() === title.toLowerCase() && 
      fav.author.toLowerCase() === author.toLowerCase())
  );
};

/**
 * Check if a book is favorited by title and author
 */
export const isBookFavorited = (
  favorites: FavoriteBook[], 
  title: string, 
  author: string
): boolean => {
  return favorites.some(fav => 
    fav.title.toLowerCase() === title.toLowerCase() && 
    fav.author.toLowerCase() === author.toLowerCase()
  );
};

/**
 * Normalize a favorite book from database to ensure consistent ID
 */
export const normalizeFavoriteFromDatabase = (dbFavorite: any): FavoriteBook => {
  return {
    id: generateBookId(dbFavorite.book_title, dbFavorite.book_author), // Use consistent ID
    title: dbFavorite.book_title,
    author: dbFavorite.book_author,
    genre: dbFavorite.book_genre,
    description: dbFavorite.book_description,
    amazonLink: dbFavorite.book_amazon_link,
    coverImageUrl: dbFavorite.book_cover_image_url,
    dateAdded: dbFavorite.date_added,
    reason: dbFavorite.reason || 'Added to favorites'
  };
};
