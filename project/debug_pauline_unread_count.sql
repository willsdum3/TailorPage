-- Debug Pauline Dumbili's unread message count issue
-- Check why she has a constant unread count of 1

-- First, get Pauline's user information
SELECT 
    'Pauline User Info' as info,
    id as internal_id,
    auth_user_id,
    name,
    username
FROM users 
WHERE username = 'paulinedumbili6' OR name = 'Pauline Dumbili';

-- Check her friend conversations
SELECT 
    'Pauline Friend Conversations' as info,
    fc.id as conversation_id,
    fc.user1_id,
    fc.user2_id,
    u1.name as user1_name,
    u2.name as user2_name
FROM friend_conversations fc
JOIN users u1 ON fc.user1_id = u1.id
JOIN users u2 ON fc.user2_id = u2.id
WHERE fc.user1_id = (SELECT id FROM users WHERE username = 'paulinedumbili6')
   OR fc.user2_id = (SELECT id FROM users WHERE username = 'paulinedumbili6');

-- Check her friend requests (accepted friendships)
SELECT 
    'Pauline Friend Requests' as info,
    fr.id,
    fr.requester_id,
    fr.target_id,
    fr.status,
    u1.name as requester_name,
    u2.name as target_name
FROM friend_requests fr
JOIN users u1 ON fr.requester_id = u1.id
JOIN users u2 ON fr.target_id = u2.id
WHERE (fr.requester_id = (SELECT id FROM users WHERE username = 'paulinedumbili6')
   OR fr.target_id = (SELECT id FROM users WHERE username = 'paulinedumbili6'))
AND fr.status = 'accepted';

-- Check messages in her conversations
SELECT 
    'Pauline Messages' as info,
    fm.id as message_id,
    fm.conversation_id,
    fm.sender_id,
    fm.content,
    fm.created_at,
    u.name as sender_name
FROM friend_messages fm
JOIN users u ON fm.sender_id = u.id
WHERE fm.conversation_id IN (
    SELECT md5(LEAST(fr.requester_id, fr.target_id)::text || GREATEST(fr.requester_id, fr.target_id)::text)::uuid
    FROM friend_requests fr
    WHERE (fr.requester_id = (SELECT id FROM users WHERE username = 'paulinedumbili6')
       OR fr.target_id = (SELECT id FROM users WHERE username = 'paulinedumbili6'))
    AND fr.status = 'accepted'
)
ORDER BY fm.created_at DESC;

-- Check her read status for conversations
SELECT 
    'Pauline Read Status' as info,
    ucr.conversation_id,
    ucr.last_read_at,
    ucr.created_at as read_record_created
FROM user_conversation_reads ucr
WHERE ucr.user_id = (SELECT id FROM users WHERE username = 'paulinedumbili6');

-- Test the unread count function directly for Pauline
SELECT 
    'Pauline Unread Count Test' as info,
    get_total_unread_message_count(
        (SELECT auth_user_id FROM users WHERE username = 'paulinedumbili6')
    ) as unread_count;
