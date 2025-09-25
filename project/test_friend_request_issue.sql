-- Test the friend request issue to understand the foreign key constraint violation

-- Check the friend_requests table structure
SELECT 
    'friend_requests table structure' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'friend_requests' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check if there are any existing friend requests
SELECT 
    'Existing friend requests' as info,
    COUNT(*) as total_requests
FROM friend_requests;

-- Check if there are any users in the users table
SELECT 
    'Users in database' as info,
    COUNT(*) as total_users
FROM users;

-- Test what happens when we try to get friend connections for William
SELECT 
    'Test get_friend_connections' as info,
    get_friend_connections('ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID) as result;
