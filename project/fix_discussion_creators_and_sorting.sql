-- =====================================================
-- FIX DISCUSSION CREATORS AND SORTING
-- =====================================================
-- Update get_discussions to include proper creator info and user creation status

DROP FUNCTION IF EXISTS get_discussions(UUID);

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
    creator_name TEXT,
    creator_username TEXT,
    is_created_by_user BOOLEAN
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
    
    -- Return all discussions with enhanced creator information
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
            (SELECT COALESCE(creator.name, creator.username, 'Unknown')
             FROM users creator WHERE creator.id = d.created_by),
            'Unknown'
        ) as creator_name,
        -- Creator username
        COALESCE(
            (SELECT creator.username
             FROM users creator WHERE creator.id = d.created_by),
            NULL
        ) as creator_username,
        -- Is created by current user
        CASE 
            WHEN user_uuid IS NULL THEN false
            ELSE d.created_by = user_uuid
        END as is_created_by_user
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

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_discussions TO authenticated;

-- Test the updated function
DO $$
DECLARE
    test_auth_id UUID := 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID;
    test_result RECORD;
    result_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== TESTING ENHANCED GET_DISCUSSIONS ===';
    
    FOR test_result IN SELECT * FROM get_discussions(test_auth_id)
    LOOP
        result_count := result_count + 1;
        RAISE NOTICE 'Discussion %: %', result_count, test_result.title;
        RAISE NOTICE '  Creator: % (@%)', test_result.creator_name, COALESCE(test_result.creator_username, 'no_username');
        RAISE NOTICE '  Created by user: %', test_result.is_created_by_user;
        RAISE NOTICE '  Participant: %', test_result.is_participant;
        RAISE NOTICE '---';
    END LOOP;
    
    RAISE NOTICE 'ENHANCED FUNCTION RETURNED % DISCUSSIONS', result_count;
    
    IF result_count > 0 THEN
        RAISE NOTICE '✅ SUCCESS: get_discussions function enhanced with creator info!';
    ELSE
        RAISE NOTICE '❌ No discussions returned';
    END IF;
END $$;
