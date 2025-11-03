-- Restore Missing Database Functions
-- This script creates the essential functions that the frontend is calling
-- Based on the console errors showing missing get_book_clubs and get_discussions functions

-- ===========================================
-- STEP 1: CREATE GET_BOOK_CLUBS FUNCTION
-- ===========================================

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS get_book_clubs(UUID);
DROP FUNCTION IF EXISTS get_book_clubs(UUID, TEXT);
DROP FUNCTION IF EXISTS get_book_clubs(UUID, TEXT, INTEGER);

-- Create get_book_clubs function
CREATE OR REPLACE FUNCTION get_book_clubs(
    p_auth_user_id UUID
)
RETURNS TABLE(
    id UUID,
    name TEXT,
    description TEXT,
    creator_id UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    is_public BOOLEAN,
    current_book_title TEXT,
    current_book_author TEXT,
    meeting_info TEXT,
    member_count BIGINT,
    is_member BOOLEAN,
    is_admin BOOLEAN,
    creator_name TEXT,
    creator_username TEXT
) AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(p_auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Return book clubs with membership info
    RETURN QUERY
    SELECT 
        bc.id,
        bc.name,
        bc.description,
        bc.creator_id,
        bc.created_at,
        COALESCE(bc.is_public, true) as is_public,
        bc.current_book_title,
        bc.current_book_author,
        bc.meeting_info,
        COUNT(bcm.user_id) as member_count,
        EXISTS(
            SELECT 1 FROM book_club_members bcm2 
            WHERE bcm2.club_id = bc.id 
            AND bcm2.user_id = user_internal_id
        ) as is_member,
        EXISTS(
            SELECT 1 FROM book_club_members bcm3 
            WHERE bcm3.club_id = bc.id 
            AND bcm3.user_id = user_internal_id 
            AND bcm3.role = 'admin'
        ) as is_admin,
        u.name as creator_name,
        u.username as creator_username
    FROM book_clubs bc
    LEFT JOIN book_club_members bcm ON bc.id = bcm.club_id
    LEFT JOIN users u ON bc.creator_id = u.id
    GROUP BY bc.id, bc.name, bc.description, bc.creator_id, bc.created_at, bc.is_public, 
             bc.current_book_title, bc.current_book_author, bc.meeting_info, u.name, u.username
    ORDER BY bc.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- STEP 2: CREATE GET_DISCUSSIONS FUNCTION
-- ===========================================

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS get_discussions(UUID);
DROP FUNCTION IF EXISTS get_discussions(UUID, TEXT);
DROP FUNCTION IF EXISTS get_discussions(UUID, TEXT, INTEGER);

-- Create get_discussions function
CREATE OR REPLACE FUNCTION get_discussions(
    p_auth_user_id UUID
)
RETURNS TABLE(
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
    user_internal_id UUID;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(p_auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Return discussions with participation info
    RETURN QUERY
    SELECT 
        d.id,
        d.title,
        d.content,
        d.book_title,
        d.book_author,
        COALESCE(d.tags, ARRAY[]::TEXT[]) as tags,
        d.created_by,
        d.created_at,
        COUNT(dm.user_id) as participant_count,
        COALESCE(MAX(dm.joined_at), d.created_at) as last_activity,
        EXISTS(
            SELECT 1 FROM discussion_members dm2 
            WHERE dm2.discussion_id = d.id 
            AND dm2.user_id = user_internal_id
        ) as is_participant,
        u.name as creator_name,
        u.username as creator_username,
        (d.created_by = user_internal_id) as is_created_by_user
    FROM discussions d
    LEFT JOIN discussion_members dm ON d.id = dm.discussion_id
    LEFT JOIN users u ON d.created_by = u.id
    GROUP BY d.id, d.title, d.content, d.book_title, d.book_author, d.tags, 
             d.created_by, d.created_at, u.name, u.username
    ORDER BY d.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- STEP 3: CREATE GET_BOOK_CLUB_DETAILS FUNCTION
-- ===========================================

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS get_book_club_details(UUID, UUID);
DROP FUNCTION IF EXISTS get_book_club_details(UUID, TEXT);

-- Create get_book_club_details function
CREATE OR REPLACE FUNCTION get_book_club_details(
    p_auth_user_id UUID,
    p_club_id UUID
)
RETURNS TABLE(
    id UUID,
    name TEXT,
    description TEXT,
    creator_id UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    is_public BOOLEAN,
    current_book_title TEXT,
    current_book_author TEXT,
    meeting_info TEXT,
    member_count BIGINT,
    is_member BOOLEAN,
    is_admin BOOLEAN,
    creator_name TEXT,
    creator_username TEXT
) AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(p_auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Return specific book club details
    RETURN QUERY
    SELECT 
        bc.id,
        bc.name,
        bc.description,
        bc.creator_id,
        bc.created_at,
        COALESCE(bc.is_public, true) as is_public,
        bc.current_book_title,
        bc.current_book_author,
        bc.meeting_info,
        COUNT(bcm.user_id) as member_count,
        EXISTS(
            SELECT 1 FROM book_club_members bcm2 
            WHERE bcm2.club_id = bc.id 
            AND bcm2.user_id = user_internal_id
        ) as is_member,
        EXISTS(
            SELECT 1 FROM book_club_members bcm3 
            WHERE bcm3.club_id = bc.id 
            AND bcm3.user_id = user_internal_id 
            AND bcm3.role = 'admin'
        ) as is_admin,
        u.name as creator_name,
        u.username as creator_username
    FROM book_clubs bc
    LEFT JOIN book_club_members bcm ON bc.id = bcm.club_id
    LEFT JOIN users u ON bc.creator_id = u.id
    WHERE bc.id = p_club_id
    GROUP BY bc.id, bc.name, bc.description, bc.creator_id, bc.created_at, bc.is_public, 
             bc.current_book_title, bc.current_book_author, bc.meeting_info, u.name, u.username;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- STEP 4: CREATE GET_BOOK_CLUB_MEMBERS FUNCTION
-- ===========================================

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS get_book_club_members(UUID, UUID);
DROP FUNCTION IF EXISTS get_book_club_members(UUID, TEXT);

-- Create get_book_club_members function
CREATE OR REPLACE FUNCTION get_book_club_members(
    p_auth_user_id UUID,
    p_club_id UUID
)
RETURNS TABLE(
    id UUID,
    user_id UUID,
    role TEXT,
    joined_at TIMESTAMP WITH TIME ZONE,
    user_name TEXT,
    user_username TEXT,
    user_email TEXT
) AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(p_auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if user is a member of the club
    IF NOT EXISTS (
        SELECT 1 FROM book_club_members bcm
        WHERE bcm.club_id = p_club_id 
        AND bcm.user_id = user_internal_id
    ) THEN
        RAISE EXCEPTION 'User is not a member of this club';
    END IF;
    
    -- Return club members
    RETURN QUERY
    SELECT 
        bcm.id,
        bcm.user_id,
        bcm.role,
        bcm.joined_at,
        u.name as user_name,
        u.username as user_username,
        u.email as user_email
    FROM book_club_members bcm
    JOIN users u ON bcm.user_id = u.id
    WHERE bcm.club_id = p_club_id
    ORDER BY bcm.role DESC, bcm.joined_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- STEP 5: CREATE GET_DISCUSSION_MESSAGES FUNCTION
-- ===========================================

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS get_discussion_messages(UUID, UUID, INTEGER);
DROP FUNCTION IF EXISTS get_discussion_messages(UUID, UUID);

-- Create get_discussion_messages function
CREATE OR REPLACE FUNCTION get_discussion_messages(
    p_auth_user_id UUID,
    p_discussion_id UUID,
    p_limit INTEGER DEFAULT 50
)
RETURNS TABLE(
    id UUID,
    user_id UUID,
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    user_name TEXT,
    user_username TEXT
) AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(p_auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if user is a member of the discussion
    IF NOT EXISTS (
        SELECT 1 FROM discussion_members dm
        WHERE dm.discussion_id = p_discussion_id 
        AND dm.user_id = user_internal_id
    ) THEN
        RAISE EXCEPTION 'User is not a member of this discussion';
    END IF;
    
    -- Return discussion messages
    RETURN QUERY
    SELECT 
        dm.id,
        dm.user_id,
        dm.message,
        dm.created_at,
        u.name as user_name,
        u.username as user_username
    FROM discussion_messages dm
    JOIN users u ON dm.user_id = u.id
    WHERE dm.discussion_id = p_discussion_id
    ORDER BY dm.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- STEP 6: VERIFICATION
-- ===========================================

-- Verify all functions exist
SELECT 
    'Function Verification' as check_type,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name IN (
    'get_book_clubs',
    'get_discussions',
    'get_book_club_details',
    'get_book_club_members',
    'get_discussion_messages'
)
ORDER BY routine_name;

-- Final success message
SELECT 
    'Missing Functions Restored' as status,
    'All essential database functions have been created to restore book clubs and discussions' as message;
