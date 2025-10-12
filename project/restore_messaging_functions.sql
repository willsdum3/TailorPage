-- URGENT: Restore messaging functions that were affected
-- This script recreates the essential messaging functions

-- Restore book club messaging functions
DROP FUNCTION IF EXISTS add_book_club_message(UUID, UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS get_book_club_messages(UUID, UUID, INTEGER, INTEGER) CASCADE;

-- Create add_book_club_message function
CREATE OR REPLACE FUNCTION add_book_club_message(
    auth_user_id UUID,
    club_id_param UUID,
    message_content TEXT
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    user_internal_id UUID;
    is_member BOOLEAN;
    is_creator BOOLEAN;
BEGIN
    -- Get user's internal ID
    SELECT u.id INTO user_internal_id 
    FROM users u
    WHERE u.auth_user_id::TEXT = auth_user_id::TEXT;
    
    IF user_internal_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'User not found'::TEXT;
        RETURN;
    END IF;
    
    -- Check if user is member or creator
    SELECT EXISTS(
        SELECT 1 FROM book_club_members bcm
        WHERE bcm.club_id = club_id_param 
        AND bcm.user_id = user_internal_id
    ) INTO is_member;
    
    SELECT EXISTS(
        SELECT 1 FROM book_clubs bc
        WHERE bc.id = club_id_param AND bc.created_by = user_internal_id
    ) INTO is_creator;
    
    IF NOT (is_member OR is_creator) THEN
        RETURN QUERY SELECT FALSE, 'You are not a member of this club'::TEXT;
        RETURN;
    END IF;
    
    -- Insert message
    INSERT INTO book_club_messages (club_id, user_id, content, message)
    VALUES (club_id_param, user_internal_id, message_content, message_content);
    
    RETURN QUERY SELECT TRUE, 'Message sent successfully'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create get_book_club_messages function
CREATE OR REPLACE FUNCTION get_book_club_messages(
    auth_user_id UUID,
    club_id_param UUID,
    _limit INTEGER DEFAULT 50,
    _offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    club_id UUID,
    user_id UUID,
    content TEXT,
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    avatar_url TEXT,
    name TEXT,
    username TEXT
) AS $$
DECLARE
    user_internal_id UUID;
    is_member BOOLEAN;
    is_creator BOOLEAN;
BEGIN
    -- Get user's internal ID
    SELECT u.id INTO user_internal_id 
    FROM users u
    WHERE u.auth_user_id::TEXT = auth_user_id::TEXT;
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if user is member or creator
    SELECT EXISTS(
        SELECT 1 FROM book_club_members bcm
        WHERE bcm.club_id = club_id_param 
        AND bcm.user_id = user_internal_id
    ) INTO is_member;
    
    SELECT EXISTS(
        SELECT 1 FROM book_clubs bc
        WHERE bc.id = club_id_param AND bc.created_by = user_internal_id
    ) INTO is_creator;
    
    IF NOT (is_member OR is_creator) THEN
        RAISE EXCEPTION 'You are not a member of this club';
    END IF;
    
    -- Return messages
    RETURN QUERY
    SELECT 
        bcm.id,
        bcm.club_id,
        bcm.user_id,
        COALESCE(bcm.content, bcm.message)::TEXT,
        COALESCE(bcm.message, bcm.content)::TEXT,
        bcm.created_at,
        bcm.updated_at,
        COALESCE(u.avatar_url, '')::TEXT,
        COALESCE(u.name, 'Unknown User')::TEXT,
        COALESCE(u.username, 'unknown')::TEXT
    FROM book_club_messages bcm
    JOIN users u ON bcm.user_id = u.id
    WHERE bcm.club_id = club_id_param
    ORDER BY bcm.created_at DESC
    LIMIT _limit OFFSET _offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Restore discussion messaging functions
DROP FUNCTION IF EXISTS add_discussion_message(UUID, UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS get_discussion_messages(UUID, UUID, INTEGER, INTEGER) CASCADE;

-- Create add_discussion_message function
CREATE OR REPLACE FUNCTION add_discussion_message(
    auth_user_id UUID,
    discussion_id_param UUID,
    message_content TEXT
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    user_internal_id UUID;
    is_participant BOOLEAN;
    is_creator BOOLEAN;
BEGIN
    -- Get user's internal ID
    SELECT u.id INTO user_internal_id 
    FROM users u
    WHERE u.auth_user_id::TEXT = auth_user_id::TEXT;
    
    IF user_internal_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'User not found'::TEXT;
        RETURN;
    END IF;
    
    -- Check if user is participant or creator
    SELECT EXISTS(
        SELECT 1 FROM discussion_members dm
        WHERE dm.discussion_id = discussion_id_param 
        AND dm.user_id = user_internal_id
    ) INTO is_participant;
    
    SELECT EXISTS(
        SELECT 1 FROM discussions d
        WHERE d.id = discussion_id_param AND d.created_by = user_internal_id
    ) INTO is_creator;
    
    IF NOT (is_participant OR is_creator) THEN
        -- Auto-add user if they're the creator
        IF is_creator THEN
            INSERT INTO discussion_members (discussion_id, user_id, joined_at)
            VALUES (discussion_id_param, user_internal_id, NOW())
            ON CONFLICT (discussion_id, user_id) DO NOTHING;
        ELSE
            RETURN QUERY SELECT FALSE, 'You are not a member of this discussion'::TEXT;
            RETURN;
        END IF;
    END IF;
    
    -- Insert message
    INSERT INTO discussion_messages (discussion_id, user_id, content, message)
    VALUES (discussion_id_param, user_internal_id, message_content, message_content);
    
    RETURN QUERY SELECT TRUE, 'Message sent successfully'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create get_discussion_messages function
CREATE OR REPLACE FUNCTION get_discussion_messages(
    auth_user_id UUID,
    discussion_id_param UUID,
    limit_param INTEGER DEFAULT 50,
    offset_param INTEGER DEFAULT 0
)
RETURNS JSON AS $$
DECLARE
    user_internal_id UUID;
    is_participant BOOLEAN;
    is_creator BOOLEAN;
    result JSON;
BEGIN
    -- Get user's internal ID
    SELECT u.id INTO user_internal_id 
    FROM users u
    WHERE u.auth_user_id::TEXT = auth_user_id::TEXT;
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if user is participant or creator
    SELECT EXISTS(
        SELECT 1 FROM discussion_members dm
        WHERE dm.discussion_id = discussion_id_param 
        AND dm.user_id = user_internal_id
    ) INTO is_participant;
    
    SELECT EXISTS(
        SELECT 1 FROM discussions d
        WHERE d.id = discussion_id_param AND d.created_by = user_internal_id
    ) INTO is_creator;
    
    IF NOT (is_participant OR is_creator) THEN
        -- Auto-add user if they're the creator
        IF is_creator THEN
            INSERT INTO discussion_members (discussion_id, user_id, joined_at)
            VALUES (discussion_id_param, user_internal_id, NOW())
            ON CONFLICT (discussion_id, user_id) DO NOTHING;
        ELSE
            RAISE EXCEPTION 'You are not a member of this discussion';
        END IF;
    END IF;
    
    -- Return messages as JSON
    SELECT json_agg(
        json_build_object(
            'id', dm.id,
            'discussionId', dm.discussion_id,
            'userId', dm.user_id,
            'content', COALESCE(dm.content, dm.message),
            'message', COALESCE(dm.message, dm.content),
            'createdAt', dm.created_at,
            'updatedAt', dm.updated_at,
            'userImageUrl', COALESCE(u.avatar_url, ''),
            'userName', COALESCE(u.name, 'Unknown User'),
            'userUsername', COALESCE(u.username, 'unknown')
        )
    ) INTO result
    FROM discussion_messages dm
    JOIN users u ON dm.user_id = u.id
    WHERE dm.discussion_id = discussion_id_param
    ORDER BY dm.created_at DESC
    LIMIT limit_param OFFSET offset_param;
    
    RETURN COALESCE(result, '[]'::JSON);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test messaging functions
DO $$
DECLARE
    test_user_id UUID;
    test_club_id UUID;
    test_discussion_id UUID;
BEGIN
    -- Get test data
    SELECT u.auth_user_id INTO test_user_id FROM users u LIMIT 1;
    SELECT bc.id INTO test_club_id FROM book_clubs bc LIMIT 1;
    SELECT d.id INTO test_discussion_id FROM discussions d LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_club_id IS NOT NULL THEN
        RAISE NOTICE 'Messaging functions restored successfully';
        RAISE NOTICE 'User: %, Club: %', test_user_id, test_club_id;
    ELSE
        RAISE NOTICE 'No test data available';
    END IF;
END $$;

-- Show restored functions
SELECT 
    'Messaging Functions Restored' as status,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name IN ('add_book_club_message', 'get_book_club_messages', 'add_discussion_message', 'get_discussion_messages') 
AND routine_schema = 'public'
ORDER BY routine_name;
