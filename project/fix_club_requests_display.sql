-- Quick fix for club requests display - the 2 pending requests should show
-- This ensures the get_club_join_requests function works properly

-- Drop and recreate only the get_club_join_requests function
DROP FUNCTION IF EXISTS get_club_join_requests(UUID, UUID) CASCADE;

CREATE OR REPLACE FUNCTION get_club_join_requests(
    auth_user_id UUID,
    club_id_param UUID
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    user_name TEXT,
    user_username TEXT,
    user_avatar_url TEXT,
    status TEXT,
    requested_at TEXT,
    message TEXT
) AS $$
DECLARE
    user_internal_id UUID;
    is_admin BOOLEAN;
    is_creator BOOLEAN;
BEGIN
    -- Get user's internal ID
    SELECT u.id INTO user_internal_id 
    FROM users u
    WHERE u.auth_user_id::TEXT = auth_user_id::TEXT;
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if user is admin or creator
    SELECT EXISTS(
        SELECT 1 FROM book_club_members bcm
        WHERE bcm.club_id = club_id_param 
        AND bcm.user_id = user_internal_id 
        AND bcm.role IN ('admin', 'owner')
    ) INTO is_admin;
    
    SELECT EXISTS(
        SELECT 1 FROM book_clubs bc
        WHERE bc.id = club_id_param AND bc.created_by = user_internal_id
    ) INTO is_creator;
    
    IF NOT (is_admin OR is_creator) THEN
        RAISE EXCEPTION 'Only admins can view join requests';
    END IF;
    
    -- Return join requests with proper type casting
    RETURN QUERY
    SELECT 
        cjr.id,
        cjr.user_id,
        COALESCE(u.name, 'Unknown User')::TEXT,
        COALESCE(u.username, 'unknown')::TEXT,
        COALESCE(u.avatar_url, '')::TEXT,
        cjr.status,
        cjr.requested_at::TEXT,
        COALESCE(cjr.message, '')::TEXT
    FROM club_join_requests cjr
    JOIN users u ON cjr.user_id = u.id
    WHERE cjr.club_id = club_id_param
    ORDER BY cjr.requested_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the function
DO $$
DECLARE
    test_user_id UUID;
    test_club_id UUID;
    test_result RECORD;
    result_count INTEGER := 0;
BEGIN
    -- Get test data
    SELECT u.auth_user_id INTO test_user_id FROM users u LIMIT 1;
    SELECT bc.id INTO test_club_id FROM book_clubs bc WHERE bc.is_public = FALSE LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_club_id IS NOT NULL THEN
        RAISE NOTICE 'Testing get_club_join_requests function...';
        RAISE NOTICE 'User: %, Club: %', test_user_id, test_club_id;
        
        BEGIN
            FOR test_result IN 
                SELECT * FROM get_club_join_requests(test_user_id, test_club_id)
            LOOP
                result_count := result_count + 1;
                RAISE NOTICE 'Join request found: id=%, user_name=%, status=%', 
                    test_result.id, test_result.user_name, test_result.status;
            END LOOP;
            
            RAISE NOTICE 'Total join requests found: %', result_count;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Function error: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE 'No test data available';
    END IF;
END $$;

-- Show the function status
SELECT 
    'Club Requests Function Fixed' as status,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name = 'get_club_join_requests' 
AND routine_schema = 'public';

-- Show current join requests
SELECT 
    'Current Join Requests' as info,
    cjr.id,
    u.name as user_name,
    u.username,
    cjr.status,
    cjr.requested_at
FROM club_join_requests cjr
JOIN users u ON cjr.user_id = u.id
ORDER BY cjr.requested_at DESC;
