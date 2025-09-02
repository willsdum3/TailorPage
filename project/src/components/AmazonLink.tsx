import React, { useState, useEffect } from 'react';
import { ShoppingCart, ExternalLink, AlertTriangle, Search } from 'lucide-react';
import { getReliableAmazonLink, isAmazonProductLink, generateFallbackUrls } from '../utils/amazonLinkValidator';
import { amazonLinkMonitor } from '../utils/amazonLinkMonitor';

interface AmazonLinkProps {
  title: string;
  author: string;
  originalLink?: string;
  className?: string;
  children?: React.ReactNode;
  showIcon?: boolean;
  variant?: 'button' | 'link' | 'text';
  aggressiveFallback?: boolean;
}

const AmazonLink: React.FC<AmazonLinkProps> = ({
  title,
  author,
  originalLink,
  className = '',
  children,
  showIcon = true,
  variant = 'button',
  aggressiveFallback = true
}) => {
  const [reliableLink, setReliableLink] = useState<string>('');
  const [isLoading, setIsLoading] = useState(true);
  const [hasError, setHasError] = useState(false);
  const [isValidProductLink, setIsValidProductLink] = useState(false);
  const [fallbackAttempts, setFallbackAttempts] = useState(0);
  const [currentStrategy, setCurrentStrategy] = useState<string>('');

  useEffect(() => {
    const validateAndSetLink = async () => {
      try {
        setIsLoading(true);
        setHasError(false);
        setFallbackAttempts(0);

        // Register link for monitoring
        if (originalLink) {
          amazonLinkMonitor.registerLink(originalLink, title, author);
        }

        // Strategy 1: Try to get a reliable link
        setCurrentStrategy('Validating original link...');
        const link = await getReliableAmazonLink(title, author, originalLink);
        
        // Check if it's a valid product link
        const isValid = isAmazonProductLink(link);
        setIsValidProductLink(isValid);
        
        if (isValid) {
          setReliableLink(link);
          setCurrentStrategy('Direct product link');
          // Record success
          if (originalLink) {
            amazonLinkMonitor.recordSuccess(originalLink, title, author);
          }
        } else {
          // Strategy 2: If not a valid product link, use search fallback
          setCurrentStrategy('Using search fallback...');
          const searchUrl = `https://www.amazon.co.uk/s?k=${encodeURIComponent(`${title} ${author}`)}`;
          setReliableLink(searchUrl);
          setFallbackAttempts(1);
          // Record fallback usage
          if (originalLink) {
            amazonLinkMonitor.recordFallback(originalLink, title, author);
          }
        }

        setIsLoading(false);
      } catch (error) {
        console.error('Error validating Amazon link:', error);
        
        // Strategy 3: Aggressive fallback - always provide a working link
        setCurrentStrategy('Emergency fallback...');
        setHasError(true);
        setFallbackAttempts(2);
        
        // Record failure
        if (originalLink) {
          amazonLinkMonitor.recordFailure(originalLink, title, author, error instanceof Error ? error.message : 'Unknown error');
        }
        
        // Generate multiple fallback options
        const fallbackUrls = generateFallbackUrls(title, author);
        setReliableLink(fallbackUrls[0]); // Use the first fallback
        
        setIsLoading(false);
      }
    };

    validateAndSetLink();
  }, [title, author, originalLink, aggressiveFallback]);

  const handleClick = (e: React.MouseEvent) => {
    // Add analytics tracking here if needed
    console.log(`Amazon link clicked for: ${title} by ${author}`);
    console.log(`Link strategy: ${currentStrategy}, Fallback attempts: ${fallbackAttempts}`);
  };

  const handleLinkError = () => {
    // If the link fails to load, try the next fallback
    if (fallbackAttempts < 3) {
      setFallbackAttempts(prev => prev + 1);
      const fallbackUrls = generateFallbackUrls(title, author);
      const nextFallback = fallbackUrls[Math.min(fallbackAttempts + 1, fallbackUrls.length - 1)];
      setReliableLink(nextFallback);
      setCurrentStrategy(`Fallback attempt ${fallbackAttempts + 2}`);
    }
  };

  if (isLoading) {
    return (
      <div className={`${className} inline-flex items-center space-x-2 text-white/60 animate-pulse`}>
        <div className="w-4 h-4 bg-white/20 rounded animate-pulse" />
        <span>Validating link...</span>
      </div>
    );
  }

  // Different variants
  if (variant === 'text') {
    return (
      <a
        href={reliableLink}
        target="_blank"
        rel="noopener noreferrer"
        onClick={handleClick}
        onError={handleLinkError}
        className={`${className} text-amber-400 hover:text-amber-300 transition-colors duration-300 inline-flex items-center space-x-1`}
        title={!isValidProductLink ? "Search results on Amazon" : "View on Amazon"}
      >
        <span>View on Amazon</span>
        {showIcon && <ExternalLink className="w-3 h-3" />}
        {!isValidProductLink && (
          <span className="text-xs text-white/60">(search)</span>
        )}
        {fallbackAttempts > 0 && (
          <span className="text-xs text-amber-400/80">(fallback)</span>
        )}
      </a>
    );
  }

  if (variant === 'link') {
    return (
      <a
        href={reliableLink}
        target="_blank"
        rel="noopener noreferrer"
        onClick={handleClick}
        onError={handleLinkError}
        className={`${className} text-amber-400 hover:text-amber-300 transition-colors duration-300 underline inline-flex items-center space-x-1`}
        title={!isValidProductLink ? "Search results on Amazon" : "View on Amazon"}
      >
        <span>Amazon</span>
        {showIcon && <ExternalLink className="w-3 h-3" />}
        {!isValidProductLink && (
          <span className="text-xs text-white/60">(search)</span>
        )}
        {fallbackAttempts > 0 && (
          <span className="text-xs text-amber-400/80">(fallback)</span>
        )}
      </a>
    );
  }

  // Default button variant
  return (
    <a
      href={reliableLink}
      target="_blank"
      rel="noopener noreferrer"
      onClick={handleClick}
      onError={handleLinkError}
      className={`${className} bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white px-4 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105 inline-flex items-center justify-center space-x-2 w-full group`}
      title={!isValidProductLink ? "Search results on Amazon" : "View on Amazon"}
    >
      {children || (
        <>
          {isValidProductLink ? (
            <ShoppingCart className="w-4 h-4" />
          ) : (
            <Search className="w-4 h-4" />
          )}
          <span>View on Amazon</span>
          <ExternalLink className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
          {!isValidProductLink && (
            <span className="text-xs text-white/80">(search)</span>
          )}
          {fallbackAttempts > 0 && (
            <span className="text-xs text-white/80">(fallback)</span>
          )}
        </>
      )}
    </a>
  );
};

export default AmazonLink;
