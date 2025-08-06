# Database Setup Instructions for Your Supabase Project

## Your Supabase Project Details:
- **Project URL**: https://ixnjlakqsjhhwfanegzk.supabase.co
- **Project ID**: ixnjlakqsjhhwfanegzk

## Step 1: Access Your Supabase Dashboard

1. Go to: https://supabase.com/dashboard/project/ixnjlakqsjhhwfanegzk
2. Sign in to your Supabase account
3. Navigate to the **SQL Editor** in the left sidebar

## Step 2: Run the Database Schema

### First, run the main database schema:

1. **Copy the entire contents** of `database_schema.sql`
2. **Paste it** into the SQL Editor
3. **Click "Run"** to execute the schema

This will create:
- Users table
- Books table  
- User favorites table
- Personality profiles table
- Book recommendations table
- Reading lists tables
- Activity log table
- All necessary indexes and functions

### Then, run the quiz schema:

1. **Copy the entire contents** of `quiz_results_schema.sql`
2. **Paste it** into the SQL Editor
3. **Click "Run"** to execute the quiz schema

This will create:
- Quiz sessions table
- Quiz questions table
- User quiz responses table
- Personality trait scores table
- Personality insights table
- Reading style analysis table
- Quiz progress tracking table

### Finally, run the webhook handler:

1. **Copy the entire contents** of `supabase_webhook_handler.sql`
2. **Paste it** into the SQL Editor
3. **Click "Run"** to execute the webhook functions

## Step 3: Verify the Setup

After running all three SQL files, you should see:

1. **Tables created** in the Table Editor:
   - `users`
   - `books`
   - `user_favorites`
   - `user_personality_profiles`
   - `book_recommendations`
   - `reading_lists`
   - `reading_list_items`
   - `user_activity_log`
   - `quiz_sessions`
   - `quiz_questions`
   - `user_quiz_responses`
   - `personality_trait_scores`
   - `personality_insights`
   - `reading_style_analysis`
   - `quiz_progress`

2. **Functions created** in the Database → Functions section:
   - `get_user_favorites`
   - `get_user_reading_stats`
   - `add_book_to_favorites`
   - `start_quiz_session`
   - `save_quiz_response`
   - `complete_quiz_session`
   - `get_user_latest_quiz_results`
   - `clerk_webhook`
   - `get_or_create_user`

## Step 4: Test the Connection

Once the database is set up, you can test the connection by:

1. **Starting your development server**:
   ```bash
   npm start
   ```

2. **Sign up/sign in with Clerk** - this should automatically create a user in Supabase

3. **Check your Supabase dashboard**:
   - Go to Table Editor
   - Check the `users` table to see if your user was created

## Troubleshooting

If you encounter any errors:

1. **Check the SQL Editor logs** for specific error messages
2. **Make sure you're running the SQL files in order** (main schema → quiz schema → webhook handler)
3. **Verify your environment variables** are set correctly in the `.env` file
4. **Restart your development server** after setting environment variables

## Next Steps

After the database is set up:

1. **Configure Clerk webhooks** (optional but recommended)
2. **Test user synchronization** by signing up/signing in
3. **Test the favorites functionality** using the helper functions
4. **Implement quiz result storage** using the quiz schema

Your Supabase project is now ready to work with your Tailor Page App! 