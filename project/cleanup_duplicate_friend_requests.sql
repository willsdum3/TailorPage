-- Clean up duplicate friend requests
-- This script will remove duplicate friend requests, keeping only the most recent one

-- First, let's see what duplicates exist
SELECT 
    'DUPLICATES FOUND' as info,
    LEAST(requester_id, target_id) as user1_id,
    GREATEST(requester_id, target_id) as user2_id,
    COUNT(*) as duplicate_count,
    STRING_AGG(id::text, ', ') as request_ids,
    STRING_AGG(status, ', ') as statuses,
    STRING_AGG(created_at::text, ', ') as created_dates
FROM friend_requests
GROUP BY LEAST(requester_id, target_id), GREATEST(requester_id, target_id)
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Delete duplicate friend requests, keeping only the most recent one
WITH duplicates AS (
    SELECT 
        id,
        LEAST(requester_id, target_id) as user1_id,
        GREATEST(requester_id, target_id) as user2_id,
        ROW_NUMBER() OVER (
            PARTITION BY LEAST(requester_id, target_id), GREATEST(requester_id, target_id) 
            ORDER BY created_at DESC
        ) as rn
    FROM friend_requests
)
DELETE FROM friend_requests 
WHERE id IN (
    SELECT id FROM duplicates WHERE rn > 1
);

-- Show the cleanup results
SELECT 
    'CLEANUP COMPLETE' as info,
    COUNT(*) as remaining_friend_requests
FROM friend_requests;

-- Show remaining friend requests for William
SELECT 
    'WILLIAM REMAINING FRIENDS' as info,
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
