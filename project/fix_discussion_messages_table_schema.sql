-- =====================================================
-- FIX DISCUSSION MESSAGES TABLE SCHEMA
-- =====================================================
-- Add missing columns and fix function to match actual table structure

-- First, check current table structure
SELECT 
    'CURRENT DISCUSSION_MESSAGES SCHEMA' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'discussion_messages' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check if is_edited column exists, if not add it
DO $$
BEGIN
    -- Add is_edited column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'discussion_messages' 
        AND column_name = 'is_edited'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE discussion_messages ADD COLUMN is_edited BOOLEAN DEFAULT false;
        RAISE NOTICE '✅ Added is_edited column to discussion_messages table';
    ELSE
        RAISE NOTICE '✅ is_edited column already exists';
    END IF;
    
    -- Add updated_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'discussion_messages' 
        AND column_name = 'updated_at'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE discussion_messages ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✅ Added updated_at column to discussion_messages table';
    ELSE
        RAISE NOTICE '✅ updated_at column already exists';
    END IF;
END $$;

-- Now recreate the get_discussion_messages function with correct column references
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
    
    -- Build JSON array of messages with correct column references
    SELECT json_agg(
        json_build_object(
            'id', dm.id::TEXT,
            'content', dm.content,
            'createdAt', dm.created_at::TEXT,
            'userId', dm.user_id::TEXT,
            'userName', COALESCE(u.name, u.username, 'Unknown'),
            'userImageUrl', NULL,
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

-- Test the fixed function
DO $$
DECLARE
    test_auth_id UUID := 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID;
    test_discussion_id UUID;
    test_result JSON;
    message_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== TESTING FIXED FUNCTION ===';
    
    -- Get discussion ID
    SELECT id INTO test_discussion_id FROM discussions ORDER BY created_at DESC LIMIT 1;
    
    IF test_discussion_id IS NULL THEN
        RAISE NOTICE '❌ No discussions found for testing';
        RETURN;
    END IF;
    
    -- Ensure user is participant
    INSERT INTO discussion_participants (discussion_id, user_id, joined_at)
    SELECT test_discussion_id, u.id, NOW()
    FROM users u WHERE u.auth_user_id = test_auth_id
    ON CONFLICT (discussion_id, user_id) DO NOTHING;
    
    -- Test function
    SELECT get_discussion_messages(test_auth_id, test_discussion_id, 10, 0) INTO test_result;
    
    IF test_result IS NOT NULL AND test_result::TEXT != '[]' THEN
        message_count := json_array_length(test_result);
        RAISE NOTICE '✅ SUCCESS: Function returned % messages', message_count;
        RAISE NOTICE 'Sample result: %', LEFT(test_result::TEXT, 200);
    ELSE
        RAISE NOTICE '❌ Function still returning empty array';
        
        -- Check if messages exist
        SELECT COUNT(*) INTO message_count FROM discussion_messages WHERE discussion_id = test_discussion_id;
        RAISE NOTICE 'Messages in database: %', message_count;
    END IF;
END $$;

-- Show final table structure
SELECT 
    'FINAL DISCUSSION_MESSAGES SCHEMA' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'discussion_messages' 
AND table_schema = 'public'
ORDER BY ordinal_position;
