-- Check William's actual friends in the database
-- This will show us the real state vs what the UI is showing

-- Get William's internal ID
SELECT 
    'William Info' as info,
    id as internal_id,
    auth_user_id,
    name,
    username
FROM users 
WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9';

-- Get all of William's actual friends from the database
SELECT 
    'William Actual Friends' as info,
    fr.id as friendship_id,
    fr.requester_id,
    fr.target_id,
    fr.status,
    fr.created_at,
    u1.name as requester_name,
    u2.name as target_name,
    CASE 
        WHEN fr.requester_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9') THEN 'William is requester'
        WHEN fr.target_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9') THEN 'William is target'
        ELSE 'Unknown relationship'
    END as relationship_type
FROM friend_requests fr
JOIN users u1 ON fr.requester_id = u1.id
JOIN users u2 ON fr.target_id = u2.id
WHERE fr.requester_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9')
   OR fr.target_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9')
ORDER BY fr.created_at DESC;

-- Check if Tailor Page exists
SELECT 
    'Tailor Page Info' as info,
    id as internal_id,
    auth_user_id,
    name,
    username
FROM users 
WHERE id = 'df1ec11e-9b78-4fb5-8218-c6fb03320100';
