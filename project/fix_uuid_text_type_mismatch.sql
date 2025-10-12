-- Fix the "operator does not exist: uuid = text" error
-- This error occurs when trying to compare UUID with TEXT without proper casting

-- Drop the problematic function
DROP FUNCTION IF EXISTS request_to_join_club(UUID, UUID, TEXT) CASCADE;

-- Recreate the function with proper type casting
CREATE OR REPLACE FUNCTION request_to_join_club(
    auth_user_id UUID,
    club_id_param UUID,
    message_param TEXT DEFAULT NULL
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    requires_approval BOOLEAN
) AS $$
DECLARE
    user_internal_id UUID;
    club_exists BOOLEAN;
    is_public BOOLEAN;
    is_already_member BOOLEAN;
    has_pending_request BOOLEAN;
BEGIN
    -- Get user's internal ID - proper type casting from UUID to TEXT
    SELECT users.id INTO user_internal_id 
    FROM users 
    WHERE users.auth_user_id::TEXT = auth_user_id::TEXT;
    
    IF user_internal_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'User not found'::TEXT, FALSE;
        RETURN;
    END IF;
    
    -- Check if club exists
    SELECT EXISTS(SELECT 1 FROM book_clubs WHERE book_clubs.id = club_id_param) INTO club_exists;
    
    IF NOT club_exists THEN
        RETURN QUERY SELECT FALSE, 'Book club not found'::TEXT, FALSE;
        RETURN;
    END IF;
    
    -- Get club visibility
    SELECT book_clubs.is_public INTO is_public 
    FROM book_clubs 
    WHERE book_clubs.id = club_id_param;
    
    -- Check if user is already a member
    SELECT EXISTS(
        SELECT 1 FROM book_club_members 
        WHERE book_club_members.club_id = club_id_param 
        AND book_club_members.user_id = user_internal_id
    ) INTO is_already_member;
    
    IF is_already_member THEN
        RETURN QUERY SELECT FALSE, 'You are already a member of this club'::TEXT, FALSE;
        RETURN;
    END IF;
    
    -- Check if user has a pending request
    SELECT EXISTS(
        SELECT 1 FROM club_join_requests 
        WHERE club_join_requests.club_id = club_id_param 
        AND club_join_requests.user_id = user_internal_id 
        AND club_join_requests.status = 'pending'
    ) INTO has_pending_request;
    
    IF has_pending_request THEN
        RETURN QUERY SELECT FALSE, 'You already have a pending request to join this club'::TEXT, FALSE;
        RETURN;
    END IF;
    
    -- Handle public clubs (direct join)
    IF is_public THEN
        -- Add user directly to the club
        INSERT INTO book_club_members (club_id, user_id, role, joined_at)
        VALUES (club_id_param, user_internal_id, 'member', NOW())
        ON CONFLICT (club_id, user_id) DO NOTHING;
        
        RETURN QUERY SELECT TRUE, 'Successfully joined the club'::TEXT, FALSE;
    ELSE
        -- Handle private clubs (create join request)
        INSERT INTO club_join_requests (club_id, user_id, message)
        VALUES (club_id_param, user_internal_id, message_param);
        
        RETURN QUERY SELECT TRUE, 'Join request sent successfully'::TEXT, TRUE;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Also fix the get_club_join_requests function
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
    requested_at TIMESTAMP WITH TIME ZONE,
    message TEXT
) AS $$
DECLARE
    user_internal_id UUID;
    is_admin BOOLEAN;
    is_creator BOOLEAN;
BEGIN
    -- Get user's internal ID - proper type casting
    SELECT users.id INTO user_internal_id 
    FROM users 
    WHERE users.auth_user_id::TEXT = auth_user_id::TEXT;
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if user is admin or creator
    SELECT EXISTS(
        SELECT 1 FROM book_club_members 
        WHERE book_club_members.club_id = club_id_param 
        AND book_club_members.user_id = user_internal_id 
        AND book_club_members.role IN ('admin', 'owner')
    ) INTO is_admin;
    
    SELECT EXISTS(
        SELECT 1 FROM book_clubs 
        WHERE book_clubs.id = club_id_param AND book_clubs.created_by = user_internal_id
    ) INTO is_creator;
    
    IF NOT (is_admin OR is_creator) THEN
        RAISE EXCEPTION 'Only admins can view join requests';
    END IF;
    
    -- Return join requests
    RETURN QUERY
    SELECT 
        cjr.id,
        cjr.user_id,
        u.name,
        u.username,
        u.avatar_url,
        cjr.status,
        cjr.requested_at,
        cjr.message
    FROM club_join_requests cjr
    JOIN users u ON cjr.user_id = u.id
    WHERE cjr.club_id = club_id_param
    ORDER BY cjr.requested_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Also fix the process_join_request function
DROP FUNCTION IF EXISTS process_join_request(UUID, UUID, BOOLEAN, TEXT) CASCADE;

CREATE OR REPLACE FUNCTION process_join_request(
    auth_user_id UUID,
    request_id UUID,
    approve BOOLEAN,
    message_param TEXT DEFAULT NULL
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    user_internal_id UUID;
    request_club_id UUID;
    request_user_id UUID;
    request_status TEXT;
    is_admin BOOLEAN;
    is_creator BOOLEAN;
BEGIN
    -- Get user's internal ID - proper type casting
    SELECT users.id INTO user_internal_id 
    FROM users 
    WHERE users.auth_user_id::TEXT = auth_user_id::TEXT;
    
    IF user_internal_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'User not found'::TEXT;
        RETURN;
    END IF;
    
    -- Get request details
    SELECT club_join_requests.club_id, club_join_requests.user_id, club_join_requests.status 
    INTO request_club_id, request_user_id, request_status
    FROM club_join_requests 
    WHERE club_join_requests.id = request_id;
    
    IF request_club_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Join request not found'::TEXT;
        RETURN;
    END IF;
    
    IF request_status != 'pending' THEN
        RETURN QUERY SELECT FALSE, 'This request has already been processed'::TEXT;
        RETURN;
    END IF;
    
    -- Check if user is admin or creator
    SELECT EXISTS(
        SELECT 1 FROM book_club_members 
        WHERE book_club_members.club_id = request_club_id 
        AND book_club_members.user_id = user_internal_id 
        AND book_club_members.role IN ('admin', 'owner')
    ) INTO is_admin;
    
    SELECT EXISTS(
        SELECT 1 FROM book_clubs 
        WHERE book_clubs.id = request_club_id AND book_clubs.created_by = user_internal_id
    ) INTO is_creator;
    
    IF NOT (is_admin OR is_creator) THEN
        RETURN QUERY SELECT FALSE, 'Only admins can process join requests'::TEXT;
        RETURN;
    END IF;
    
    -- Update the request status
    UPDATE club_join_requests 
    SET 
        status = CASE WHEN approve THEN 'approved' ELSE 'rejected' END,
        processed_at = NOW(),
        processed_by = user_internal_id,
        message = message_param
    WHERE club_join_requests.id = request_id;
    
    -- If approved, add user to the club
    IF approve THEN
        INSERT INTO book_club_members (club_id, user_id, role, joined_at)
        VALUES (request_club_id, request_user_id, 'member', NOW())
        ON CONFLICT (club_id, user_id) DO NOTHING;
    END IF;
    
    -- Return success
    IF approve THEN
        RETURN QUERY SELECT TRUE, 'Join request approved successfully'::TEXT;
    ELSE
        RETURN QUERY SELECT TRUE, 'Join request rejected'::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the fixed function
DO $$
DECLARE
    test_user_id UUID;
    test_club_id UUID;
    test_result RECORD;
BEGIN
    -- Get test data
    SELECT u.auth_user_id INTO test_user_id FROM users u LIMIT 1;
    SELECT bc.id INTO test_club_id FROM book_clubs bc WHERE bc.is_public = FALSE LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_club_id IS NOT NULL THEN
        RAISE NOTICE 'Testing fixed request_to_join_club function with proper type casting...';
        RAISE NOTICE 'User: %, Club: %', test_user_id, test_club_id;
        
        BEGIN
            FOR test_result IN 
                SELECT * FROM request_to_join_club(test_user_id, test_club_id, 'Test join request')
            LOOP
                RAISE NOTICE 'Function result: success=%, message=%, requires_approval=%', 
                    test_result.success, test_result.message, test_result.requires_approval;
            END LOOP;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Function error: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE 'No test data available';
    END IF;
END $$;

-- Show the function signatures to confirm they're created
SELECT 
    'Functions Fixed with Type Casting' as status,
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_name IN ('request_to_join_club', 'get_club_join_requests', 'process_join_request') 
AND routine_schema = 'public'
ORDER BY routine_name;
