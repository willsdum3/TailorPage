-- =====================================================
-- SIMPLE AVATAR CHECK WITH SELECT STATEMENTS
-- =====================================================
-- This uses SELECT statements that will definitely show results

-- Check 1: Total users
SELECT 'Total Users' as check_type, COUNT(*) as count FROM users;

-- Check 2: Users with usernames
SELECT 'Users with Usernames' as check_type, COUNT(*) as count 
FROM users 
WHERE username IS NOT NULL AND username != '';

-- Check 3: Users with avatar URLs
SELECT 'Users with Avatar URLs' as check_type, COUNT(*) as count 
FROM users 
WHERE avatar_url IS NOT NULL AND avatar_url != '' AND avatar_url != 'null';

-- Check 4: Sample user data
SELECT 
    'Sample User Data' as info,
    username,
    name,
    CASE 
        WHEN avatar_url IS NULL THEN 'NULL'
        WHEN avatar_url = '' THEN 'EMPTY'
        WHEN LENGTH(avatar_url) < 10 THEN 'TOO_SHORT'
        ELSE 'HAS_URL'
    END as avatar_status,
    LEFT(COALESCE(avatar_url, 'NULL'), 50) as avatar_preview
FROM users 
WHERE username IS NOT NULL 
ORDER BY created_at DESC 
LIMIT 5;

-- Check 5: Test search function for 'kat'
SELECT 
    'Search Test for kat' as test_name,
    username,
    name,
    CASE 
        WHEN avatar_url IS NULL THEN 'NULL'
        WHEN avatar_url = '' THEN 'EMPTY'
        ELSE 'HAS_URL'
    END as avatar_status,
    LEFT(COALESCE(avatar_url, 'NULL'), 50) as avatar_preview
FROM search_users_by_username('kat', 10);

-- Check 6: Test search function for 'a' (broader)
SELECT 
    'Search Test for a' as test_name,
    username,
    name,
    CASE 
        WHEN avatar_url IS NULL THEN 'NULL'
        WHEN avatar_url = '' THEN 'EMPTY'
        ELSE 'HAS_URL'
    END as avatar_status
FROM search_users_by_username('a', 5);

-- Check 7: Let's manually verify the users table structure
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check 8: If no avatars exist, let's try to add a test one
-- First check if we can update an existing user with a test avatar
UPDATE users 
SET avatar_url = 'https://via.placeholder.com/150/FF0000/FFFFFF?text=TEST'
WHERE username = 'katslater' -- Using the username from your screenshot
AND (avatar_url IS NULL OR avatar_url = '' OR avatar_url = 'null');

-- Check if the update worked
SELECT 
    'After Test Update' as info,
    username,
    name,
    avatar_url
FROM users 
WHERE username = 'katslater';

-- Test search again after the update
SELECT 
    'Search After Update' as test_name,
    username,
    name,
    avatar_url
FROM search_users_by_username('kat', 5);
