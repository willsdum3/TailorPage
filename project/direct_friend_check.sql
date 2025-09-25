-- Direct check to see what's happening with the friends data

-- Check all friend_requests with details
SELECT 
    'All Friend Requests' as check_type,
    fr.id,
    fr.requester_id,
    fr.target_id,
    fr.status,
    fr.created_at,
    u1.name as requester_name,
    u2.name as target_name
FROM friend_requests fr
LEFT JOIN users u1 ON fr.requester_id = u1.id
LEFT JOIN users u2 ON fr.target_id = u2.id
ORDER BY fr.created_at DESC;

-- Check William's user record
SELECT 
    'William User Record' as check_type,
    id,
    auth_user_id,
    name,
    username
FROM users 
WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9';

-- Test the function with William's internal ID
SELECT 
    'Function Test' as check_type,
    get_friend_connections('3bd64865-45b6-4b2b-81d2-4940a8bf3200'::UUID) as result;
