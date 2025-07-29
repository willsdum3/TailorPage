import { useEffect } from 'react';

/**
 * Custom hook that scrolls to the top of the page when the component mounts
 * or when dependencies change
 */
export const useScrollToTop = (dependencies: any[] = []) => {
  useEffect(() => {
    // Scroll to top with smooth behavior
    window.scrollTo({
      top: 0,
      left: 0,
      behavior: 'smooth'
    });
  }, dependencies);
};

/**
 * Custom hook that scrolls to the top immediately without smooth behavior
 * Useful for instant navigation
 */
export const useScrollToTopInstant = (dependencies: any[] = []) => {
  useEffect(() => {
    // Scroll to top immediately
    window.scrollTo(0, 0);
  }, dependencies);
}; 