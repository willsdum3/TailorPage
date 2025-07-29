# Book Covers Setup Guide

## Overview
This guide explains how to set up book covers for your Tailor Page app using the Google Books API.

## Features Implemented
- ✅ Book cover fetching from Google Books API
- ✅ Caching system to avoid repeated API calls
- ✅ Fallback book icons when covers aren't available
- ✅ Loading states and error handling
- ✅ Reusable BookCover component

## Setup Steps

### 1. Get Google Books API Key
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the **Google Books API**:
   - Go to "APIs & Services" > "Library"
   - Search for "Google Books API"
   - Click "Enable"
4. Create credentials:
   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "API Key"
   - Copy the generated API key

### 2. Set Environment Variable
Create a `.env` file in your project root and add:
```
REACT_APP_GOOGLE_BOOKS_API_KEY=your_actual_api_key_here
```

### 3. Restart Development Server
After adding the environment variable, restart your development server:
```bash
npm run dev
```

## Usage

### BookCover Component
The `BookCover` component automatically handles:
- Loading states with skeleton animation
- Error handling with fallback icons
- Caching to improve performance
- Multiple image sizes

```tsx
import BookCover from './components/BookCover';

<BookCover 
  bookId="unique-book-id"
  title="Book Title"
  author="Author Name"
  size="md" // sm, md, lg
  className="custom-classes"
/>
```

### Book Cover Service
The service provides these functions:
- `getBookCover(bookId, title, author)` - Get cover for a single book
- `preloadBookCovers(books)` - Preload covers for multiple books
- `clearBookCoverCache()` - Clear the cache
- `getCacheStats()` - Get cache statistics

## Performance Optimization

### Caching
- Book covers are cached in memory to avoid repeated API calls
- Cache persists during the session
- Failed requests are also cached to avoid repeated failures

### Lazy Loading
- Covers load asynchronously
- Loading states provide good UX
- Fallback icons show immediately

### API Limits
- Google Books API has generous limits (1,000 requests/day for free)
- Caching helps stay within limits
- Consider upgrading for high-traffic apps

## Troubleshooting

### Covers Not Loading
1. Check your API key is correct
2. Verify the Google Books API is enabled
3. Check browser console for errors
4. Ensure environment variable is set correctly

### Poor Image Quality
- Google Books API provides different image sizes
- The service tries to get the best available size
- Consider using a different API for higher quality

### API Rate Limits
- Monitor your API usage in Google Cloud Console
- Implement additional caching if needed
- Consider using a CDN for frequently accessed covers

## Alternative APIs

If Google Books API doesn't meet your needs, consider:
- **OpenLibrary API** (free, no key required)
- **ISBNdb** (paid, comprehensive)
- **Amazon Product Advertising API** (paid, high quality)

## Files Modified
- `src/types.ts` - Added coverImageUrl field
- `src/utils/bookCoverService.ts` - API integration and caching
- `src/components/BookCover.tsx` - Reusable cover component
- `src/components/ResultsPage.tsx` - Updated to use book covers
- `src/components/CelebrityTesterPage.tsx` - Updated to use book covers

## Next Steps
1. Test with your API key
2. Monitor API usage
3. Consider adding more book data with covers
4. Implement additional fallback strategies 