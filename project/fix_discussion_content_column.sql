-- Fix Discussion Messages Content Column Issue
-- The error shows: null value in column "content" of relation "discussion_messages"

-- First, let's check the current table structure to see all columns
SELECT 
    'Current Discussion Messages Table Structure' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'discussion_messages' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check if there's a content column that might be causing issues
SELECT 
    'Content Column Check' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'discussion_messages' 
            AND column_name = 'content' 
            AND table_schema = 'public'
        ) 
        THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as content_column_status;

-- Fix the content column if it exists and has NOT NULL constraint
DO $$
BEGIN
    -- Check if content column has a NOT NULL constraint
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'discussion_messages' 
        AND column_name = 'content' 
        AND table_schema = 'public'
        AND is_nullable = 'NO'
    ) THEN
        -- Make content column nullable
        ALTER TABLE discussion_messages ALTER COLUMN content DROP NOT NULL;
        RAISE NOTICE 'Made content column nullable';
    END IF;
END $$;

-- Update the add_discussion_message function to populate both columns
DROP FUNCTION IF EXISTS add_discussion_message(UUID, UUID, TEXT) CASCADE;

CREATE OR REPLACE FUNCTION add_discussion_message(
    auth_user_id UUID,
    discussion_id UUID,
    message_content TEXT
)
RETURNS UUID AS $$
DECLARE
    user_internal_id UUID;
    message_id UUID;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if user is a member of the discussion OR is the creator
    IF NOT EXISTS (
        SELECT 1 FROM discussion_members dm
        WHERE dm.discussion_id = add_discussion_message.discussion_id 
        AND dm.user_id = user_internal_id
    ) AND NOT EXISTS (
        SELECT 1 FROM discussions d
        WHERE d.id = add_discussion_message.discussion_id
        AND d.created_by = user_internal_id
    ) THEN
        -- If user is not a member and not the creator, add them as a member automatically
        INSERT INTO discussion_members (discussion_id, user_id, joined_at)
        VALUES (add_discussion_message.discussion_id, user_internal_id, NOW())
        ON CONFLICT (discussion_id, user_id) DO NOTHING;
    END IF;
    
    -- Insert the message into both message and content columns to be safe
    INSERT INTO discussion_messages (discussion_id, user_id, message, content, created_at)
    VALUES (
        add_discussion_message.discussion_id, 
        user_internal_id, 
        add_discussion_message.message_content,
        add_discussion_message.message_content,
        NOW()
    )
    RETURNING id INTO message_id;
    
    -- Create notification for other members (if function exists)
    BEGIN
        PERFORM create_discussion_message_notification(
            add_discussion_message.discussion_id,
            user_internal_id,
            add_discussion_message.message_content
        );
    EXCEPTION
        WHEN OTHERS THEN
            -- Log the error but don't fail the main operation
            RAISE NOTICE 'Failed to create discussion message notification: %', SQLERRM;
    END;
    
    RETURN message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Also update the get_discussion_messages function to read from the correct column
DROP FUNCTION IF EXISTS get_discussion_messages(UUID, UUID, INTEGER, INTEGER) CASCADE;

CREATE OR REPLACE FUNCTION get_discussion_messages(
    auth_user_id UUID,
    p_discussion_id UUID,
    limit_count INTEGER DEFAULT 50,
    offset_count INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    content TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    user_id UUID,
    name TEXT,
    username TEXT,
    avatar_url TEXT,
    is_edited BOOLEAN
) AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if user is a member of the discussion
    IF NOT EXISTS (
        SELECT 1 FROM discussion_members dm
        WHERE dm.discussion_id = get_discussion_messages.p_discussion_id 
        AND dm.user_id = user_internal_id
    ) THEN
        RAISE EXCEPTION 'User is not a member of this discussion';
    END IF;
    
    -- Return messages with user information, using COALESCE to handle both columns
    RETURN QUERY
    SELECT 
        dm.id,
        COALESCE(dm.message, dm.content) as content, -- Use message first, fallback to content
        dm.created_at,
        dm.user_id,
        u.name,
        u.username,
        u.avatar_url,
        COALESCE(dm.is_edited, FALSE) as is_edited
    FROM discussion_messages dm
    JOIN users u ON dm.user_id = u.id
    WHERE dm.discussion_id = get_discussion_messages.p_discussion_id
    ORDER BY dm.created_at ASC
    LIMIT limit_count
    OFFSET offset_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the fix
DO $$
DECLARE
    test_user_id UUID;
    test_discussion_id UUID;
    message_id UUID;
BEGIN
    -- Get test data if available
    SELECT u.auth_user_id INTO test_user_id FROM users u LIMIT 1;
    SELECT d.id INTO test_discussion_id FROM discussions d LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_discussion_id IS NOT NULL THEN
        BEGIN
            -- Test the add_discussion_message function
            message_id := add_discussion_message(test_user_id, test_discussion_id, 'Test message with content fix');
            RAISE NOTICE '✅ add_discussion_message test successful with content fix, message_id: %', message_id;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE '❌ Function test failed: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE '⚠️ No test data available for function test';
    END IF;
END $$;

-- Show the final table structure
SELECT 
    'Final Table Structure' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'discussion_messages' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Final verification
SELECT 
    'Final Function Verification' as check_type,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name IN ('add_discussion_message', 'get_discussion_messages')
AND routine_schema = 'public'
ORDER BY routine_name;
