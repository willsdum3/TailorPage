-- Complete Fix for Join Request Functionality
-- This script ensures all join request functions work correctly

-- First, let's ensure all necessary tables exist
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

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_club_join_requests_club_id ON club_join_requests(club_id);
CREATE INDEX IF NOT EXISTS idx_club_join_requests_user_id ON club_join_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_club_join_requests_status ON club_join_requests(status);

-- Enable RLS
ALTER TABLE club_join_requests ENABLE ROW LEVEL SECURITY;

-- RLS Policies for club_join_requests
DROP POLICY IF EXISTS "Users can view their own join requests" ON club_join_requests;
CREATE POLICY "Users can view their own join requests" ON club_join_requests
    FOR SELECT USING (auth.uid()::text IN (SELECT auth_user_id FROM users WHERE id = user_id));

DROP POLICY IF EXISTS "Users can create join requests" ON club_join_requests;
CREATE POLICY "Users can create join requests" ON club_join_requests
    FOR INSERT WITH CHECK (auth.uid()::text IN (SELECT auth_user_id FROM users WHERE id = user_id));

DROP POLICY IF EXISTS "Admins can view join requests for their clubs" ON club_join_requests;
CREATE POLICY "Admins can view join requests for their clubs" ON club_join_requests
    FOR SELECT USING (
        auth.uid()::text IN (
            SELECT u.auth_user_id 
            FROM users u 
            JOIN book_club_members bcm ON u.id = bcm.user_id 
            WHERE bcm.club_id = club_join_requests.club_id 
            AND bcm.role IN ('admin', 'owner')
        )
    );

DROP POLICY IF EXISTS "Admins can update join requests for their clubs" ON club_join_requests;
CREATE POLICY "Admins can update join requests for their clubs" ON club_join_requests
    FOR UPDATE USING (
        auth.uid()::text IN (
            SELECT u.auth_user_id 
            FROM users u 
            JOIN book_club_members bcm ON u.id = bcm.user_id 
            WHERE bcm.club_id = club_join_requests.club_id 
            AND bcm.role IN ('admin', 'owner')
        )
    );

-- Ensure book_clubs table has is_public column
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'book_clubs' AND column_name = 'is_public'
    ) THEN
        ALTER TABLE book_clubs ADD COLUMN is_public BOOLEAN DEFAULT TRUE;
    END IF;
END $$;

-- Update existing clubs to be public by default if is_public is NULL
UPDATE book_clubs SET is_public = TRUE WHERE is_public IS NULL;

-- Make is_public NOT NULL
ALTER TABLE book_clubs ALTER COLUMN is_public SET NOT NULL;

-- Drop and recreate all join request functions with correct implementations
DROP FUNCTION IF EXISTS request_to_join_club(UUID, UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS get_club_join_requests(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS process_join_request(UUID, UUID, BOOLEAN, TEXT) CASCADE;

-- Helper function to get user internal ID
CREATE OR REPLACE FUNCTION get_user_internal_id(auth_user_id UUID)
RETURNS UUID AS $$
DECLARE
    internal_id UUID;
BEGIN
    SELECT id INTO internal_id FROM users WHERE users.auth_user_id = get_user_internal_id.auth_user_id;
    RETURN internal_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Main join request function
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
    user_internal_id := get_user_internal_id(auth_user_id);
    
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
    
    -- Get club visibility and check if user is already a member - using explicit table references
    SELECT book_clubs.is_public INTO is_public FROM book_clubs WHERE book_clubs.id = club_id_param;
    SELECT EXISTS(
        SELECT 1 FROM book_club_members 
        WHERE book_club_members.club_id = club_id_param AND book_club_members.user_id = user_internal_id
    ) INTO is_already_member;
    
    IF is_already_member THEN
        RETURN QUERY SELECT FALSE, 'You are already a member of this club'::TEXT, FALSE;
        RETURN;
    END IF;
    
    -- Check if user has a pending request
    SELECT EXISTS(
        SELECT 1 FROM club_join_requests 
        WHERE club_join_requests.club_id = club_id_param AND club_join_requests.user_id = user_internal_id AND club_join_requests.status = 'pending'
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

-- Function to get club join requests for admins
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
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if user is admin or creator - using explicit table references
    SELECT EXISTS(
        SELECT 1 FROM book_club_members 
        WHERE book_club_members.club_id = club_id_param 
        AND book_club_members.user_id = user_internal_id 
        AND book_club_members.role = 'admin'
    ) INTO is_admin;
    
    SELECT EXISTS(
        SELECT 1 FROM book_clubs 
        WHERE book_clubs.id = club_id_param AND book_clubs.created_by = user_internal_id
    ) INTO is_creator;
    
    IF NOT (is_admin OR is_creator) THEN
        RAISE EXCEPTION 'Only admins can view join requests';
    END IF;
    
    -- Return join requests - using explicit table references
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

-- Function to process join requests (approve/decline)
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
    request_exists BOOLEAN;
    is_admin BOOLEAN;
    is_creator BOOLEAN;
    request_club_id UUID;
    request_user_id UUID;
    request_status TEXT;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'User not found'::TEXT;
        RETURN;
    END IF;
    
    -- Get request details - using explicit table references
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
    
    -- Check if user is admin or creator - using explicit table references
    SELECT EXISTS(
        SELECT 1 FROM book_club_members 
        WHERE book_club_members.club_id = request_club_id 
        AND book_club_members.user_id = user_internal_id 
        AND book_club_members.role = 'admin'
    ) INTO is_admin;
    
    SELECT EXISTS(
        SELECT 1 FROM book_clubs 
        WHERE book_clubs.id = request_club_id AND book_clubs.created_by = user_internal_id
    ) INTO is_creator;
    
    IF NOT (is_admin OR is_creator) THEN
        RETURN QUERY SELECT FALSE, 'Only admins can process join requests'::TEXT;
        RETURN;
    END IF;
    
    -- Update the request status - using explicit table references
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
    test_request_id UUID;
BEGIN
    -- Get test data
    SELECT u.auth_user_id INTO test_user_id FROM users u WHERE u.name = 'Kat Slater' LIMIT 1;
    SELECT bc.id INTO test_club_id FROM book_clubs bc WHERE bc.is_public = FALSE LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_club_id IS NOT NULL THEN
        RAISE NOTICE 'Testing join request functionality...';
        RAISE NOTICE 'User: %, Club: %', test_user_id, test_club_id;
        
        -- Test requesting to join a private club
        FOR test_result IN 
            SELECT * FROM request_to_join_club(test_user_id, test_club_id, 'I would like to join this private club')
        LOOP
            RAISE NOTICE 'Join request result: success=%, message=%, requires_approval=%', 
                test_result.success, test_result.message, test_result.requires_approval;
        END LOOP;
        
        -- Test getting join requests (if user is admin)
        BEGIN
            FOR test_result IN 
                SELECT * FROM get_club_join_requests(test_user_id, test_club_id)
            LOOP
                RAISE NOTICE 'Join request found: id=%, user_name=%, status=%', 
                    test_result.id, test_result.user_name, test_result.status;
                test_request_id := test_result.id;
                EXIT; -- Just get the first one
            END LOOP;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'User is not admin of this club (expected for testing)';
        END;
    ELSE
        RAISE NOTICE 'No test data found for private clubs';
    END IF;
END $$;

-- Show the function signatures
SELECT 
    'Join Request Functions Created' as check_type,
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_name IN ('request_to_join_club', 'get_club_join_requests', 'process_join_request') 
AND routine_schema = 'public'
ORDER BY routine_name;
