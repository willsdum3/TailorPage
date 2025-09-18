-- =====================================================
-- SIMPLE FIX FOR GET_DISCUSSIONS FUNCTION
-- =====================================================
-- This creates a simple, working get_discussions function

-- Drop ALL possible variations aggressively
DO $$
DECLARE
    func_record RECORD;
BEGIN
    RAISE NOTICE '=== DROPPING ALL GET_DISCUSSIONS VARIATIONS ===';
    
    -- Get all get_discussions functions and drop them
    FOR func_record IN 
        SELECT 
            p.proname as function_name,
            pg_get_function_identity_arguments(p.oid) as arguments
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
        AND p.proname = 'get_discussions'
    LOOP
        BEGIN
            EXECUTE 'DROP FUNCTION IF EXISTS ' || func_record.function_name || '(' || func_record.arguments || ')';
            RAISE NOTICE 'Dropped: %(%)', func_record.function_name, func_record.arguments;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Failed to drop %: %', func_record.function_name, SQLERRM;
        END;
    END LOOP;
END $$;

-- Create a simple, bulletproof get_discussions function
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
    RAISE NOTICE 'get_discussions called with auth_user_id: %', auth_user_id;
    
    -- Get user ID from auth_user_id
    SELECT u.id INTO user_uuid
    FROM users u
    WHERE u.auth_user_id = get_discussions.auth_user_id;
    
    RAISE NOTICE 'Found user_uuid: %', user_uuid;
    
    -- Simple query to return all discussions with participant info
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
        (SELECT COUNT(*) FROM discussion_participants WHERE discussion_id = d.id)::BIGINT as participant_count,
        -- Get last message time or created time
        COALESCE(
            (SELECT MAX(created_at) FROM discussion_messages WHERE discussion_id = d.id), 
            d.created_at
        ) as last_message_at,
        -- Check if current user is participant
        CASE 
            WHEN user_uuid IS NULL THEN false
            ELSE EXISTS(
                SELECT 1 FROM discussion_participants 
                WHERE discussion_id = d.id AND user_id = user_uuid
            )
        END as is_participant,
        -- Get creator name
        COALESCE(
            (SELECT COALESCE(creator.username, creator.name, 'Unknown') 
             FROM users creator WHERE creator.id = d.created_by),
            'Unknown'
        ) as creator_name
    FROM discussions d
    ORDER BY d.created_at DESC;
    
    RAISE NOTICE 'get_discussions query completed';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in get_discussions: %', SQLERRM;
        RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_discussions TO authenticated;

-- Test the function immediately
DO $$
DECLARE
    test_auth_id UUID := 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID; -- From your console
    test_result RECORD;
    result_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== TESTING NEW GET_DISCUSSIONS FUNCTION ===';
    
    -- Test with your actual user ID
    FOR test_result IN SELECT * FROM get_discussions(test_auth_id)
    LOOP
        result_count := result_count + 1;
        RAISE NOTICE 'Result %: % (ID: %)', result_count, test_result.title, test_result.id;
        RAISE NOTICE '  Participant: %, Creator: %', test_result.is_participant, test_result.creator_name;
        RAISE NOTICE '  Participants: %, Last activity: %', test_result.participant_count, test_result.last_message_at;
    END LOOP;
    
    RAISE NOTICE 'Function returned % discussions', result_count;
    
    IF result_count = 0 THEN
        RAISE NOTICE '❌ Function still returns 0 - investigating further...';
        
        -- Check if discussions exist at all
        SELECT COUNT(*) INTO result_count FROM discussions;
        RAISE NOTICE 'Total discussions in table: %', result_count;
        
        -- Check if user exists
        SELECT COUNT(*) INTO result_count FROM users WHERE auth_user_id = test_auth_id;
        RAISE NOTICE 'User found in users table: %', result_count;
    ELSE
        RAISE NOTICE '✅ Function working - returned % discussions', result_count;
    END IF;
END $$;

-- Also test with a simpler version that just returns all discussions
CREATE OR REPLACE FUNCTION get_all_discussions_simple()
RETURNS TABLE (
    id UUID,
    title TEXT,
    content TEXT,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.id,
        d.title,
        d.content,
        d.created_at
    FROM discussions d
    ORDER BY d.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_all_discussions_simple TO authenticated;

-- Test the simple function
SELECT 'Simple Function Test' as test, * FROM get_all_discussions_simple();

-- Final status
DO $$
BEGIN
    RAISE NOTICE '=== GET_DISCUSSIONS DEBUG COMPLETE ===';
    RAISE NOTICE 'Check the results above to see:';
    RAISE NOTICE '1. If the user lookup is working';
    RAISE NOTICE '2. If the function returns any discussions';
    RAISE NOTICE '3. If there are any function errors';
    RAISE NOTICE '4. Comparison with simple function that just returns all discussions';
END $$;
