-- Check if there's a mismatch between friend_conversations and friend_requests tables
-- The unread count function uses friend_conversations but conversations might be stored differently

-- Check what's in friend_conversations table
SELECT 
    'friend_conversations table' as info,
    COUNT(*) as total_conversations
FROM friend_conversations;

-- Check what's in friend_requests table (accepted)
SELECT 
    'friend_requests table (accepted)' as info,
    COUNT(*) as total_accepted_friendships
FROM friend_requests 
WHERE status = 'accepted';

-- Check if Pauline has entries in friend_conversations
SELECT 
    'Pauline in friend_conversations' as info,
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

-- Check if Pauline has entries in friend_requests (accepted)
SELECT 
    'Pauline in friend_requests (accepted)' as info,
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

-- Check if there are messages that don't have corresponding friend_conversations entries
SELECT 
    'Messages without friend_conversations entries' as info,
    fm.conversation_id,
    COUNT(*) as message_count
FROM friend_messages fm
LEFT JOIN friend_conversations fc ON fm.conversation_id = fc.id
WHERE fc.id IS NULL
GROUP BY fm.conversation_id;
