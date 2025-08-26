# Supabase Auth Migration Guide

This guide will help you migrate your Tailor Page App from Clerk authentication to Supabase Auth.

## 📋 Prerequisites

Before starting the migration, ensure you have:

1. **Supabase Project Setup**
   - A Supabase project with authentication enabled
   - Your Supabase URL and anon key
   - Access to the Supabase SQL editor

2. **Backup Your Data**
   - Export any important user data from your current Clerk setup
   - Document your current database schema

3. **Development Environment**
   - Your local development environment ready
   - Git repository with current state committed

## 🚀 Migration Steps

### Step 1: Update Environment Variables

1. **Remove Clerk Environment Variables**
   ```bash
   # Remove from your .env file
   VITE_CLERK_PUBLISHABLE_KEY=your_clerk_key_here
   ```

2. **Ensure Supabase Environment Variables**
   ```bash
   # Make sure these are in your .env file
   VITE_SUPABASE_URL=your_supabase_url_here
   VITE_SUPABASE_ANON_KEY=your_supabase_anon_key_here
   VITE_SUPABASE_SERVICE_KEY=your_supabase_service_key_here
   ```

### Step 2: Run Database Migration

1. **Open Supabase SQL Editor**
   - Go to your Supabase dashboard
   - Navigate to SQL Editor
   - Create a new query

2. **Run the Migration Script**
   - Copy the contents of `migrate_to_supabase_auth.sql`
   - Paste it into the SQL editor
   - Execute the script

3. **Verify Migration Success**
   - Check the verification queries at the end of the script
   - Ensure all tables have the new `auth_user_id` columns
   - Confirm RLS policies are in place

### Step 3: Update Application Code

1. **Install Supabase Dependencies** (Already done)
   ```bash
   npm install @supabase/supabase-js @supabase/auth-ui-react @supabase/auth-ui-shared
   ```

2. **Update main.tsx** (Already done)
   - Replaced ClerkProvider with AuthProvider

3. **Update App.tsx** (In progress)
   - Replace Clerk authentication with Supabase Auth
   - Update user conversion logic
   - Fix component prop interfaces

### Step 4: Test the Migration

1. **Test User Registration**
   - Try creating a new account
   - Verify user data is saved to the database
   - Check that the `auth_user_id` is properly set

2. **Test User Login**
   - Try logging in with existing credentials
   - Verify authentication state is maintained
   - Check that user data loads correctly

3. **Test Core Features**
   - Test favorites functionality
   - Test personality profile saving
   - Test quiz completion and data persistence

## 🔧 Troubleshooting

### Common Issues

1. **RLS Policy Errors**
   ```
   Error: new row violates row-level security policy
   ```
   **Solution**: Ensure RLS policies are properly configured and the user is authenticated.

2. **Function Parameter Mismatch**
   ```
   Error: function does not exist
   ```
   **Solution**: Make sure all stored procedures have been updated with the new `auth_user_id` parameter.

3. **Authentication State Issues**
   ```
   Error: user not found
   ```
   **Solution**: Check that the Supabase Auth context is properly wrapping your app.

### Rollback Plan

If you need to revert the migration:

1. **Run the Rollback Script**
   - Use `rollback_supabase_migration.sql`
   - This will restore the original Clerk-based schema

2. **Revert Code Changes**
   - Restore the original `main.tsx` with ClerkProvider
   - Restore the original `App.tsx` with Clerk authentication
   - Remove Supabase Auth dependencies

3. **Restore Environment Variables**
   - Add back `VITE_CLERK_PUBLISHABLE_KEY`
   - Remove Supabase Auth variables if not needed

## 📊 Migration Checklist

- [ ] Environment variables updated
- [ ] Database migration script executed
- [ ] RLS policies verified
- [ ] Stored procedures updated
- [ ] AuthContext implemented
- [ ] AuthModal component created
- [ ] main.tsx updated
- [ ] App.tsx authentication logic updated
- [ ] User registration tested
- [ ] User login tested
- [ ] Favorites functionality tested
- [ ] Personality profile functionality tested
- [ ] Quiz functionality tested
- [ ] All components updated for new auth system

## 🔒 Security Considerations

1. **RLS Policies**
   - All user data is protected by Row Level Security
   - Users can only access their own data
   - Policies use `auth.uid()` for authentication

2. **Function Security**
   - All stored procedures use `SECURITY DEFINER`
   - Functions validate user ownership before operations

3. **Environment Variables**
   - Never commit service keys to version control
   - Use environment variables for all sensitive data

## 📈 Performance Considerations

1. **Indexes**
   - Added indexes on `auth_user_id` columns for better query performance
   - Existing indexes on other columns are maintained

2. **Function Optimization**
   - Stored procedures are optimized for common operations
   - Batch operations where possible

## 🎯 Next Steps

After successful migration:

1. **Monitor Performance**
   - Watch for any performance issues
   - Monitor database query performance

2. **User Communication**
   - Inform users about the authentication change
   - Provide migration instructions if needed

3. **Cleanup**
   - Remove old Clerk dependencies
   - Clean up unused environment variables
   - Remove backup tables after confirming success

## 📞 Support

If you encounter issues during migration:

1. **Check Supabase Documentation**
   - [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
   - [RLS Policies Guide](https://supabase.com/docs/guides/auth/row-level-security)

2. **Review Migration Scripts**
   - Check the migration script for any errors
   - Verify all steps were completed

3. **Test Incrementally**
   - Test each component individually
   - Use browser developer tools to debug issues

## 🎉 Success Criteria

The migration is successful when:

- ✅ Users can register and login with Supabase Auth
- ✅ All user data is properly associated with Supabase Auth users
- ✅ Favorites functionality works correctly
- ✅ Personality profiles are saved and retrieved properly
- ✅ Quiz functionality works end-to-end
- ✅ No authentication errors in the console
- ✅ All RLS policies are working correctly

---

**Note**: This migration is designed to be reversible. If you encounter any issues, you can use the rollback script to restore the original Clerk-based system.
