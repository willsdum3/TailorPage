-- Test to verify friend removal worked
-- Check current friend connections for a specific user

-- First, let's see what friends exist for the current user
-- Replace 'your_user_id_here' with an actual user ID from your users table
SELECT 
    fr.id,
    fr.requester_id,
    fr.target_id,
    u1.name as requester_name,
    u2.name as target_name,
    fr.status,
    fr.created_at
FROM friend_requests fr
JOIN users u1 ON fr.requester_id = u1.id
JOIN users u2 ON fr.target_id = u2.id
WHERE fr.status = 'accepted'
ORDER BY fr.created_at DESC
LIMIT 10;

-- Check if there are any conversations that should have been deleted
SELECT 
    fc.id as conversation_id,
    u1.name as user1_name,
    u2.name as user2_name,
    fc.created_at
FROM friend_conversations fc
JOIN users u1 ON fc.user1_id = u1.id
JOIN users u2 ON fc.user2_id = u2.id
ORDER BY fc.created_at DESC
LIMIT 10;
