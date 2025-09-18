-- =====================================================
-- COMPREHENSIVE DISCUSSIONS FIX - FINAL VERSION
-- =====================================================
-- This completely rebuilds all discussion functions from scratch

-- Step 1: Nuclear option - drop everything discussion-related
DO $$
DECLARE
    func_record RECORD;
    drop_sql TEXT;
BEGIN
    RAISE NOTICE '=== NUCLEAR CLEANUP - DROPPING ALL DISCUSSION FUNCTIONS ===';
    
    -- Get all discussion functions and drop them
    FOR func_record IN 
        SELECT 
            r.routine_name,
            r.specific_name,
            string_agg(
                CASE 
                    WHEN p.data_type = 'ARRAY' THEN p.udt_name || '[]'
                    WHEN p.data_type = 'USER-DEFINED' THEN p.udt_name
                    WHEN p.data_type IS NULL THEN ''
                    ELSE p.data_type 
                END, 
                ', ' ORDER BY p.ordinal_position
            ) as param_list
        FROM information_schema.routines r
        LEFT JOIN information_schema.parameters p ON r.specific_name = p.specific_name 
            AND p.parameter_mode = 'IN'
        WHERE r.routine_schema = 'public' 
        AND r.routine_name LIKE '%discussion%'
        AND r.routine_type = 'FUNCTION'
        GROUP BY r.routine_name, r.specific_name
    LOOP
        -- Try to drop with parameters first
        IF func_record.param_list IS NOT NULL AND func_record.param_list != '' THEN
            drop_sql := 'DROP FUNCTION IF EXISTS ' || func_record.routine_name || '(' || func_record.param_list || ') CASCADE';
        ELSE
            drop_sql := 'DROP FUNCTION IF EXISTS ' || func_record.routine_name || '() CASCADE';
        END IF;
        
        RAISE NOTICE 'Executing: %', drop_sql;
        BEGIN
            EXECUTE drop_sql;
            RAISE NOTICE '✅ Dropped: %', func_record.routine_name;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE '⚠️ Could not drop: % - %', func_record.routine_name, SQLERRM;
                -- Try without parameters
                BEGIN
                    EXECUTE 'DROP FUNCTION IF EXISTS ' || func_record.routine_name || ' CASCADE';
                    RAISE NOTICE '✅ Dropped (no params): %', func_record.routine_name;
                EXCEPTION
                    WHEN OTHERS THEN
                        RAISE NOTICE '❌ Failed completely: %', func_record.routine_name;
                END;
        END;
    END LOOP;
    
    RAISE NOTICE '=== CLEANUP COMPLETE ===';
END $$;

-- Step 2: Create the working get_discussions function (based on our successful simple test)
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
    last_activity TIMESTAMP WITH TIME ZONE,
    is_participant BOOLEAN,
    creator_name TEXT
) AS $$
DECLARE
    user_uuid UUID;
    total_discussions INTEGER;
BEGIN
    RAISE NOTICE 'get_discussions called with auth_user_id: %', auth_user_id;
    
    -- First check how many discussions exist
    SELECT COUNT(*) INTO total_discussions FROM discussions;
    RAISE NOTICE 'Total discussions in database: %', total_discussions;
    
    -- Get user ID
    SELECT u.id INTO user_uuid
    FROM users u
    WHERE u.auth_user_id = get_discussions.auth_user_id;
    
    RAISE NOTICE 'User lookup result: %', COALESCE(user_uuid::TEXT, 'NULL');
    
    -- Return all discussions with calculated fields
    RETURN QUERY
    SELECT 
        d.id,
        d.title,
        d.content,
        d.book_title,
        d.book_author,
        COALESCE(d.tags, '{}') as tags,
        d.created_by,
        d.created_at,
        -- Count participants
        COALESCE((SELECT COUNT(*) FROM discussion_participants dp WHERE dp.discussion_id = d.id), 0)::BIGINT as participant_count,
        -- Last activity
        COALESCE(
            (SELECT MAX(dm.created_at) FROM discussion_messages dm WHERE dm.discussion_id = d.id),
            d.created_at
        ) as last_activity,
        -- Is participant check
        CASE 
            WHEN user_uuid IS NULL THEN false
            ELSE COALESCE(
                (SELECT EXISTS(SELECT 1 FROM discussion_participants dp WHERE dp.discussion_id = d.id AND dp.user_id = user_uuid)),
                false
            )
        END as is_participant,
        -- Creator name
        COALESCE(
            (SELECT COALESCE(creator.username, creator.name, 'Unknown')
             FROM users creator WHERE creator.id = d.created_by),
            'Unknown'
        ) as creator_name
    FROM discussions d
    ORDER BY d.created_at DESC;
    
    GET DIAGNOSTICS total_discussions = ROW_COUNT;
    RAISE NOTICE 'get_discussions returning % rows', total_discussions;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in get_discussions: %', SQLERRM;
        RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Create join_discussion function
CREATE OR REPLACE FUNCTION join_discussion(
    auth_user_id UUID,
    discussion_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
    discussion_exists BOOLEAN;
BEGIN
    RAISE NOTICE 'join_discussion called: auth_user_id=%, discussion_id=%', auth_user_id, discussion_id;
    
    -- Get user ID
    SELECT u.id INTO user_uuid
    FROM users u
    WHERE u.auth_user_id = join_discussion.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RAISE NOTICE 'User not found for auth_user_id: %', auth_user_id;
        RETURN false;
    END IF;
    
    -- Check if discussion exists
    SELECT EXISTS(SELECT 1 FROM discussions WHERE id = discussion_id) INTO discussion_exists;
    IF NOT discussion_exists THEN
        RAISE NOTICE 'Discussion not found: %', discussion_id;
        RETURN false;
    END IF;
    
    -- Add as participant
    INSERT INTO discussion_participants (discussion_id, user_id, joined_at)
    VALUES (discussion_id, user_uuid, NOW())
    ON CONFLICT (discussion_id, user_id) DO NOTHING;
    
    RAISE NOTICE 'User % joined discussion %', user_uuid, discussion_id;
    RETURN true;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in join_discussion: %', SQLERRM;
        RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 4: Create create_discussion function
CREATE OR REPLACE FUNCTION create_discussion(
    auth_user_id UUID,
    discussion_title TEXT,
    discussion_content TEXT,
    book_title TEXT DEFAULT NULL,
    book_author TEXT DEFAULT NULL,
    tags TEXT[] DEFAULT '{}'
)
RETURNS JSON AS $$
DECLARE
    user_uuid UUID;
    discussion_id UUID;
    user_name TEXT;
    user_username TEXT;
    result JSON;
BEGIN
    RAISE NOTICE 'create_discussion called: auth_user_id=%, title=%', auth_user_id, discussion_title;
    
    -- Get user info
    SELECT u.id, u.name, u.username INTO user_uuid, user_name, user_username
    FROM users u
    WHERE u.auth_user_id = create_discussion.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RAISE NOTICE 'User not found for auth_user_id: %', auth_user_id;
        RETURN json_build_object('error', 'User not found');
    END IF;
    
    -- Insert discussion
    INSERT INTO discussions (
        title,
        content,
        book_title,
        book_author,
        tags,
        created_by,
        created_at
    )
    VALUES (
        discussion_title,
        discussion_content,
        book_title,
        book_author,
        COALESCE(tags, '{}'),
        user_uuid,
        NOW()
    )
    RETURNING id INTO discussion_id;
    
    -- Auto-join creator
    INSERT INTO discussion_participants (discussion_id, user_id, joined_at)
    VALUES (discussion_id, user_uuid, NOW());
    
    -- Build result
    SELECT json_build_object(
        'id', discussion_id,
        'title', discussion_title,
        'content', discussion_content,
        'bookTitle', book_title,
        'bookAuthor', book_author,
        'tags', COALESCE(tags, '{}'),
        'createdBy', user_uuid,
        'createdAt', NOW(),
        'participantCount', 1,
        'lastActivity', NOW(),
        'isParticipant', true,
        'creatorName', COALESCE(user_username, user_name, 'Unknown')
    ) INTO result;
    
    RAISE NOTICE 'Discussion created: %', discussion_id;
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in create_discussion: %', SQLERRM;
        RETURN json_build_object('error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 5: Create messaging functions
CREATE OR REPLACE FUNCTION add_discussion_message(
    auth_user_id UUID,
    discussion_id UUID,
    message_content TEXT
)
RETURNS JSON AS $$
DECLARE
    user_uuid UUID;
    message_id UUID;
    user_name TEXT;
    user_username TEXT;
    is_participant BOOLEAN;
    result JSON;
BEGIN
    RAISE NOTICE 'add_discussion_message called: auth_user_id=%, discussion_id=%', auth_user_id, discussion_id;
    
    -- Get user info
    SELECT u.id, u.name, u.username INTO user_uuid, user_name, user_username
    FROM users u
    WHERE u.auth_user_id = add_discussion_message.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RETURN json_build_object('error', 'User not found');
    END IF;
    
    -- Check participation
    SELECT EXISTS(
        SELECT 1 FROM discussion_participants dp
        WHERE dp.discussion_id = add_discussion_message.discussion_id 
        AND dp.user_id = user_uuid
    ) INTO is_participant;
    
    IF NOT is_participant THEN
        RETURN json_build_object('error', 'You must join the discussion first');
    END IF;
    
    -- Insert message
    INSERT INTO discussion_messages (discussion_id, user_id, content, created_at)
    VALUES (discussion_id, user_uuid, message_content, NOW())
    RETURNING id INTO message_id;
    
    -- Build result
    SELECT json_build_object(
        'id', message_id,
        'discussionId', discussion_id,
        'userId', user_uuid,
        'userName', user_name,
        'userUsername', user_username,
        'content', message_content,
        'createdAt', NOW(),
        'isEdited', false
    ) INTO result;
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_discussion_messages(
    auth_user_id UUID,
    target_discussion_id UUID,
    limit_count INTEGER DEFAULT 50,
    offset_count INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    discussion_id UUID,
    user_id UUID,
    user_name TEXT,
    user_username TEXT,
    content TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    is_edited BOOLEAN
) AS $$
DECLARE
    user_uuid UUID;
    is_participant BOOLEAN;
BEGIN
    RAISE NOTICE 'get_discussion_messages called: auth_user_id=%, discussion_id=%', auth_user_id, target_discussion_id;
    
    -- Get user ID
    SELECT u.id INTO user_uuid FROM users u WHERE u.auth_user_id = get_discussion_messages.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RETURN;
    END IF;
    
    -- Check participation
    SELECT EXISTS(
        SELECT 1 FROM discussion_participants dp
        WHERE dp.discussion_id = target_discussion_id AND dp.user_id = user_uuid
    ) INTO is_participant;
    
    IF NOT is_participant THEN
        RETURN;
    END IF;
    
    -- Return messages
    RETURN QUERY
    SELECT 
        dm.id,
        dm.discussion_id,
        dm.user_id,
        COALESCE(u.name, 'Unknown') as user_name,
        COALESCE(u.username, 'unknown') as user_username,
        dm.content,
        dm.created_at,
        COALESCE(dm.is_edited, false) as is_edited
    FROM discussion_messages dm
    JOIN users u ON dm.user_id = u.id
    WHERE dm.discussion_id = target_discussion_id
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
GRANT EXECUTE ON FUNCTION join_discussion TO authenticated;
GRANT EXECUTE ON FUNCTION create_discussion TO authenticated;
GRANT EXECUTE ON FUNCTION add_discussion_message TO authenticated;
GRANT EXECUTE ON FUNCTION get_discussion_messages TO authenticated;

-- Final test
DO $$
DECLARE
    test_auth_id UUID := 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID;
    test_result RECORD;
    result_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== FINAL COMPREHENSIVE TEST ===';
    
    -- Test get_discussions
    FOR test_result IN SELECT * FROM get_discussions(test_auth_id)
    LOOP
        result_count := result_count + 1;
        RAISE NOTICE 'Discussion %: % (Participant: %)', result_count, test_result.title, test_result.is_participant;
    END LOOP;
    
    IF result_count > 0 THEN
        RAISE NOTICE '✅ SUCCESS: get_discussions returned % discussions', result_count;
        RAISE NOTICE '✅ Frontend should now load discussions properly';
        RAISE NOTICE '✅ All discussion functions created successfully';
    ELSE
        RAISE NOTICE '❌ get_discussions still returning 0 results';
        
        -- Check if discussions exist
        SELECT COUNT(*) INTO result_count FROM discussions;
        IF result_count > 0 THEN
            RAISE NOTICE '❌ PROBLEM: % discussions exist but function returns none', result_count;
        ELSE
            RAISE NOTICE '✅ No discussions in database - this is normal';
        END IF;
    END IF;
    
    RAISE NOTICE '=== DEPLOYMENT COMPLETE ===';
END $$;
