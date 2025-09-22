-- Comprehensive friend system diagnosis
-- This will show exactly what's missing and causing the 400 errors

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

-- 2. Check if users table exists and has data
SELECT 
    'USERS_TABLE_STATUS' as info,
    COUNT(*) as user_count
FROM users;

-- 3. Show sample users (first 3)
SELECT 
    'SAMPLE_USERS' as info,
    id,
    name,
    username,
    auth_user_id
FROM users
LIMIT 3;

-- 4. Check friend_requests table structure
SELECT 
    'FRIEND_REQUESTS_TABLE_STRUCTURE' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'friend_requests'
ORDER BY ordinal_position;

-- 5. Check if friend_requests table has any data
SELECT 
    'FRIEND_REQUESTS_DATA' as info,
    COUNT(*) as request_count
FROM friend_requests;

-- 6. Show all friend-related tables
SELECT 
    'FRIEND_RELATED_TABLES' as info,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE '%friend%'
ORDER BY table_name;

-- 7. Check if any friend functions exist at all
SELECT 
    'ALL_FUNCTIONS_WITH_FRIEND' as info,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND (routine_name LIKE '%friend%' OR routine_name LIKE '%Friend%')
ORDER BY routine_name;
