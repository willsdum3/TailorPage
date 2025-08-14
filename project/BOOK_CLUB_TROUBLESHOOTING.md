# Book Club Creation Troubleshooting Guide

## Overview
This guide addresses the common issues users encounter when trying to create book clubs in the Tailor Mates feature.

## Common Error Messages

### 1. "User not found in database. Please try logging out and back in."

**Cause:** The user exists in Clerk (authentication) but not in the Supabase `users` table.

**Solutions:**

#### Automatic Fix (Recommended)
1. **Log out and log back in** - This triggers the user sync process
2. **Wait for sync** - The system will automatically create the user record
3. **Try creating the book club again**

#### Manual Fix (If automatic doesn't work)
1. **Clear browser cache and cookies**
2. **Log out completely**
3. **Log back in**
4. **Wait 30 seconds for sync to complete**
5. **Try creating the book club again**

#### Developer Fix (If issues persist)
1. Check the browser console for sync errors
2. Verify Supabase connection
3. Check if the `users` table exists and has proper permissions

### 2. "Failed to create book club. Please try again."

**Cause:** Various database or permission issues.

**Solutions:**

#### Check Prerequisites
1. **Ensure you're logged in** - You must be authenticated
2. **Complete the personality quiz** - Required for book club features
3. **Verify Tailor Mates is enabled** - Check if the feature is active

#### Database Issues
1. **Check if Tailor Mates tables exist**
   - The system requires `book_clubs`, `book_club_members`, etc.
   - Contact support if tables are missing

2. **Verify database permissions**
   - Ensure RLS (Row Level Security) policies are correct
   - Check if user has proper permissions

#### Form Validation Issues
1. **Fill all required fields:**
   - Club name (required)
   - Description (required)
   - At least one personality trait (required)
   - At least one tag (required)

2. **Check field formats:**
   - Club name should be unique
   - Description should be meaningful
   - Meeting date should be in the future

## Enhanced Error Handling

### Recent Improvements

#### 1. **Automatic User Creation**
- The system now automatically creates user records if they don't exist
- User data is passed from Clerk to Supabase during book club creation
- Retry logic handles temporary network issues

#### 2. **Better Error Messages**
- More specific error messages for different failure types
- Clear guidance on how to resolve issues
- Helpful suggestions for common problems

#### 3. **User Sync Status**
- Visual indicator shows sync status
- Retry button for failed syncs
- Real-time feedback on sync progress

#### 4. **Robust Retry Logic**
- Automatic retries for network issues
- Exponential backoff for failed requests
- Graceful degradation when sync fails

## Technical Implementation

### User Sync Process
```typescript
// Enhanced user sync with retry logic
const syncUser = async () => {
  let retryCount = 0;
  const maxRetries = 3;
  
  while (retryCount < maxRetries) {
    try {
      const result = await upsertUser(userData);
      if (result) {
        setSyncStatus('success');
        return;
      }
    } catch (error) {
      retryCount++;
      if (retryCount >= maxRetries) throw error;
      await new Promise(resolve => setTimeout(resolve, 1000 * retryCount));
    }
  }
};
```

### Book Club Creation Process
```typescript
// Enhanced book club creation with user creation fallback
const createBookClub = async (clubData, clerkUserId, userData) => {
  // Check if tables exist
  const tablesExist = await checkTablesExist();
  if (!tablesExist) {
    throw new Error('Database tables not found. Please contact support.');
  }

  // Ensure user exists, create if needed
  let userExists = false;
  try {
    userExists = await ensureUserExists(clerkUserId);
  } catch (error) {
    if (userData) {
      const created = await createUserIfNotExists(clerkUserId, userData);
      if (created) userExists = true;
    } else {
      throw error;
    }
  }

  // Create book club
  const result = await supabase.rpc('create_book_club', {
    user_clerk_id: clerkUserId,
    // ... other club data
  });

  return result;
};
```

## Monitoring and Debugging

### Console Logs
The system provides detailed logging for debugging:

```javascript
// User sync logs
console.log('useUserSync: User detected, syncing to Supabase...');
console.log('useUserSync: User data to sync:', userData);
console.log('useUserSync: Upsert result:', result);

// Book club creation logs
console.log('Creating book club with data:', clubData);
console.log('User found in database:', clerkUserId);
console.log('Book club created successfully:', data);
```

### Error Tracking
- All errors are logged with detailed information
- Error messages include context and suggestions
- Failed operations are tracked for debugging

## Prevention Strategies

### 1. **Proactive User Sync**
- Users are automatically synced when they log in
- Sync happens before any Tailor Mates operations
- Retry logic handles temporary failures

### 2. **Form Validation**
- Client-side validation prevents invalid submissions
- Clear error messages guide users
- Required fields are clearly marked

### 3. **Database Health Checks**
- System checks if required tables exist
- Verifies user permissions before operations
- Provides helpful error messages for missing resources

## Support Information

### When to Contact Support
- Persistent "User not found" errors after logout/login
- Database table missing errors
- Permission denied errors
- Any errors that persist after following this guide

### Information to Provide
- Error message (exact text)
- Browser console logs
- Steps taken to reproduce the issue
- User ID (if available)
- Browser and OS information

## Future Improvements

### Planned Enhancements
1. **Real-time sync status** - Show sync progress in UI
2. **Automatic recovery** - Self-healing for common issues
3. **Better error categorization** - More specific error types
4. **User guidance** - In-app help and tutorials

### Monitoring
- Track sync success rates
- Monitor book club creation success
- Alert on unusual error patterns
- Performance metrics for user operations

This troubleshooting guide should resolve most book club creation issues. If problems persist, please contact support with the specific error messages and steps taken.
