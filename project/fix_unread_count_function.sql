-- Fix the unread count function to use the correct column names
-- The user_conversation_reads table uses last_read_at (timestamp) not last_read_message_id

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
    
    -- Count unread messages across all friend conversations
    SELECT COUNT(*) INTO v_unread_count
    FROM friend_messages fm
    JOIN friend_conversations fc ON fm.conversation_id = fc.id
    LEFT JOIN user_conversation_reads ucr ON (
        ucr.user_id = v_user_id 
        AND ucr.conversation_id = fm.conversation_id
    )
    WHERE (
        fc.user1_id = v_user_id OR fc.user2_id = v_user_id
    )
    AND fm.sender_id != v_user_id  -- Only count messages from others
    AND (
        ucr.last_read_at IS NULL  -- User hasn't read any messages in this conversation
        OR fm.created_at > ucr.last_read_at  -- Message is newer than the last read timestamp
    );
    
    RETURN COALESCE(v_unread_count, 0);
END;
$$;

-- Test the fixed function
SELECT 
    'Test Fixed Unread Count Function' as test_type,
    get_total_unread_message_count('ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID) as unread_count;
