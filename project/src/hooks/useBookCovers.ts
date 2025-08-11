import { useState, useEffect, useCallback, useRef } from 'react';
import { BookCoverData, bookCoverService } from '../services/bookCoverService';

export interface BookCoverState {
  [key: string]: {
    data: BookCoverData | null;
    loading: boolean;
    error: string | null;
    lastUpdated: number;
  };
}

export interface UseBookCoversOptions {
  preloadCount?: number;
  enableCache?: boolean;
  retryAttempts?: number;
  retryDelay?: number;
  onCoverLoad?: (bookId: string, coverData: BookCoverData) => void;
  onCoverError?: (bookId: string, error: string) => void;
}

export const useBookCovers = (options: UseBookCoversOptions = {}) => {
  const {
    preloadCount = 8,
    enableCache = true,
    retryAttempts = 3,
    retryDelay = 1000,
    onCoverLoad,
    onCoverError
  } = options;

  const [coverState, setCoverState] = useState<BookCoverState>({});
  const [loadingQueue, setLoadingQueue] = useState<Set<string>>(new Set());
  const retryCountRef = useRef<Map<string, number>>(new Map());
  const abortControllerRef = useRef<Map<string, AbortController>>(new Map());

  // Generate cache key for a book
  const getCacheKey = useCallback((title: string, author: string): string => {
    return `${title.toLowerCase().replace(/[^a-z0-9]/g, '')}-${author.toLowerCase().replace(/[^a-z0-9]/g, '')}`;
  }, []);

  // Load a single book cover
  const loadCover = useCallback(async (
    title: string, 
    author: string, 
    bookId?: string
  ): Promise<void> => {
    const cacheKey = getCacheKey(title, author);
    const id = bookId || cacheKey;

    // Check if already loading
    if (loadingQueue.has(cacheKey)) {
      return;
    }

    // Check if already cached and not expired
    const existing = coverState[cacheKey];
    if (existing && !isExpired(existing.lastUpdated)) {
      return;
    }

    // Add to loading queue
    setLoadingQueue(prev => new Set(prev).add(cacheKey));

    // Create abort controller for this request
    const abortController = new AbortController();
    abortControllerRef.current.set(cacheKey, abortController);

    // Update state to loading
    setCoverState(prev => ({
      ...prev,
      [cacheKey]: {
        data: existing?.data || null,
        loading: true,
        error: null,
        lastUpdated: Date.now()
      }
    }));

    try {
      const result = await bookCoverService.getBookCover(title, author);
      
      if (abortController.signal.aborted) {
        return;
      }

      if (result.success && result.data) {
        setCoverState(prev => ({
          ...prev,
          [cacheKey]: {
            data: result.data,
            loading: false,
            error: null,
            lastUpdated: Date.now()
          }
        }));
        
        onCoverLoad?.(id, result.data);
        retryCountRef.current.delete(cacheKey);
      } else {
        throw new Error(result.error || 'Failed to load cover');
      }
    } catch (error) {
      if (abortController.signal.aborted) {
        return;
      }

      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      
      // Handle retry logic
      const currentRetries = retryCountRef.current.get(cacheKey) || 0;
      if (currentRetries < retryAttempts) {
        retryCountRef.current.set(cacheKey, currentRetries + 1);
        
        setTimeout(() => {
          loadCover(title, author, bookId);
        }, retryDelay * (currentRetries + 1));
        
        return;
      }

      setCoverState(prev => ({
        ...prev,
        [cacheKey]: {
          data: existing?.data || null,
          loading: false,
          error: errorMessage,
          lastUpdated: Date.now()
        }
      }));
      
      onCoverError?.(id, errorMessage);
    } finally {
      setLoadingQueue(prev => {
        const newSet = new Set(prev);
        newSet.delete(cacheKey);
        return newSet;
      });
      abortControllerRef.current.delete(cacheKey);
    }
  }, [coverState, loadingQueue, retryAttempts, retryDelay, onCoverLoad, onCoverError, getCacheKey]);

  // Load multiple book covers with priority
  const loadCovers = useCallback(async (
    books: Array<{ title: string; author: string; id?: string }>
  ): Promise<void> => {
    if (books.length === 0) return;

    // Sort books by priority (first preloadCount are high priority)
    const highPriority = books.slice(0, preloadCount);
    const lowPriority = books.slice(preloadCount);

    // Load high priority covers immediately
    const highPriorityPromises = highPriority.map(book => 
      loadCover(book.title, book.author, book.id)
    );

    await Promise.allSettled(highPriorityPromises);

    // Load low priority covers with delay
    if (lowPriority.length > 0) {
      setTimeout(() => {
        lowPriority.forEach(book => {
          loadCover(book.title, book.author, book.id);
        });
      }, 100);
    }
  }, [loadCover, preloadCount]);

  // Preload covers for better performance
  const preloadCovers = useCallback(async (
    books: Array<{ title: string; author: string; id?: string }>
  ): Promise<void> => {
    const bookData = books.map(book => ({ title: book.title, author: book.author }));
    await bookCoverService.preloadCovers(bookData);
  }, []);

  // Get cover data for a specific book
  const getCover = useCallback((title: string, author: string) => {
    const cacheKey = getCacheKey(title, author);
    return coverState[cacheKey] || {
      data: null,
      loading: false,
      error: null,
      lastUpdated: 0
    };
  }, [coverState, getCacheKey]);

  // Check if cover is expired
  const isExpired = useCallback((timestamp: number): boolean => {
    const expiryTime = 24 * 60 * 60 * 1000; // 24 hours
    return Date.now() - timestamp > expiryTime;
  }, []);

  // Clear specific cover from cache
  const clearCover = useCallback((title: string, author: string): void => {
    const cacheKey = getCacheKey(title, author);
    
    // Abort any ongoing request
    const abortController = abortControllerRef.current.get(cacheKey);
    if (abortController) {
      abortController.abort();
      abortControllerRef.current.delete(cacheKey);
    }

    setCoverState(prev => {
      const newState = { ...prev };
      delete newState[cacheKey];
      return newState;
    });

    setLoadingQueue(prev => {
      const newSet = new Set(prev);
      newSet.delete(cacheKey);
      return newSet;
    });

    retryCountRef.current.delete(cacheKey);
  }, [getCacheKey]);

  // Clear all covers from cache
  const clearAllCovers = useCallback((): void => {
    // Abort all ongoing requests
    abortControllerRef.current.forEach(controller => controller.abort());
    abortControllerRef.current.clear();

    setCoverState({});
    setLoadingQueue(new Set());
    retryCountRef.current.clear();
  }, []);

  // Get cache statistics
  const getCacheStats = useCallback(() => {
    const totalCovers = Object.keys(coverState).length;
    const loadingCovers = loadingQueue.size;
    const cachedCovers = Object.values(coverState).filter(item => item.data).length;
    const errorCovers = Object.values(coverState).filter(item => item.error).length;

    return {
      total: totalCovers,
      loading: loadingCovers,
      cached: cachedCovers,
      errors: errorCovers,
      hitRate: totalCovers > 0 ? (cachedCovers / totalCovers) * 100 : 0
    };
  }, [coverState, loadingQueue]);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      // Abort all ongoing requests
      abortControllerRef.current.forEach(controller => controller.abort());
      abortControllerRef.current.clear();
    };
  }, []);

  return {
    coverState,
    loadCover,
    loadCovers,
    preloadCovers,
    getCover,
    clearCover,
    clearAllCovers,
    getCacheStats,
    isLoading: loadingQueue.size > 0
  };
};

// Hook for managing a single book cover
export const useBookCover = (
  title: string,
  author: string,
  options: UseBookCoversOptions = {}
) => {
  const { loadCover, getCover, clearCover } = useBookCovers(options);
  const coverData = getCover(title, author);

  useEffect(() => {
    if (title && author) {
      loadCover(title, author);
    }
  }, [title, author, loadCover]);

  return {
    ...coverData,
    reload: () => {
      clearCover(title, author);
      loadCover(title, author);
    },
    clear: () => clearCover(title, author)
  };
};
