-- Fix the unread count function to use the correct table structure
-- The function should use friend_requests (accepted) instead of friend_conversations
-- since conversations are generated from friend_requests with MD5 hashes

CREATE OR REPLACE FUNCTION get_total_unread_message_count(
    p_auth_user_id UUID
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_unread_count INTEGER := 0;
BEGIN
    -- Get the user's internal ID
    SELECT id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RETURN 0;
    END IF;
    
    -- Count unread messages using friend_requests (accepted) to generate conversation IDs
    SELECT COUNT(*) INTO v_unread_count
    FROM friend_messages fm
    JOIN friend_requests fr ON (
        fm.conversation_id = md5(LEAST(fr.requester_id, fr.target_id)::text || GREATEST(fr.requester_id, fr.target_id)::text)::uuid
        AND fr.status = 'accepted'
        AND (fr.requester_id = v_user_id OR fr.target_id = v_user_id)
    )
    LEFT JOIN user_conversation_reads ucr ON (
        ucr.user_id = v_user_id 
        AND ucr.conversation_id = fm.conversation_id
    )
    WHERE fm.sender_id != v_user_id  -- Only count messages from others
    AND (
        ucr.last_read_at IS NULL  -- User hasn't read any messages in this conversation
        OR fm.created_at > ucr.last_read_at  -- Message is newer than the last read timestamp
    );
    
    RETURN COALESCE(v_unread_count, 0);
END;
$$;

-- Test the corrected function for Pauline
SELECT 
    'Test Corrected Unread Count Function for Pauline' as test_type,
    get_total_unread_message_count(
        (SELECT auth_user_id FROM users WHERE username = 'paulinedumbili6')
    ) as unread_count;

-- Test for all users to make sure it works correctly
SELECT 
    'Test Corrected Function for All Users' as test_type,
    u.name,
    u.username,
    get_total_unread_message_count(u.auth_user_id) as unread_count
FROM users u
WHERE u.auth_user_id IS NOT NULL
ORDER BY u.name;
