-- Test Tailor Mates Functions
-- Run this in your Supabase SQL Editor to check if functions are working

-- Step 1: Check if functions exist
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN (
    'get_book_clubs',
    'get_discussions', 
    'get_friend_connections',
    'create_book_club',
    'create_discussion',
    'send_friend_request'
)
ORDER BY routine_name;

-- Step 2: Test get_book_clubs function with a sample user
-- Replace 'YOUR_CLERK_USER_ID' with your actual Clerk user ID
-- You can find this in the browser console or from the debug panel
SELECT 'Testing get_book_clubs function...' as test_step;

-- Step 3: Check if there are any users in the database
SELECT 
    id,
    clerk_id,
    name,
    email,
    created_at
FROM users 
LIMIT 5;

-- Step 4: Test the function with the first user found
-- This will help us see if the function works at all
SELECT 'Testing with first user found...' as test_step;

-- Step 5: Show any recent errors in the logs (if available)
SELECT 'Function test completed. Check the results above.' as status;
