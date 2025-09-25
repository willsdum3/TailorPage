-- Check the exact state of William's friends in the database
-- This will help us understand the sync issue between frontend and backend

-- Get William's internal ID
SELECT 
    'William Info' as check_type,
    id as internal_id,
    auth_user_id,
    name,
    username
FROM users 
WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9';

-- Get all of William's current friends
SELECT 
    'William Current Friends' as check_type,
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

-- Check if there are any conversations for William
SELECT 
    'William Conversations' as check_type,
    fc.id as conversation_id,
    fc.user1_id,
    fc.user2_id,
    fc.created_at,
    u1.name as user1_name,
    u2.name as user2_name
FROM friend_conversations fc
JOIN users u1 ON fc.user1_id = u1.id
JOIN users u2 ON fc.user2_id = u2.id
WHERE fc.user1_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9')
   OR fc.user2_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9');
