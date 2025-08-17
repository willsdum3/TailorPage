-- Fix User Sync for Tailor Mates
-- Run this in your Supabase SQL Editor to manually sync your user account

-- First, let's see what users exist
SELECT id, clerk_id, name, email, created_at FROM users LIMIT 10;

-- If your user doesn't exist, you'll need to insert them manually
-- Replace 'YOUR_CLERK_USER_ID' with your actual Clerk user ID from the debug panel
-- You can find this in your browser console or from the Clerk dashboard

-- Example manual user insertion (uncomment and modify as needed):
/*
INSERT INTO users (clerk_id, name, username, email, image_url, created_at, updated_at)
VALUES (
  'YOUR_CLERK_USER_ID_HERE',  -- Replace with your actual Clerk user ID
  'Your Name',                -- Replace with your actual name
  'yourusername',             -- Replace with your actual username
  'your.email@example.com',   -- Replace with your actual email
  'https://example.com/avatar.jpg', -- Replace with your actual image URL
  NOW(),
  NOW()
);
*/

-- Check if the user was created successfully
-- SELECT * FROM users WHERE clerk_id = 'YOUR_CLERK_USER_ID_HERE';

-- Success message
SELECT 'User sync script ready. Check the comments above for instructions.' as status;

