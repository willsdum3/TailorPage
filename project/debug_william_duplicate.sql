-- Debug script to investigate William Dumbili duplication issue
-- This will help us understand why he appears multiple times

-- First, let's see all friend requests involving William
SELECT 
    'WILLIAM FRIEND REQUESTS' as info,
    fr.id,
    fr.requester_id,
    fr.target_id,
    fr.status,
    fr.created_at,
    u1.name as requester_name,
    u1.username as requester_username,
    u2.name as target_name,
    u2.username as target_username
FROM friend_requests fr
LEFT JOIN users u1 ON fr.requester_id = u1.id
LEFT JOIN users u2 ON fr.target_id = u2.id
WHERE u1.username = 'hereistand' OR u2.username = 'hereistand'
ORDER BY fr.created_at DESC;

-- Check if there are multiple friend requests between the same users
SELECT 
    'DUPLICATE CHECK' as info,
    LEAST(requester_id, target_id) as user1_id,
    GREATEST(requester_id, target_id) as user2_id,
    COUNT(*) as request_count,
    STRING_AGG(status, ', ') as statuses,
    STRING_AGG(id::text, ', ') as request_ids
FROM friend_requests
WHERE (requester_id IN (
    SELECT id FROM users WHERE username = 'hereistand'
) OR target_id IN (
    SELECT id FROM users WHERE username = 'hereistand'
))
GROUP BY LEAST(requester_id, target_id), GREATEST(requester_id, target_id)
HAVING COUNT(*) > 1;

-- Check the current user's friend connections
SELECT 
    'CURRENT USER FRIENDS' as info,
    CASE 
        WHEN fr.requester_id = (SELECT id FROM users WHERE username = 'hereistand') THEN fr.target_id 
        ELSE fr.requester_id 
    END as friend_id,
    CASE 
        WHEN fr.requester_id = (SELECT id FROM users WHERE username = 'hereistand') THEN u2.name 
        ELSE u1.name 
    END as friend_name,
    CASE 
        WHEN fr.requester_id = (SELECT id FROM users WHERE username = 'hereistand') THEN u2.username 
        ELSE u1.username 
    END as friend_username,
    fr.status,
    fr.created_at
FROM friend_requests fr
LEFT JOIN users u1 ON fr.requester_id = u1.id
LEFT JOIN users u2 ON fr.target_id = u2.id
WHERE (fr.requester_id = (SELECT id FROM users WHERE username = 'hereistand') 
   OR fr.target_id = (SELECT id FROM users WHERE username = 'hereistand'))
AND fr.status = 'accepted'
ORDER BY fr.created_at DESC;
