# Fresh Database Setup Guide

## 🎯 **Overview**
This guide will help you set up a completely fresh database for the Tailor Page app, eliminating all the complex migration issues we've been experiencing.

## 📋 **Prerequisites**
- Access to your Supabase project dashboard
- Supabase project with Supabase Auth enabled

## 🚀 **Step-by-Step Setup**

### **Step 1: Access Supabase SQL Editor**
1. Go to your Supabase project dashboard
2. Navigate to the **SQL Editor** in the left sidebar
3. Click **"New Query"** to create a new SQL script

### **Step 2: Run the Fresh Database Setup**
1. Copy the entire contents of `fresh_database_setup.sql`
2. Paste it into the SQL Editor
3. Click **"Run"** to execute the script

### **Step 3: Verify the Setup**
After running the script, you should see:
- ✅ **"Fresh database setup completed successfully!"**
- ✅ **List of created tables:** `users`, `user_personality_profiles`, `user_favorites`
- ✅ **List of created functions:** Various helper functions

### **Step 4: Test the Database**
1. **Test User Creation:**
   ```sql
   SELECT * FROM users LIMIT 5;
   ```

2. **Test Functions:**
   ```sql
   SELECT routine_name FROM information_schema.routines 
   WHERE routine_schema = 'public' AND routine_type = 'FUNCTION';
   ```

## 🏗️ **Database Structure**

### **Tables Created:**

#### **1. `users` Table**
- `id` - Primary key (UUID)
- `auth_user_id` - Supabase Auth user ID (UUID, unique)
- `name` - User's display name
- `username` - Optional username
- `email` - User's email address
- `avatar_url` - Optional profile picture URL
- `created_at` / `updated_at` - Timestamps

#### **2. `user_personality_profiles` Table**
- `id` - Primary key (UUID)
- `user_id` - References users table
- `openness` - Personality trait score (1-25)
- `conscientiousness` - Personality trait score (1-25)
- `extraversion` - Personality trait score (1-25)
- `agreeableness` - Personality trait score (1-25)
- `emotional_stability` - Personality trait score (1-25)
- `created_at` / `updated_at` - Timestamps

#### **3. `user_favorites` Table**
- `id` - Primary key (UUID)
- `user_id` - References users table
- `book_title` - Book title
- `book_author` - Book author
- `book_genre` - Book genre
- `book_description` - Book description
- `book_amazon_link` - Amazon purchase link
- `book_cover_image_url` - Book cover image URL
- `reason` - Why this book was recommended
- `created_at` - When added to favorites

### **Functions Created:**

#### **1. `get_or_create_user()`**
- Creates or retrieves user profile
- Automatically handles user creation

#### **2. `save_personality_profile()`**
- Saves personality profile for a user
- Handles both insert and update operations

#### **3. `get_personality_profile()`**
- Retrieves user's personality profile
- Returns latest profile if multiple exist

#### **4. `add_book_to_favorites()`**
- Adds a book to user's favorites
- Prevents duplicate entries

#### **5. `remove_book_from_favorites()`**
- Removes a book from user's favorites
- Returns success/failure status

#### **6. `get_user_favorites()`**
- Retrieves all user's favorite books
- Ordered by most recently added

## 🔒 **Security Features**

### **Row Level Security (RLS)**
- All tables have RLS enabled
- Users can only access their own data
- Policies ensure data isolation

### **Authentication Integration**
- All functions use `auth.uid()` for user identification
- Automatic user creation when needed
- Secure data access patterns

## 🧪 **Testing the Setup**

### **Test User Registration:**
1. Register a new user in your app
2. Check the `users` table for the new entry
3. Verify the `auth_user_id` matches the Supabase Auth user

### **Test Quiz Completion:**
1. Complete the personality quiz
2. Check the `user_personality_profiles` table
3. Verify scores are saved correctly (1-25 range)

### **Test Favorites:**
1. Add books to favorites
2. Check the `user_favorites` table
3. Verify books are saved with all details

## 🔧 **Troubleshooting**

### **Common Issues:**

#### **1. "Function does not exist" errors**
- Make sure you ran the complete `fresh_database_setup.sql` script
- Check that all functions were created successfully

#### **2. "Permission denied" errors**
- Verify RLS policies are in place
- Check that user is authenticated
- Ensure proper function permissions

#### **3. "Table does not exist" errors**
- Confirm all tables were created
- Check table names match exactly

### **Reset if Needed:**
If you need to start completely fresh:
```sql
-- Drop everything and start over
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;
```

Then run the `fresh_database_setup.sql` script again.

## 🎉 **Benefits of Fresh Setup**

- ✅ **No legacy issues** - Clean, simple schema
- ✅ **Proper Supabase Auth integration** - Built from the ground up
- ✅ **Type safety** - All functions return proper types
- ✅ **Performance optimized** - Proper indexes and constraints
- ✅ **Security focused** - RLS policies and secure functions
- ✅ **Easy to maintain** - Simple, well-documented structure

## 📞 **Next Steps**

After setting up the fresh database:

1. **Test the app** - Verify all functionality works
2. **Check console logs** - Ensure no database errors
3. **Test user flows** - Registration, quiz, favorites
4. **Deploy to production** - Push changes to Vercel

The fresh database should resolve all the data persistence issues we've been experiencing! 🚀
