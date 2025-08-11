# Add these lines to your .env file for the book cover system:

# Book Cover System Configuration
VITE_COVER_CACHE_ENABLED=true
VITE_COVER_CACHE_SIZE=50
VITE_COVER_CACHE_EXPIRY=24
VITE_COVER_PROGRESSIVE_LOADING=true
VITE_COVER_OFFLINE_SUPPORT=true
VITE_COVER_RETRY_ATTEMPTS=3
VITE_COVER_RETRY_DELAY=1000
VITE_COVER_PRELOAD_COUNT=8

# Optional: Amazon Product Advertising API (for enhanced coverage)
VITE_AMAZON_API_KEY=your_amazon_api_key_here
VITE_AMAZON_SECRET_KEY=your_amazon_secret_key_here
VITE_AMAZON_ASSOCIATE_TAG=your_amazon_associate_tag_here

# Optional: Goodreads API (deprecated but included for future use)
VITE_GOODREADS_API_KEY=your_goodreads_api_key_here
