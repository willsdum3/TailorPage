-- Test the get_friend_connections function directly to see what it returns

-- Test the function with William's internal ID
SELECT 
    'get_friend_connections function result' as test_type,
    get_friend_connections('3bd64865-45b6-4b2b-81d2-4940a8bf3200'::UUID) as result;

-- Check if the function exists and what it does
SELECT 
    'Function Definition' as test_type,
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_name = 'get_friend_connections'
AND routine_schema = 'public';
