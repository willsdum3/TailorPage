-- Test the get_friend_connections function directly
-- This will show us what the function is actually returning

-- Test the function with William's internal ID
SELECT 
    'get_friend_connections result' as test_type,
    get_friend_connections('3bd64865-45b6-4b2b-81d2-4940a8bf3200'::UUID) as result;

-- Check what the function should return by manually querying
SELECT 
    'Manual query result' as test_type,
    fr.id,
    fr.requester_id,
    fr.target_id,
    fr.status,
    CASE 
        WHEN fr.requester_id = '3bd64865-45b6-4b2b-81d2-4940a8bf3200' THEN u2.id
        ELSE u1.id
    END as friend_id,
    CASE 
        WHEN fr.requester_id = '3bd64865-45b6-4b2b-81d2-4940a8bf3200' THEN u2.name
        ELSE u1.name
    END as friend_name,
    CASE 
        WHEN fr.requester_id = '3bd64865-45b6-4b2b-81d2-4940a8bf3200' THEN u2.username
        ELSE u1.username
    END as friend_username,
    CASE 
        WHEN fr.requester_id = '3bd64865-45b6-4b2b-81d2-4940a8bf3200' THEN u2.avatar_url
        ELSE u1.avatar_url
    END as friend_image_url
FROM friend_requests fr
JOIN users u1 ON fr.requester_id = u1.id
JOIN users u2 ON fr.target_id = u2.id
WHERE (fr.requester_id = '3bd64865-45b6-4b2b-81d2-4940a8bf3200' OR fr.target_id = '3bd64865-45b6-4b2b-81d2-4940a8bf3200')
AND fr.status = 'accepted';
