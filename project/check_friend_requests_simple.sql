-- Simple check of friend requests without complex JOINs

-- Check all friend_requests
SELECT 
    'Friend Requests' as check_type,
    id,
    requester_id,
    target_id,
    status,
    created_at
FROM friend_requests
ORDER BY created_at DESC;

-- Check if William has any friend requests (as requester)
SELECT 
    'William as Requester' as check_type,
    id,
    requester_id,
    target_id,
    status,
    created_at
FROM friend_requests
WHERE requester_id = '3bd64865-45b6-4b2b-81d2-4940a8bf3200';

-- Check if William has any friend requests (as target)
SELECT 
    'William as Target' as check_type,
    id,
    requester_id,
    target_id,
    status,
    created_at
FROM friend_requests
WHERE target_id = '3bd64865-45b6-4b2b-81d2-4940a8bf3200';
