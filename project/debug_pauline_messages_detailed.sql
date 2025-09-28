-- Debug Pauline's messages in detail to find the unread message
-- This will show exactly which message is being counted as unread

WITH pauline_user AS (
    SELECT id as user_id, auth_user_id 
    FROM users 
    WHERE username = 'paulinedumbili6'
),
pauline_conversations AS (
    SELECT DISTINCT
        md5(LEAST(fr.requester_id, fr.target_id)::text || GREATEST(fr.requester_id, fr.target_id)::text)::uuid as conversation_id,
        fr.requester_id,
        fr.target_id,
        u1.name as user1_name,
        u2.name as user2_name
    FROM friend_requests fr
    JOIN users u1 ON fr.requester_id = u1.id
    JOIN users u2 ON fr.target_id = u2.id
    WHERE (fr.requester_id = (SELECT user_id FROM pauline_user)
       OR fr.target_id = (SELECT user_id FROM pauline_user))
    AND fr.status = 'accepted'
)
SELECT 
    'All Messages in Pauline Conversations' as info,
    fm.id as message_id,
    fm.conversation_id,
    fm.sender_id,
    fm.content,
    fm.created_at,
    u.name as sender_name,
    pc.user1_name,
    pc.user2_name,
    CASE 
        WHEN fm.sender_id = (SELECT user_id FROM pauline_user) THEN 'Pauline sent this'
        ELSE 'Someone else sent this'
    END as sender_type
FROM friend_messages fm
JOIN pauline_conversations pc ON fm.conversation_id = pc.conversation_id
JOIN users u ON fm.sender_id = u.id
ORDER BY fm.created_at DESC;

-- Now check which messages are being counted as unread by the function
WITH pauline_user AS (
    SELECT id as user_id, auth_user_id 
    FROM users 
    WHERE username = 'paulinedumbili6'
),
pauline_conversations AS (
    SELECT DISTINCT
        md5(LEAST(fr.requester_id, fr.target_id)::text || GREATEST(fr.requester_id, fr.target_id)::text)::uuid as conversation_id
    FROM friend_requests fr
    WHERE (fr.requester_id = (SELECT user_id FROM pauline_user)
       OR fr.target_id = (SELECT user_id FROM pauline_user))
    AND fr.status = 'accepted'
)
SELECT 
    'Messages Counted as Unread' as info,
    fm.id as message_id,
    fm.conversation_id,
    fm.sender_id,
    fm.content,
    fm.created_at,
    u.name as sender_name,
    ucr.last_read_at,
    CASE 
        WHEN ucr.last_read_at IS NULL THEN 'Unread - Never read conversation'
        WHEN fm.created_at > ucr.last_read_at THEN 'Unread - Message newer than last read'
        ELSE 'Should be read'
    END as unread_reason
FROM friend_messages fm
JOIN pauline_conversations pc ON fm.conversation_id = pc.conversation_id
JOIN users u ON fm.sender_id = u.id
LEFT JOIN user_conversation_reads ucr ON (
    ucr.conversation_id = fm.conversation_id 
    AND ucr.user_id = (SELECT user_id FROM pauline_user)
)
WHERE fm.sender_id != (SELECT user_id FROM pauline_user)  -- Only messages from others
AND (
    ucr.last_read_at IS NULL  -- Never read
    OR fm.created_at > ucr.last_read_at  -- Newer than last read
)
ORDER BY fm.created_at DESC;
