-- =====================================================
-- FIX DISCUSSION MESSAGE AVATARS
-- =====================================================
-- Update get_discussion_messages to include user avatar URLs

DROP FUNCTION IF EXISTS get_discussion_messages(UUID, UUID, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION get_discussion_messages(
    auth_user_id UUID,
    p_discussion_id UUID,
    limit_count INTEGER DEFAULT 50,
    offset_count INTEGER DEFAULT 0
)
RETURNS JSON AS $$
DECLARE
    user_uuid UUID;
    is_participant BOOLEAN;
    messages_array JSON;
    message_count INTEGER := 0;
BEGIN
    RAISE NOTICE 'get_discussion_messages called: auth_user_id=%, discussion_id=%', auth_user_id, p_discussion_id;
    
    -- Get user ID
    SELECT u.id INTO user_uuid FROM users u WHERE u.auth_user_id = get_discussion_messages.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RAISE NOTICE 'User not found for auth_user_id: %', auth_user_id;
        RETURN '[]'::JSON;
    END IF;
    
    RAISE NOTICE 'Found user: %', user_uuid;
    
    -- Check participation
    SELECT EXISTS(
        SELECT 1 FROM discussion_participants dp
        WHERE dp.discussion_id = p_discussion_id AND dp.user_id = user_uuid
    ) INTO is_participant;
    
    IF NOT is_participant THEN
        RAISE NOTICE 'User % is not a participant in discussion %', user_uuid, p_discussion_id;
        RETURN '[]'::JSON;
    END IF;
    
    RAISE NOTICE 'User is participant, fetching messages...';
    
    -- Build JSON array of messages with avatar URLs
    SELECT json_agg(
        json_build_object(
            'id', dm.id::TEXT,
            'content', dm.content,
            'createdAt', dm.created_at::TEXT,
            'userId', dm.user_id::TEXT,
            'userName', COALESCE(u.name, u.username, 'Unknown'),
            'userImageUrl', u.avatar_url,  -- Include avatar URL from users table
            'isEdited', COALESCE(dm.is_edited, false)
        )
        ORDER BY dm.created_at ASC
    ) INTO messages_array
    FROM discussion_messages dm
    JOIN users u ON dm.user_id = u.id
    WHERE dm.discussion_id = p_discussion_id
    LIMIT limit_count
    OFFSET offset_count;
    
    -- Count messages for logging
    SELECT COUNT(*) INTO message_count
    FROM discussion_messages dm
    WHERE dm.discussion_id = p_discussion_id;
    
    RAISE NOTICE 'Returning % messages as JSON array', COALESCE(json_array_length(messages_array), 0);
    RAISE NOTICE 'Total messages in discussion: %', message_count;
    
    RETURN COALESCE(messages_array, '[]'::JSON);
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in get_discussion_messages: %', SQLERRM;
        RETURN '[]'::JSON;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_discussion_messages TO authenticated;

-- Test the updated function
DO $$
DECLARE
    test_auth_id UUID := 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID;
    test_discussion_id UUID;
    test_result JSON;
    sample_message JSON;
BEGIN
    RAISE NOTICE '=== TESTING AVATAR FUNCTION ===';
    
    -- Get discussion ID
    SELECT id INTO test_discussion_id FROM discussions ORDER BY created_at DESC LIMIT 1;
    
    -- Test function
    SELECT get_discussion_messages(test_auth_id, test_discussion_id, 10, 0) INTO test_result;
    
    IF test_result IS NOT NULL AND test_result::TEXT != '[]' THEN
        -- Extract first message to show avatar data
        SELECT test_result->0 INTO sample_message;
        RAISE NOTICE '✅ SUCCESS: Function returned messages with avatars';
        RAISE NOTICE 'Sample message: %', sample_message;
        RAISE NOTICE 'Avatar URL: %', sample_message->>'userImageUrl';
    ELSE
        RAISE NOTICE '❌ Function returned empty array';
    END IF;
END $$;
