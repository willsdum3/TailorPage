-- Debug friend functions - check what exists and what's missing

-- 1. Check if friend-related functions exist
SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%friend%'
ORDER BY routine_name;

-- 2. Check friend_requests table
SELECT 
    'FRIEND_REQUESTS_TABLE' as info,
    COUNT(*) as count
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'friend_requests';

-- 3. Check friend_conversations table
SELECT 
    'FRIEND_CONVERSATIONS_TABLE' as info,
    COUNT(*) as count
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'friend_conversations';

-- 4. Check if we have any friend data
SELECT 
    'FRIEND_REQUESTS_DATA' as info,
    COUNT(*) as count
FROM friend_requests;

SELECT 
    'FRIEND_CONVERSATIONS_DATA' as info,
    COUNT(*) as count
FROM friend_conversations;
