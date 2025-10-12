-- MINIMAL FIX: Only fix club join requests functions without touching messaging
-- This script ONLY modifies club join request functions to avoid affecting messaging

-- First, let's check if the club_join_requests table exists
CREATE TABLE IF NOT EXISTS club_join_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    club_id UUID NOT NULL REFERENCES book_clubs(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    message TEXT,
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE,
    processed_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS with simple policy
ALTER TABLE club_join_requests ENABLE ROW LEVEL SECURITY;

-- Remove any existing policies and create simple one
DROP POLICY IF EXISTS "Simple authenticated access" ON club_join_requests;
DROP POLICY IF EXISTS "Allow all for authenticated users" ON club_join_requests;
DROP POLICY IF EXISTS "Allow all operations for authenticated users" ON club_join_requests;

CREATE POLICY "Simple authenticated access" ON club_join_requests
    FOR ALL USING (auth.uid() IS NOT NULL);

-- ONLY drop and recreate club join request functions (NOT messaging functions)
DROP FUNCTION IF EXISTS request_to_join_club(UUID, UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS get_club_join_requests(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS process_join_request(UUID, UUID, BOOLEAN, TEXT) CASCADE;

-- Create request_to_join_club function with correct signature and types
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
    -- Get user's internal ID
    SELECT u.id INTO user_internal_id 
    FROM users u
    WHERE u.auth_user_id::TEXT = auth_user_id::TEXT;
    
    IF user_internal_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'User not found'::TEXT, FALSE;
        RETURN;
    END IF;
    
    -- Check if club exists
    SELECT EXISTS(SELECT 1 FROM book_clubs bc WHERE bc.id = club_id_param) INTO club_exists;
    
    IF NOT club_exists THEN
        RETURN QUERY SELECT FALSE, 'Book club not found'::TEXT, FALSE;
        RETURN;
    END IF;
    
    -- Get club visibility
    SELECT bc.is_public INTO is_public 
    FROM book_clubs bc
    WHERE bc.id = club_id_param;
    
    -- Check if user is already a member
    SELECT EXISTS(
        SELECT 1 FROM book_club_members bcm
        WHERE bcm.club_id = club_id_param 
        AND bcm.user_id = user_internal_id
    ) INTO is_already_member;
    
    IF is_already_member THEN
        RETURN QUERY SELECT FALSE, 'You are already a member of this club'::TEXT, FALSE;
        RETURN;
    END IF;
    
    -- Check if user has a pending request
    SELECT EXISTS(
        SELECT 1 FROM club_join_requests cjr
        WHERE cjr.club_id = club_id_param 
        AND cjr.user_id = user_internal_id 
        AND cjr.status = 'pending'
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

-- Create get_club_join_requests function with correct return types
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

-- Create process_join_request function
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
    -- Get user's internal ID
    SELECT u.id INTO user_internal_id 
    FROM users u
    WHERE u.auth_user_id::TEXT = auth_user_id::TEXT;
    
    IF user_internal_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'User not found'::TEXT;
        RETURN;
    END IF;
    
    -- Get request details
    SELECT cjr.club_id, cjr.user_id, cjr.status 
    INTO request_club_id, request_user_id, request_status
    FROM club_join_requests cjr
    WHERE cjr.id = request_id;
    
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
        SELECT 1 FROM book_club_members bcm
        WHERE bcm.club_id = request_club_id 
        AND bcm.user_id = user_internal_id 
        AND bcm.role IN ('admin', 'owner')
    ) INTO is_admin;
    
    SELECT EXISTS(
        SELECT 1 FROM book_clubs bc
        WHERE bc.id = request_club_id AND bc.created_by = user_internal_id
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

-- Test the functions
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
        RAISE NOTICE 'Testing club join request functions...';
        RAISE NOTICE 'User: %, Club: %', test_user_id, test_club_id;
        
        -- Test get_club_join_requests
        BEGIN
            FOR test_result IN 
                SELECT * FROM get_club_join_requests(test_user_id, test_club_id)
            LOOP
                result_count := result_count + 1;
                RAISE NOTICE 'Join request found: id=%, user_name=%, status=%', 
                    test_result.id, test_result.user_name, test_result.status;
            END LOOP;
            
            IF result_count = 0 THEN
                RAISE NOTICE 'No join requests found (this is normal if no requests exist)';
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'get_club_join_requests error: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE 'No test data available';
    END IF;
END $$;

-- Show function status
SELECT 
    'Club Join Request Functions Fixed' as status,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name IN ('request_to_join_club', 'get_club_join_requests', 'process_join_request') 
AND routine_schema = 'public'
ORDER BY routine_name;

-- Check join requests count
SELECT 
    'Join Requests Status' as info,
    COUNT(*) as total_requests,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_requests,
    COUNT(CASE WHEN status = 'approved' THEN 1 END) as approved_requests,
    COUNT(CASE WHEN status = 'rejected' THEN 1 END) as rejected_requests
FROM club_join_requests;
