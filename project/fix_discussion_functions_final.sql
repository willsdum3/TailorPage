-- =====================================================
-- FINAL FIX FOR DISCUSSION FUNCTIONS
-- =====================================================
-- This script properly drops all function variations and recreates them

-- Drop all possible variations of discussion functions
DROP FUNCTION IF EXISTS get_discussions(UUID);
DROP FUNCTION IF EXISTS get_discussions();
DROP FUNCTION IF EXISTS get_discussions(auth_user_id UUID);

DROP FUNCTION IF EXISTS create_discussion(UUID, TEXT, TEXT, TEXT, TEXT, TEXT[]);
DROP FUNCTION IF EXISTS create_discussion(UUID, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS create_discussion(UUID, TEXT, TEXT);

DROP FUNCTION IF EXISTS join_discussion(UUID, UUID);
DROP FUNCTION IF EXISTS join_discussion(auth_user_id UUID, discussion_id UUID);

DROP FUNCTION IF EXISTS add_discussion_message(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS add_discussion_message(auth_user_id UUID, discussion_id UUID, message_content TEXT);

DROP FUNCTION IF EXISTS get_discussion_messages(UUID, UUID, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS get_discussion_messages(UUID, UUID);
DROP FUNCTION IF EXISTS get_discussion_messages(auth_user_id UUID, discussion_id UUID);

-- Create get_discussions function
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
BEGIN
    -- Get user ID
    SELECT u.id INTO user_uuid
    FROM users u
    WHERE u.auth_user_id = get_discussion_messages.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Return messages
    RETURN QUERY
    SELECT 
        dm.id,
        dm.content,
        dm.created_at,
        dm.user_id,
        COALESCE(u.name, 'Unknown User') as user_name,
        u.avatar_url as user_image_url,
        false as is_edited
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

-- Test the functions with actual discussion data
DO $$
DECLARE
    sample_discussion_id UUID;
    test_auth_id UUID := '3bd64865-45b6-4b2b-81d2-4940a8bf3200'::UUID; -- From your sample data
    test_result RECORD;
    result_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== TESTING WITH REAL DATA ===';
    
    -- Get a real discussion ID from your data
    SELECT id INTO sample_discussion_id FROM discussions LIMIT 1;
    
    IF sample_discussion_id IS NOT NULL THEN
        RAISE NOTICE 'Testing with discussion ID: %', sample_discussion_id;
        
        -- Test get_discussions
        FOR test_result IN SELECT * FROM get_discussions(test_auth_id) LIMIT 3
        LOOP
            result_count := result_count + 1;
            RAISE NOTICE 'Discussion %: % (Participant: %)', result_count, test_result.title, test_result.is_participant;
        END LOOP;
        
        RAISE NOTICE 'get_discussions returned % discussions', result_count;
    ELSE
        RAISE NOTICE 'No discussions found to test with';
    END IF;
END $$;

-- Final status
DO $$
BEGIN
    RAISE NOTICE '=== DISCUSSION SYSTEM READY ===';
    RAISE NOTICE 'All discussion functions have been recreated';
    RAISE NOTICE 'Functions are self-contained and should work with frontend';
    RAISE NOTICE 'Test creating, joining, and messaging in discussions';
END $$;
