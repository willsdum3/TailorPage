-- COMPREHENSIVE RESTORE: All book club functions except join requests
-- This restores messaging, polls, editing, and invitations without touching join requests

-- 1. RESTORE BOOK CLUB MESSAGING FUNCTIONS
DROP FUNCTION IF EXISTS add_book_club_message(UUID, UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS get_book_club_messages(UUID, UUID, INTEGER, INTEGER) CASCADE;

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
    SELECT u.id INTO user_internal_id FROM users u WHERE u.auth_user_id::TEXT = auth_user_id::TEXT;
    IF user_internal_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'User not found'::TEXT;
        RETURN;
    END IF;
    
    SELECT EXISTS(SELECT 1 FROM book_club_members bcm WHERE bcm.club_id = club_id_param AND bcm.user_id = user_internal_id) INTO is_member;
    SELECT EXISTS(SELECT 1 FROM book_clubs bc WHERE bc.id = club_id_param AND bc.created_by = user_internal_id) INTO is_creator;
    
    IF NOT (is_member OR is_creator) THEN
        RETURN QUERY SELECT FALSE, 'You are not a member of this club'::TEXT;
        RETURN;
    END IF;
    
    INSERT INTO book_club_messages (club_id, user_id, content, message) VALUES (club_id_param, user_internal_id, message_content, message_content);
    RETURN QUERY SELECT TRUE, 'Message sent successfully'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

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
    SELECT u.id INTO user_internal_id FROM users u WHERE u.auth_user_id::TEXT = auth_user_id::TEXT;
    IF user_internal_id IS NULL THEN RAISE EXCEPTION 'User not found'; END IF;
    
    SELECT EXISTS(SELECT 1 FROM book_club_members bcm WHERE bcm.club_id = club_id_param AND bcm.user_id = user_internal_id) INTO is_member;
    SELECT EXISTS(SELECT 1 FROM book_clubs bc WHERE bc.id = club_id_param AND bc.created_by = user_internal_id) INTO is_creator;
    
    IF NOT (is_member OR is_creator) THEN RAISE EXCEPTION 'You are not a member of this club'; END IF;
    
    RETURN QUERY
    SELECT bcm.id, bcm.club_id, bcm.user_id, COALESCE(bcm.content, bcm.message)::TEXT, COALESCE(bcm.message, bcm.content)::TEXT,
           bcm.created_at, bcm.updated_at, COALESCE(u.avatar_url, '')::TEXT, COALESCE(u.name, 'Unknown User')::TEXT, COALESCE(u.username, 'unknown')::TEXT
    FROM book_club_messages bcm
    JOIN users u ON bcm.user_id = u.id
    WHERE bcm.club_id = club_id_param
    ORDER BY bcm.created_at DESC LIMIT _limit OFFSET _offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. RESTORE POLL FUNCTIONS
DROP FUNCTION IF EXISTS create_book_selection_poll(UUID, UUID, TEXT, TEXT, JSONB) CASCADE;
DROP FUNCTION IF EXISTS get_club_polls(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS vote_on_poll(UUID, UUID, UUID) CASCADE;

CREATE OR REPLACE FUNCTION create_book_selection_poll(
    auth_user_id UUID,
    club_id_param UUID,
    title_param TEXT,
    description_param TEXT,
    options_param JSONB
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    poll_id UUID
) AS $$
DECLARE
    user_internal_id UUID;
    is_admin BOOLEAN;
    is_creator BOOLEAN;
    new_poll_id UUID;
BEGIN
    SELECT u.id INTO user_internal_id FROM users u WHERE u.auth_user_id::TEXT = auth_user_id::TEXT;
    IF user_internal_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'User not found'::TEXT, NULL::UUID;
        RETURN;
    END IF;
    
    SELECT EXISTS(SELECT 1 FROM book_club_members bcm WHERE bcm.club_id = club_id_param AND bcm.user_id = user_internal_id AND bcm.role IN ('admin', 'owner')) INTO is_admin;
    SELECT EXISTS(SELECT 1 FROM book_clubs bc WHERE bc.id = club_id_param AND bc.created_by = user_internal_id) INTO is_creator;
    
    IF NOT (is_admin OR is_creator) THEN
        RETURN QUERY SELECT FALSE, 'Only admins can create polls'::TEXT, NULL::UUID;
        RETURN;
    END IF;
    
    new_poll_id := gen_random_uuid();
    INSERT INTO book_selection_polls (id, club_id, title, description, created_by, created_at, closes_at)
    VALUES (new_poll_id, club_id_param, title_param, description_param, user_internal_id, NOW(), NOW() + INTERVAL '7 days');
    
    -- Insert poll options
    INSERT INTO poll_options (poll_id, option_text, option_order)
    SELECT new_poll_id, value::TEXT, (key::INTEGER + 1)
    FROM jsonb_each_text(options_param);
    
    RETURN QUERY SELECT TRUE, 'Poll created successfully'::TEXT, new_poll_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_club_polls(
    auth_user_id UUID,
    club_id_param UUID
)
RETURNS JSONB AS $$
DECLARE
    user_internal_id UUID;
    is_member BOOLEAN;
    is_creator BOOLEAN;
    result JSONB;
BEGIN
    SELECT u.id INTO user_internal_id FROM users u WHERE u.auth_user_id::TEXT = auth_user_id::TEXT;
    IF user_internal_id IS NULL THEN RAISE EXCEPTION 'User not found'; END IF;
    
    SELECT EXISTS(SELECT 1 FROM book_club_members bcm WHERE bcm.club_id = club_id_param AND bcm.user_id = user_internal_id) INTO is_member;
    SELECT EXISTS(SELECT 1 FROM book_clubs bc WHERE bc.id = club_id_param AND bc.created_by = user_internal_id) INTO is_creator;
    
    IF NOT (is_member OR is_creator) THEN RAISE EXCEPTION 'You are not a member of this club'; END IF;
    
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', p.id,
            'title', p.title,
            'description', p.description,
            'options', COALESCE(options_data.options, '[]'::jsonb),
            'total_votes', COALESCE(vote_data.total_votes, 0),
            'created_at', p.created_at,
            'closes_at', p.closes_at,
            'created_by_name', COALESCE(u.name, 'Unknown'),
            'user_vote', COALESCE(user_vote_data.user_vote, NULL),
            'vote_counts', COALESCE(vote_data.vote_counts, '{}'::jsonb)
        )
    ) INTO result
    FROM book_selection_polls p
    JOIN users u ON p.created_by = u.id
    LEFT JOIN (
        SELECT po.poll_id, jsonb_agg(jsonb_build_object('id', po.id, 'text', po.option_text, 'order', po.option_order)) as options
        FROM poll_options po
        GROUP BY po.poll_id
    ) options_data ON p.id = options_data.poll_id
    LEFT JOIN (
        SELECT pv.poll_id, COUNT(*) as total_votes,
               jsonb_object_agg(po.option_text, vote_counts.count) as vote_counts
        FROM poll_votes pv
        JOIN poll_options po ON pv.option_id = po.id
        JOIN (
            SELECT option_id, COUNT(*) as count
            FROM poll_votes
            GROUP BY option_id
        ) vote_counts ON pv.option_id = vote_counts.option_id
        GROUP BY pv.poll_id
    ) vote_data ON p.id = vote_data.poll_id
    LEFT JOIN (
        SELECT poll_id, option_id as user_vote
        FROM poll_votes
        WHERE user_id = user_internal_id
    ) user_vote_data ON p.id = user_vote_data.poll_id
    WHERE p.club_id = club_id_param AND p.closes_at > NOW()
    ORDER BY p.created_at DESC;
    
    RETURN COALESCE(result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION vote_on_poll(
    auth_user_id UUID,
    poll_id_param UUID,
    option_id_param UUID
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    user_internal_id UUID;
    is_member BOOLEAN;
    is_creator BOOLEAN;
    poll_club_id UUID;
BEGIN
    SELECT u.id INTO user_internal_id FROM users u WHERE u.auth_user_id::TEXT = auth_user_id::TEXT;
    IF user_internal_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'User not found'::TEXT;
        RETURN;
    END IF;
    
    SELECT p.club_id INTO poll_club_id FROM book_selection_polls p WHERE p.id = poll_id_param;
    IF poll_club_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Poll not found'::TEXT;
        RETURN;
    END IF;
    
    SELECT EXISTS(SELECT 1 FROM book_club_members bcm WHERE bcm.club_id = poll_club_id AND bcm.user_id = user_internal_id) INTO is_member;
    SELECT EXISTS(SELECT 1 FROM book_clubs bc WHERE bc.id = poll_club_id AND bc.created_by = user_internal_id) INTO is_creator;
    
    IF NOT (is_member OR is_creator) THEN
        RETURN QUERY SELECT FALSE, 'You are not a member of this club'::TEXT;
        RETURN;
    END IF;
    
    INSERT INTO poll_votes (poll_id, user_id, option_id, voted_at)
    VALUES (poll_id_param, user_internal_id, option_id_param, NOW())
    ON CONFLICT (poll_id, user_id) DO UPDATE SET option_id = option_id_param, voted_at = NOW();
    
    RETURN QUERY SELECT TRUE, 'Vote recorded successfully'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. RESTORE EDIT CLUB DETAILS FUNCTION
DROP FUNCTION IF EXISTS update_book_club_details(UUID, UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) CASCADE;

CREATE OR REPLACE FUNCTION update_book_club_details(
    auth_user_id UUID,
    club_id_param UUID,
    name_param TEXT DEFAULT NULL,
    description_param TEXT DEFAULT NULL,
    current_book_title_param TEXT DEFAULT NULL,
    current_book_author_param TEXT DEFAULT NULL,
    meeting_time_param TEXT DEFAULT NULL,
    next_meeting_date_param TEXT DEFAULT NULL
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    user_internal_id UUID;
    is_admin BOOLEAN;
    is_creator BOOLEAN;
BEGIN
    SELECT u.id INTO user_internal_id FROM users u WHERE u.auth_user_id::TEXT = auth_user_id::TEXT;
    IF user_internal_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'User not found'::TEXT;
        RETURN;
    END IF;
    
    SELECT EXISTS(SELECT 1 FROM book_club_members bcm WHERE bcm.club_id = club_id_param AND bcm.user_id = user_internal_id AND bcm.role IN ('admin', 'owner')) INTO is_admin;
    SELECT EXISTS(SELECT 1 FROM book_clubs bc WHERE bc.id = club_id_param AND bc.created_by = user_internal_id) INTO is_creator;
    
    IF NOT (is_admin OR is_creator) THEN
        RETURN QUERY SELECT FALSE, 'Only admins can update club details'::TEXT;
        RETURN;
    END IF;
    
    UPDATE book_clubs SET
        name = COALESCE(name_param, name),
        description = COALESCE(description_param, description),
        current_book_title = COALESCE(current_book_title_param, current_book_title),
        current_book_author = COALESCE(current_book_author_param, current_book_author),
        meeting_time = COALESCE(meeting_time_param, meeting_time),
        next_meeting_date = COALESCE(next_meeting_date_param::DATE, next_meeting_date),
        updated_at = NOW()
    WHERE id = club_id_param;
    
    RETURN QUERY SELECT TRUE, 'Club details updated successfully'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. RESTORE CLUB VISIBILITY FUNCTION
DROP FUNCTION IF EXISTS toggle_book_club_visibility(UUID, UUID) CASCADE;

CREATE OR REPLACE FUNCTION toggle_book_club_visibility(
    auth_user_id UUID,
    club_id_param UUID
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    is_public BOOLEAN
) AS $$
DECLARE
    user_internal_id UUID;
    is_admin BOOLEAN;
    is_creator BOOLEAN;
    current_visibility BOOLEAN;
BEGIN
    SELECT u.id INTO user_internal_id FROM users u WHERE u.auth_user_id::TEXT = auth_user_id::TEXT;
    IF user_internal_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'User not found'::TEXT, FALSE;
        RETURN;
    END IF;
    
    SELECT EXISTS(SELECT 1 FROM book_club_members bcm WHERE bcm.club_id = club_id_param AND bcm.user_id = user_internal_id AND bcm.role IN ('admin', 'owner')) INTO is_admin;
    SELECT EXISTS(SELECT 1 FROM book_clubs bc WHERE bc.id = club_id_param AND bc.created_by = user_internal_id) INTO is_creator;
    
    IF NOT (is_admin OR is_creator) THEN
        RETURN QUERY SELECT FALSE, 'Only admins can change club visibility'::TEXT, FALSE;
        RETURN;
    END IF;
    
    SELECT bc.is_public INTO current_visibility FROM book_clubs bc WHERE bc.id = club_id_param;
    
    UPDATE book_clubs SET is_public = NOT current_visibility, updated_at = NOW() WHERE id = club_id_param;
    
    RETURN QUERY SELECT TRUE, 'Club visibility updated successfully'::TEXT, NOT current_visibility;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test all functions
DO $$
DECLARE
    test_user_id UUID;
    test_club_id UUID;
BEGIN
    SELECT u.auth_user_id INTO test_user_id FROM users u LIMIT 1;
    SELECT bc.id INTO test_club_id FROM book_clubs bc LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_club_id IS NOT NULL THEN
        RAISE NOTICE 'All book club functions restored successfully';
        RAISE NOTICE 'User: %, Club: %', test_user_id, test_club_id;
    ELSE
        RAISE NOTICE 'No test data available';
    END IF;
END $$;

-- Show restored functions
SELECT 
    'Book Club Functions Restored' as status,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name IN (
    'add_book_club_message', 'get_book_club_messages',
    'create_book_selection_poll', 'get_club_polls', 'vote_on_poll',
    'update_book_club_details', 'toggle_book_club_visibility'
) 
AND routine_schema = 'public'
ORDER BY routine_name;
