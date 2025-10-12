-- STEP 1: Drop ALL versions of book club functions (including duplicates)
DO $$ 
DECLARE
    func_record RECORD;
BEGIN
    -- Drop all versions of add_book_club_message
    FOR func_record IN 
        SELECT proname, oidvectortypes(proargtypes) as argtypes
        FROM pg_proc 
        WHERE proname = 'add_book_club_message' AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
    LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS public.' || func_record.proname || '(' || func_record.argtypes || ') CASCADE';
        RAISE NOTICE 'Dropped function: % (%)', func_record.proname, func_record.argtypes;
    END LOOP;

    -- Drop all versions of get_book_club_messages
    FOR func_record IN 
        SELECT proname, oidvectortypes(proargtypes) as argtypes
        FROM pg_proc 
        WHERE proname = 'get_book_club_messages' AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
    LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS public.' || func_record.proname || '(' || func_record.argtypes || ') CASCADE';
        RAISE NOTICE 'Dropped function: % (%)', func_record.proname, func_record.argtypes;
    END LOOP;

    -- Drop all versions of update_book_club_details
    FOR func_record IN 
        SELECT proname, oidvectortypes(proargtypes) as argtypes
        FROM pg_proc 
        WHERE proname = 'update_book_club_details' AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
    LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS public.' || func_record.proname || '(' || func_record.argtypes || ') CASCADE';
        RAISE NOTICE 'Dropped function: % (%)', func_record.proname, func_record.argtypes;
    END LOOP;

    -- Drop all versions of create_book_selection_poll
    FOR func_record IN 
        SELECT proname, oidvectortypes(proargtypes) as argtypes
        FROM pg_proc 
        WHERE proname = 'create_book_selection_poll' AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
    LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS public.' || func_record.proname || '(' || func_record.argtypes || ') CASCADE';
        RAISE NOTICE 'Dropped function: % (%)', func_record.proname, func_record.argtypes;
    END LOOP;

    -- Drop all versions of get_club_polls
    FOR func_record IN 
        SELECT proname, oidvectortypes(proargtypes) as argtypes
        FROM pg_proc 
        WHERE proname = 'get_club_polls' AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
    LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS public.' || func_record.proname || '(' || func_record.argtypes || ') CASCADE';
        RAISE NOTICE 'Dropped function: % (%)', func_record.proname, func_record.argtypes;
    END LOOP;

    -- Drop all versions of vote_on_poll
    FOR func_record IN 
        SELECT proname, oidvectortypes(proargtypes) as argtypes
        FROM pg_proc 
        WHERE proname = 'vote_on_poll' AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
    LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS public.' || func_record.proname || '(' || func_record.argtypes || ') CASCADE';
        RAISE NOTICE 'Dropped function: % (%)', func_record.proname, func_record.argtypes;
    END LOOP;

    -- Drop all versions of toggle_book_club_visibility
    FOR func_record IN 
        SELECT proname, oidvectortypes(proargtypes) as argtypes
        FROM pg_proc 
        WHERE proname = 'toggle_book_club_visibility' AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
    LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS public.' || func_record.proname || '(' || func_record.argtypes || ') CASCADE';
        RAISE NOTICE 'Dropped function: % (%)', func_record.proname, func_record.argtypes;
    END LOOP;
END $$;

-- STEP 2: Create clean versions matching frontend exactly

-- 1. MESSAGING
CREATE OR REPLACE FUNCTION add_book_club_message(
    auth_user_id UUID,
    club_id_param UUID,
    content_param TEXT
)
RETURNS TABLE (success BOOLEAN, message TEXT) AS $$
DECLARE
    user_internal_id UUID;
    is_member BOOLEAN;
    is_creator BOOLEAN;
BEGIN
    SELECT u.id INTO user_internal_id FROM users u WHERE u.auth_user_id::TEXT = auth_user_id::TEXT;
    IF user_internal_id IS NULL THEN RETURN QUERY SELECT FALSE, 'User not found'::TEXT; RETURN; END IF;
    
    SELECT EXISTS(SELECT 1 FROM book_club_members bcm WHERE bcm.club_id = club_id_param AND bcm.user_id = user_internal_id) INTO is_member;
    SELECT EXISTS(SELECT 1 FROM book_clubs bc WHERE bc.id = club_id_param AND bc.created_by = user_internal_id) INTO is_creator;
    
    IF NOT (is_member OR is_creator) THEN RETURN QUERY SELECT FALSE, 'You are not a member of this club'::TEXT; RETURN; END IF;
    
    INSERT INTO book_club_messages (club_id, user_id, content, message) VALUES (club_id_param, user_internal_id, content_param, content_param);
    RETURN QUERY SELECT TRUE, 'Message sent successfully'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_book_club_messages(
    auth_user_id UUID,
    club_id_param UUID
)
RETURNS TABLE (id UUID, club_id UUID, user_id UUID, content TEXT, message TEXT, created_at TIMESTAMP WITH TIME ZONE, updated_at TIMESTAMP WITH TIME ZONE, avatar_url TEXT, name TEXT, username TEXT) AS $$
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
    ORDER BY bcm.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. EDIT CLUB
CREATE OR REPLACE FUNCTION update_book_club_details(
    auth_user_id UUID,
    club_id_param UUID,
    new_name TEXT DEFAULT NULL,
    new_description TEXT DEFAULT NULL,
    new_current_book_title TEXT DEFAULT NULL,
    new_current_book_author TEXT DEFAULT NULL,
    new_meeting_info TEXT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT) AS $$
DECLARE
    user_internal_id UUID;
    is_admin BOOLEAN;
    is_creator BOOLEAN;
BEGIN
    SELECT u.id INTO user_internal_id FROM users u WHERE u.auth_user_id::TEXT = auth_user_id::TEXT;
    IF user_internal_id IS NULL THEN RETURN QUERY SELECT FALSE, 'User not found'::TEXT; RETURN; END IF;
    
    SELECT EXISTS(SELECT 1 FROM book_club_members bcm WHERE bcm.club_id = club_id_param AND bcm.user_id = user_internal_id AND bcm.role IN ('admin', 'owner')) INTO is_admin;
    SELECT EXISTS(SELECT 1 FROM book_clubs bc WHERE bc.id = club_id_param AND bc.created_by = user_internal_id) INTO is_creator;
    
    IF NOT (is_admin OR is_creator) THEN RETURN QUERY SELECT FALSE, 'Only admins can update club details'::TEXT; RETURN; END IF;
    
    UPDATE book_clubs SET
        name = COALESCE(new_name, name),
        description = COALESCE(new_description, description),
        current_book_title = COALESCE(new_current_book_title, current_book_title),
        current_book_author = COALESCE(new_current_book_author, current_book_author),
        meeting_time = COALESCE(new_meeting_info, meeting_time),
        updated_at = NOW()
    WHERE id = club_id_param;
    
    RETURN QUERY SELECT TRUE, 'Club details updated successfully'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. POLLS
CREATE OR REPLACE FUNCTION create_book_selection_poll(
    auth_user_id UUID,
    club_id_param UUID,
    poll_title TEXT,
    poll_description TEXT,
    book_options JSONB,
    closes_at TEXT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, poll_id UUID) AS $$
DECLARE
    user_internal_id UUID;
    is_admin BOOLEAN;
    is_creator BOOLEAN;
    new_poll_id UUID;
    close_date TIMESTAMP WITH TIME ZONE;
BEGIN
    SELECT u.id INTO user_internal_id FROM users u WHERE u.auth_user_id::TEXT = auth_user_id::TEXT;
    IF user_internal_id IS NULL THEN RETURN QUERY SELECT FALSE, 'User not found'::TEXT, NULL::UUID; RETURN; END IF;
    
    SELECT EXISTS(SELECT 1 FROM book_club_members bcm WHERE bcm.club_id = club_id_param AND bcm.user_id = user_internal_id AND bcm.role IN ('admin', 'owner')) INTO is_admin;
    SELECT EXISTS(SELECT 1 FROM book_clubs bc WHERE bc.id = club_id_param AND bc.created_by = user_internal_id) INTO is_creator;
    
    IF NOT (is_admin OR is_creator) THEN RETURN QUERY SELECT FALSE, 'Only admins can create polls'::TEXT, NULL::UUID; RETURN; END IF;
    
    close_date := COALESCE(closes_at::TIMESTAMP WITH TIME ZONE, NOW() + INTERVAL '7 days');
    new_poll_id := gen_random_uuid();
    
    INSERT INTO book_selection_polls (id, club_id, title, description, created_by, created_at, closes_at)
    VALUES (new_poll_id, club_id_param, poll_title, poll_description, user_internal_id, NOW(), close_date);
    
    INSERT INTO poll_options (poll_id, option_text, option_order)
    SELECT new_poll_id, value->>'title', (ROW_NUMBER() OVER ())::INTEGER
    FROM jsonb_array_elements(book_options);
    
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
    
    SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
            'id', p.id,
            'title', p.title,
            'description', p.description,
            'options', COALESCE(options_data.options, '[]'::jsonb),
            'total_votes', COALESCE(vote_data.total_votes, 0),
            'created_at', p.created_at,
            'closes_at', p.closes_at,
            'created_by_name', COALESCE(u.name, 'Unknown'),
            'user_vote', user_vote_data.user_vote_index,
            'vote_counts', COALESCE(vote_data.vote_counts, '[]'::jsonb)
        )
    ), '[]'::jsonb) INTO result
    FROM book_selection_polls p
    JOIN users u ON p.created_by = u.id
    LEFT JOIN (
        SELECT po.poll_id, jsonb_agg(jsonb_build_object('id', po.id, 'text', po.option_text, 'order', po.option_order) ORDER BY po.option_order) as options
        FROM poll_options po GROUP BY po.poll_id
    ) options_data ON p.id = options_data.poll_id
    LEFT JOIN (
        SELECT pv.poll_id, COUNT(*)::INTEGER as total_votes,
               jsonb_agg(jsonb_build_object('option_id', pv.option_id, 'count', vote_counts.count)) as vote_counts
        FROM poll_votes pv
        JOIN (SELECT option_id, COUNT(*)::INTEGER as count FROM poll_votes GROUP BY option_id) vote_counts ON pv.option_id = vote_counts.option_id
        GROUP BY pv.poll_id
    ) vote_data ON p.id = vote_data.poll_id
    LEFT JOIN (
        SELECT pv.poll_id, po.option_order as user_vote_index
        FROM poll_votes pv
        JOIN poll_options po ON pv.option_id = po.id
        WHERE pv.user_id = user_internal_id
    ) user_vote_data ON p.id = user_vote_data.poll_id
    WHERE p.club_id = club_id_param AND p.closes_at > NOW()
    GROUP BY p.id, p.title, p.description, p.created_at, p.closes_at, u.name, options_data.options, vote_data.total_votes, vote_data.vote_counts, user_vote_data.user_vote_index
    ORDER BY p.created_at DESC;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION vote_on_poll(
    auth_user_id UUID,
    poll_id_param UUID,
    option_index INTEGER
)
RETURNS TABLE (success BOOLEAN, message TEXT) AS $$
DECLARE
    user_internal_id UUID;
    is_member BOOLEAN;
    is_creator BOOLEAN;
    poll_club_id UUID;
    target_option_id UUID;
BEGIN
    SELECT u.id INTO user_internal_id FROM users u WHERE u.auth_user_id::TEXT = auth_user_id::TEXT;
    IF user_internal_id IS NULL THEN RETURN QUERY SELECT FALSE, 'User not found'::TEXT; RETURN; END IF;
    
    SELECT p.club_id INTO poll_club_id FROM book_selection_polls p WHERE p.id = poll_id_param;
    IF poll_club_id IS NULL THEN RETURN QUERY SELECT FALSE, 'Poll not found'::TEXT; RETURN; END IF;
    
    SELECT EXISTS(SELECT 1 FROM book_club_members bcm WHERE bcm.club_id = poll_club_id AND bcm.user_id = user_internal_id) INTO is_member;
    SELECT EXISTS(SELECT 1 FROM book_clubs bc WHERE bc.id = poll_club_id AND bc.created_by = user_internal_id) INTO is_creator;
    
    IF NOT (is_member OR is_creator) THEN RETURN QUERY SELECT FALSE, 'You are not a member of this club'::TEXT; RETURN; END IF;
    
    SELECT po.id INTO target_option_id FROM poll_options po WHERE po.poll_id = poll_id_param AND po.option_order = option_index;
    IF target_option_id IS NULL THEN RETURN QUERY SELECT FALSE, 'Invalid option'::TEXT; RETURN; END IF;
    
    INSERT INTO poll_votes (poll_id, user_id, option_id, voted_at)
    VALUES (poll_id_param, user_internal_id, target_option_id, NOW())
    ON CONFLICT (poll_id, user_id) DO UPDATE SET option_id = target_option_id, voted_at = NOW();
    
    RETURN QUERY SELECT TRUE, 'Vote recorded successfully'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. VISIBILITY
CREATE OR REPLACE FUNCTION toggle_book_club_visibility(
    auth_user_id UUID,
    club_id_param UUID,
    is_public_param BOOLEAN
)
RETURNS TABLE (success BOOLEAN, message TEXT, is_public BOOLEAN) AS $$
DECLARE
    user_internal_id UUID;
    is_admin BOOLEAN;
    is_creator BOOLEAN;
BEGIN
    SELECT u.id INTO user_internal_id FROM users u WHERE u.auth_user_id::TEXT = auth_user_id::TEXT;
    IF user_internal_id IS NULL THEN RETURN QUERY SELECT FALSE, 'User not found'::TEXT, FALSE; RETURN; END IF;
    
    SELECT EXISTS(SELECT 1 FROM book_club_members bcm WHERE bcm.club_id = club_id_param AND bcm.user_id = user_internal_id AND bcm.role IN ('admin', 'owner')) INTO is_admin;
    SELECT EXISTS(SELECT 1 FROM book_clubs bc WHERE bc.id = club_id_param AND bc.created_by = user_internal_id) INTO is_creator;
    
    IF NOT (is_admin OR is_creator) THEN RETURN QUERY SELECT FALSE, 'Only admins can change club visibility'::TEXT, FALSE; RETURN; END IF;
    
    UPDATE book_clubs SET is_public = is_public_param, updated_at = NOW() WHERE id = club_id_param;
    
    RETURN QUERY SELECT TRUE, 'Club visibility updated successfully'::TEXT, is_public_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Final verification
SELECT 'CLEAN FUNCTIONS CREATED' as status, p.proname as function_name, 
       pg_get_function_arguments(p.oid) as arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname IN ('add_book_club_message', 'get_book_club_messages', 'create_book_selection_poll', 'get_club_polls', 'vote_on_poll', 'update_book_club_details', 'toggle_book_club_visibility') 
AND n.nspname = 'public'
ORDER BY p.proname;
