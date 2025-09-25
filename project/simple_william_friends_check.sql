-- Simple check for William's friends in the database

-- Check if William exists
SELECT 
    'William Exists' as check_type,
    id as internal_id,
    auth_user_id,
    name,
    username
FROM users 
WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9';

-- Check all friend_requests in the database
SELECT 
    'All Friend Requests' as check_type,
    fr.id,
    fr.requester_id,
    fr.target_id,
    fr.status,
    u1.name as requester_name,
    u2.name as target_name
FROM friend_requests fr
LEFT JOIN users u1 ON fr.requester_id = u1.id
LEFT JOIN users u2 ON fr.target_id = u2.id
ORDER BY fr.created_at DESC;

-- Check if there are any friend_requests at all
SELECT 
    'Total Friend Requests' as check_type,
    COUNT(*) as total_count
FROM friend_requests;
