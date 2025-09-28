-- Debug the unread count logic step by step for Pauline
-- This will help identify exactly why the count is showing 1

-- Step 1: Get Pauline's internal ID
SELECT 
    'Step 1 - Pauline Internal ID' as step,
    id as internal_id,
    auth_user_id
FROM users 
WHERE username = 'paulinedumbili6';

-- Step 2: Check all messages in her conversations
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
    'Step 2 - All Messages in Pauline Conversations' as step,
    fm.id as message_id,
    fm.conversation_id,
    fm.sender_id,
    fm.created_at,
    u.name as sender_name,
    CASE 
        WHEN fm.sender_id = (SELECT user_id FROM pauline_user) THEN 'Pauline (sender)'
        ELSE 'Other user (sender)'
    END as sender_type
FROM friend_messages fm
JOIN pauline_conversations pc ON fm.conversation_id = pc.conversation_id
JOIN users u ON fm.sender_id = u.id
ORDER BY fm.created_at DESC;

-- Step 3: Check read status for each conversation
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
    'Step 3 - Read Status for Each Conversation' as step,
    pc.conversation_id,
    ucr.last_read_at,
    CASE 
        WHEN ucr.last_read_at IS NULL THEN 'Never read'
        ELSE 'Last read: ' || ucr.last_read_at::text
    END as read_status
FROM pauline_conversations pc
LEFT JOIN user_conversation_reads ucr ON (
    ucr.conversation_id = pc.conversation_id 
    AND ucr.user_id = (SELECT user_id FROM pauline_user)
);

-- Step 4: Check which messages should be counted as unread
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
    'Step 4 - Messages That Should Be Counted as Unread' as step,
    fm.id as message_id,
    fm.conversation_id,
    fm.sender_id,
    fm.created_at,
    u.name as sender_name,
    ucr.last_read_at,
    CASE 
        WHEN ucr.last_read_at IS NULL THEN 'Unread (never read conversation)'
        WHEN fm.created_at > ucr.last_read_at THEN 'Unread (newer than last read)'
        ELSE 'Read (older than last read)'
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
