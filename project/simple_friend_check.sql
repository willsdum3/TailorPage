-- Simple friend functions check - no complex joins
-- This will show basic information about friend functions

-- 1. Check if friend functions exist
SELECT 
    'FRIEND_FUNCTIONS_STATUS' as info,
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%friend%'
ORDER BY routine_name;

-- 2. Check if friend_requests table exists
SELECT 
    'FRIEND_REQUESTS_TABLE' as info,
    COUNT(*) as table_exists
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'friend_requests';

-- 3. Check if users table has data
SELECT 
    'USERS_TABLE_DATA' as info,
    COUNT(*) as user_count
FROM users;

-- 4. Check if friend_requests table has any data
SELECT 
    'FRIEND_REQUESTS_DATA' as info,
    COUNT(*) as request_count
FROM friend_requests;

-- 5. Show all tables that contain 'friend' in the name
SELECT 
    'FRIEND_RELATED_TABLES' as info,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE '%friend%'
ORDER BY table_name;
