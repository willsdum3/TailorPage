# Book Covers Setup Guide

This guide will help you ensure all books in your Tailor Page app display proper covers instead of "Cover Not Found" placeholders.

## 🚀 Quick Setup

### 1. Google Books API Key (Recommended)

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable the "Books API"
4. Create credentials (API Key)
5. Add the key to your `.env` file:
   ```
   VITE_GOOGLE_BOOKS_API_KEY=your_api_key_here
   ```

### 2. Test Your Setup

Open your browser console and run:
```javascript
// Test a specific book
import { testBookCover } from './src/utils/bookCoverEnhancer';
await testBookCover('The Midnight Library', 'Matt Haig');

// Test multiple books
import { debugBookCovers } from './src/utils/bookCoverEnhancer';
const books = [
  { id: '1', title: 'Klara and the Sun', author: 'Kazuo Ishiguro' },
  { id: '2', title: 'The Seven Husbands of Evelyn Hugo', author: 'Taylor Jenkins Reid' }
];
await debugBookCovers(books);
```

## 🔧 How the System Works

### Fallback Chain (in order of priority):

1. **Manual Overrides** - Most reliable, hardcoded URLs
2. **Google Books API** - High quality, requires API key
3. **OpenLibrary API** - Free, good coverage
4. **Internet Archive API** - Additional fallback
5. **Professional Placeholder** - Generated with title/author

### Caching System:

- Covers are cached by title-author combination
- Cache persists during app session
- Manual cache clearing available

## 📝 Adding Manual Overrides

When you find books showing "Cover Not Found", add them to `src/utils/bookCoverService.ts`:

```typescript
const manualCoverOverrides: Record<string, string> = {
  // Existing overrides...
  
  // Add new ones here
  'your-book-title': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/GOODREADS_ID.jpg',
};
```

### Finding Goodreads Cover URLs:

1. Go to [Goodreads.com](https://goodreads.com)
2. Search for your book
3. Right-click on the cover image
4. Copy image URL
5. Replace `GOODREADS_ID` in the template above

### Example:
```typescript
'never-let-me-go': 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327942880i/6334.jpg',
```

## 🛠️ Maintenance Tools

### 1. Debug Specific Books

```javascript
import { testBookCover } from './src/utils/bookCoverEnhancer';

// Test a book that's showing "Cover Not Found"
await testBookCover('Book Title', 'Author Name');
```

### 2. Batch Debug Multiple Books

```javascript
import { debugBookCovers } from './src/utils/bookCoverEnhancer';

const books = [
  { id: '1', title: 'Book 1', author: 'Author 1' },
  { id: '2', title: 'Book 2', author: 'Author 2' },
  // Add all your books here
];

const results = await debugBookCovers(books);
console.log(`Success rate: ${results.summary.successRate}%`);
```

### 3. Generate Manual Override Code

```javascript
import { generateManualOverrides } from './src/utils/bookCoverEnhancer';

// After running debugBookCovers, generate override code
const overrideCode = generateManualOverrides(results.failed);
console.log(overrideCode);
```

## 🔍 Troubleshooting

### Common Issues:

1. **"Cover Not Found" still appears**
   - Check if the book is in manual overrides
   - Verify the override key matches the book title
   - Test with `testBookCover()` function

2. **API Key not working**
   - Verify the key is in `.env` file
   - Check if Books API is enabled in Google Cloud Console
   - Ensure the key has proper permissions

3. **Slow loading**
   - Covers are cached after first load
   - Consider preloading covers for better UX
   - Use the `preloadBookCovers()` function

### Performance Tips:

1. **Preload covers** for better user experience:
   ```javascript
   import { preloadBookCovers } from './src/utils/bookCoverService';
   
   const books = [/* your book list */];
   await preloadBookCovers(books);
   ```

2. **Clear cache** when needed:
   ```javascript
   import { clearBookCoverCache } from './src/utils/bookCoverService';
   clearBookCoverCache();
   ```

## 📊 Monitoring

### Check Cache Statistics:

```javascript
import { getCacheStats } from './src/utils/bookCoverService';

const stats = getCacheStats();
console.log(`Cached covers: ${stats.size}`);
console.log(`Cached books:`, stats.entries);
```

### Regular Maintenance:

1. **Weekly**: Check for new "Cover Not Found" books
2. **Monthly**: Update manual overrides for missing covers
3. **Quarterly**: Review API usage and performance

## 🎯 Best Practices

1. **Always test** new manual overrides before deploying
2. **Use consistent** naming for override keys
3. **Keep backups** of your manual overrides
4. **Monitor API usage** if using Google Books API
5. **Update regularly** as new books are added to your app

## 🚀 Docker Deployment

Remember to rebuild your Docker image after updating environment variables:

```bash
# Rebuild with new environment variables
docker build -t tailorpage .

# Run the updated container
docker run -d -p 3000:80 tailorpage
```

## 📞 Support

If you're still having issues:

1. Check the browser console for error messages
2. Verify all API keys are correctly set
3. Test with the debugging tools provided
4. Check if the book exists in the APIs being used

The system is designed to be robust with multiple fallbacks, so even without API keys, you should see professional placeholder covers instead of "Cover Not Found" messages. 