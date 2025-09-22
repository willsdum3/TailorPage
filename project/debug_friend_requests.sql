-- Debug friend requests system
-- Check if the get_friend_requests function exists and works

-- 1. Check if function exists
SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name = 'get_friend_requests';

-- 2. Check friend_requests table structure
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'friend_requests'
ORDER BY ordinal_position;

-- 3. Check if there are any friend requests in the table
SELECT 
    'FRIEND REQUESTS COUNT' as info,
    COUNT(*) as count
FROM friend_requests;

-- 4. Show sample friend requests data
SELECT 
    'SAMPLE FRIEND REQUESTS' as info,
    id,
    requester_id,
    target_id,
    status,
    message,
    created_at
FROM friend_requests
ORDER BY created_at DESC
LIMIT 5;

-- 5. Test the function directly (replace with actual user ID)
-- SELECT * FROM get_friend_requests('your-user-id-here'::UUID);
