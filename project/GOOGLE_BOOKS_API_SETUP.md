# Google Books API Setup Guide

## Why Google Books API?

The Google Books API provides the **highest quality, most accurate book covers** that match exactly what you'd see on Amazon or in bookstores. It's the gold standard for book cover images.

## Step-by-Step Setup

### 1. Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click "Select a project" → "New Project"
3. Name your project (e.g., "Tailor Page Book Covers")
4. Click "Create"

### 2. Enable Google Books API

1. In your new project, go to "APIs & Services" → "Library"
2. Search for "Google Books API"
3. Click on "Google Books API"
4. Click "Enable"

### 3. Create API Key

1. Go to "APIs & Services" → "Credentials"
2. Click "Create Credentials" → "API Key"
3. Copy the generated API key (it will look like: `AIzaSyC...`)

### 4. Secure Your API Key (Recommended)

1. Click on your newly created API key
2. Under "Application restrictions", select "HTTP referrers (web sites)"
3. Add your domain(s):
   - For development: `localhost:3000/*`
   - For production: `yourdomain.com/*`
4. Under "API restrictions", select "Restrict key"
5. Select "Google Books API" from the dropdown
6. Click "Save"

### 5. Add to Your Project

1. Create a `.env` file in your project root (if it doesn't exist)
2. Add your API key:
   ```
   VITE_GOOGLE_BOOKS_API_KEY=your_actual_api_key_here
   ```
3. Replace `your_actual_api_key_here` with your actual API key

### 6. Restart Your Development Server

```bash
npm run dev
```

## Benefits of Google Books API

### ✅ **Official Covers**
- Exact same covers as Amazon, Barnes & Noble, etc.
- High-resolution images
- Professional quality

### ✅ **Better Accuracy**
- More precise title/author matching
- Handles different editions correctly
- Includes ISBN matching

### ✅ **Higher Coverage**
- ~85-90% coverage vs ~70-80% with OpenLibrary
- Better for obscure or newer books
- More comprehensive database

### ✅ **Image Quality**
- Multiple size options
- No compression artifacts
- Professional presentation

## API Limits & Costs

### Free Tier
- **1,000 requests per day** (free)
- **100 requests per 100 seconds** (rate limit)
- Perfect for most applications

### Paid Tier (if needed)
- $5 per 1,000 additional requests
- Only needed for very high-traffic sites

## Testing Your Setup

1. Open your app in the browser
2. Open Developer Tools (F12)
3. Go to Console tab
4. You should see: "Google Books API key configured successfully"
5. Book covers should load with higher quality

## Troubleshooting

### API Key Not Working
1. Check that the API key is correct
2. Verify Google Books API is enabled
3. Check API restrictions aren't too restrictive
4. Ensure the `.env` file is in the project root

### Rate Limits
1. The app automatically caches results
2. Failed requests are cached to avoid repeated failures
3. Consider upgrading if you hit limits frequently

### Covers Still Not Loading
1. Check browser console for errors
2. Verify the API key is being read correctly
3. The app will fall back to OpenLibrary automatically

## Next Steps

1. **Test with a few books** to see the quality improvement
2. **Monitor your API usage** in Google Cloud Console
3. **Consider upgrading** if you need more than 1,000 requests/day
4. **Add manual overrides** for any books that still have issues

## Security Notes

- Never commit your API key to version control
- Use environment variables (as shown above)
- Restrict the API key to your domain
- Monitor usage in Google Cloud Console

Your book covers should now be the official, high-quality versions that match what users see everywhere else!
