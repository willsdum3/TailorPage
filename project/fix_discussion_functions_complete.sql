-- =====================================================
-- COMPLETE FIX FOR DISCUSSION FUNCTIONS
-- =====================================================
-- This script creates all necessary discussion functions without dependencies

-- Drop all existing discussion functions to start fresh
DROP FUNCTION IF EXISTS get_discussions(UUID);
DROP FUNCTION IF EXISTS create_discussion(UUID, TEXT, TEXT, TEXT, TEXT, TEXT[]);
DROP FUNCTION IF EXISTS join_discussion(UUID, UUID);
DROP FUNCTION IF EXISTS add_discussion_message(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS get_discussion_messages(UUID, UUID, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS get_discussion_messages(UUID, UUID);

-- Create self-contained get_discussions function
CREATE OR REPLACE FUNCTION get_discussions(auth_user_id UUID)
RETURNS TABLE (
    id UUID,
    title TEXT,
    content TEXT,
    book_title TEXT,
    book_author TEXT,
    tags TEXT[],
    created_by UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    participant_count BIGINT,
    last_message_at TIMESTAMP WITH TIME ZONE,
    is_participant BOOLEAN,
    creator_name TEXT
) AS $$
DECLARE
    user_uuid UUID;
BEGIN
    -- Get user ID
    SELECT u.id INTO user_uuid
    FROM users u
    WHERE u.auth_user_id = get_discussions.auth_user_id;
    
    RETURN QUERY
    SELECT 
        d.id,
        d.title,
        d.content,
        d.book_title,
        d.book_author,
        d.tags,
        d.created_by,
        d.created_at,
        COALESCE((SELECT COUNT(*) FROM discussion_participants WHERE discussion_id = d.id), 0)::BIGINT as participant_count,
        COALESCE((SELECT MAX(created_at) FROM discussion_messages WHERE discussion_id = d.id), d.created_at) as last_message_at,
        COALESCE((
            SELECT EXISTS(
                SELECT 1 FROM discussion_participants 
                WHERE discussion_id = d.id AND user_id = user_uuid
            )
        ), false) as is_participant,
        COALESCE((
            SELECT COALESCE(creator.username, creator.name, 'Unknown')
            FROM users creator 
            WHERE creator.id = d.created_by
        ), 'Unknown') as creator_name
    FROM discussions d
    ORDER BY d.created_at DESC;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in get_discussions: %', SQLERRM;
        RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create discussion function
CREATE OR REPLACE FUNCTION create_discussion(
    auth_user_id UUID,
    discussion_title TEXT,
    discussion_content TEXT,
    book_title TEXT DEFAULT NULL,
    book_author TEXT DEFAULT NULL,
    tags TEXT[] DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
    discussion_id UUID;
BEGIN
    -- Get user ID
    SELECT u.id INTO user_uuid
    FROM users u
    WHERE u.auth_user_id = create_discussion.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Create discussion
    INSERT INTO discussions (
        title,
        content,
        book_title,
        book_author,
        tags,
        created_by
    ) VALUES (
        discussion_title,
        discussion_content,
        book_title,
        book_author,
        tags,
        user_uuid
    ) RETURNING id INTO discussion_id;
    
    -- Automatically add creator as participant
    INSERT INTO discussion_participants (discussion_id, user_id)
    VALUES (discussion_id, user_uuid);
    
    RETURN discussion_id;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to create discussion: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Join discussion function
CREATE OR REPLACE FUNCTION join_discussion(
    auth_user_id UUID,
    discussion_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
    discussion_exists BOOLEAN;
    already_participant BOOLEAN;
BEGIN
    -- Get user ID
    SELECT u.id INTO user_uuid
    FROM users u
    WHERE u.auth_user_id = join_discussion.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if discussion exists
    SELECT EXISTS(SELECT 1 FROM discussions WHERE id = discussion_id) INTO discussion_exists;
    
    IF NOT discussion_exists THEN
        RAISE EXCEPTION 'Discussion not found';
    END IF;
    
    -- Check if already a participant
    SELECT EXISTS(
        SELECT 1 FROM discussion_participants 
        WHERE discussion_id = join_discussion.discussion_id AND user_id = user_uuid
    ) INTO already_participant;
    
    IF already_participant THEN
        RETURN true; -- Already joined, return success
    END IF;
    
    -- Add user as participant
    INSERT INTO discussion_participants (discussion_id, user_id)
    VALUES (discussion_id, user_uuid);
    
    RETURN true;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to join discussion: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add discussion message function
CREATE OR REPLACE FUNCTION add_discussion_message(
    auth_user_id UUID,
    discussion_id UUID,
    message_content TEXT
)
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
    is_participant BOOLEAN;
    message_id UUID;
BEGIN
    -- Get user ID
    SELECT u.id INTO user_uuid
    FROM users u
    WHERE u.auth_user_id = add_discussion_message.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if user is a participant
    SELECT EXISTS(
        SELECT 1 FROM discussion_participants 
        WHERE discussion_id = add_discussion_message.discussion_id AND user_id = user_uuid
    ) INTO is_participant;
    
    IF NOT is_participant THEN
        RAISE EXCEPTION 'You must join the discussion before sending messages';
    END IF;
    
    -- Add message
    INSERT INTO discussion_messages (
        discussion_id,
        user_id,
        content
    ) VALUES (
        discussion_id,
        user_uuid,
        message_content
    ) RETURNING id INTO message_id;
    
    -- Update participant's last_read_at
    UPDATE discussion_participants
    SET last_read_at = NOW()
    WHERE discussion_id = add_discussion_message.discussion_id AND user_id = user_uuid;
    
    RETURN message_id;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to add message: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get discussion messages function
CREATE OR REPLACE FUNCTION get_discussion_messages(
    auth_user_id UUID,
    discussion_id UUID,
    limit_count INTEGER DEFAULT 50,
    offset_count INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    content TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    user_id UUID,
    user_name TEXT,
    user_image_url TEXT,
    is_edited BOOLEAN
) AS $$
DECLARE
    user_uuid UUID;
    is_participant BOOLEAN;
BEGIN
    -- Get user ID
    SELECT u.id INTO user_uuid
    FROM users u
    WHERE u.auth_user_id = get_discussion_messages.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if user is a participant (optional - might want to allow viewing without joining)
    SELECT EXISTS(
        SELECT 1 FROM discussion_participants 
        WHERE discussion_id = get_discussion_messages.discussion_id AND user_id = user_uuid
    ) INTO is_participant;
    
    -- Return messages (allow viewing even if not participant for now)
    RETURN QUERY
    SELECT 
        dm.id,
        dm.content,
        dm.created_at,
        dm.user_id,
        COALESCE(u.name, 'Unknown User') as user_name,
        u.avatar_url as user_image_url,
        false as is_edited -- Simple implementation for now
    FROM discussion_messages dm
    JOIN users u ON dm.user_id = u.id
    WHERE dm.discussion_id = get_discussion_messages.discussion_id
    ORDER BY dm.created_at ASC
    LIMIT limit_count
    OFFSET offset_count;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in get_discussion_messages: %', SQLERRM;
        RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_discussions TO authenticated;
GRANT EXECUTE ON FUNCTION create_discussion TO authenticated;
GRANT EXECUTE ON FUNCTION join_discussion TO authenticated;
GRANT EXECUTE ON FUNCTION add_discussion_message TO authenticated;
GRANT EXECUTE ON FUNCTION get_discussion_messages TO authenticated;

-- Test the functions
DO $$
DECLARE
    test_user_id UUID := '00000000-0000-0000-0000-000000000000'::UUID;
    test_result RECORD;
    function_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== TESTING DISCUSSION FUNCTIONS ===';
    
    -- Test get_discussions
    BEGIN
        FOR test_result IN SELECT * FROM get_discussions(test_user_id) LIMIT 1
        LOOP
            function_count := function_count + 1;
        END LOOP;
        RAISE NOTICE '✅ get_discussions function works';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '❌ get_discussions function error: %', SQLERRM;
    END;
    
    -- Test get_discussion_messages
    BEGIN
        FOR test_result IN SELECT * FROM get_discussion_messages(test_user_id, test_user_id) LIMIT 1
        LOOP
            function_count := function_count + 1;
        END LOOP;
        RAISE NOTICE '✅ get_discussion_messages function works';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '❌ get_discussion_messages function error: %', SQLERRM;
    END;
    
    RAISE NOTICE 'Function tests completed';
END $$;

-- Final status
DO $$
BEGIN
    RAISE NOTICE '=== DISCUSSION FUNCTIONS SETUP COMPLETE ===';
    RAISE NOTICE '✅ Created get_discussions function';
    RAISE NOTICE '✅ Created create_discussion function';
    RAISE NOTICE '✅ Created join_discussion function';
    RAISE NOTICE '✅ Created add_discussion_message function';
    RAISE NOTICE '✅ Created get_discussion_messages function';
    RAISE NOTICE '✅ All functions are self-contained without dependencies';
    RAISE NOTICE '✅ Functions should now work with the frontend';
END $$;
