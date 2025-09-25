-- Debug the get_friend_connections function issue
-- This will help us understand why it's returning incorrect data

-- Check William's actual friends in the database
SELECT 
    'William Actual Friends' as check_type,
    fr.id,
    fr.requester_id,
    fr.target_id,
    fr.status,
    u1.name as requester_name,
    u2.name as target_name
FROM friend_requests fr
LEFT JOIN users u1 ON fr.requester_id = u1.id
LEFT JOIN users u2 ON fr.target_id = u2.id
WHERE fr.requester_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9')
   OR fr.target_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9');

-- Test the get_friend_connections function directly
SELECT 
    'Function Result' as check_type,
    get_friend_connections('3bd64865-45b6-4b2b-81d2-4940a8bf3200'::UUID) as result;

-- Check if there are any friend_requests at all
SELECT 
    'All Friend Requests' as check_type,
    COUNT(*) as total_count
FROM friend_requests;

-- Check if there are any friend_requests with accepted status
SELECT 
    'Accepted Friend Requests' as check_type,
    COUNT(*) as accepted_count
FROM friend_requests
WHERE status = 'accepted';
