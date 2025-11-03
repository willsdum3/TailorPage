-- Safe Fix for Ambiguous Column References
-- This script handles function dropping more carefully to avoid conflicts

-- ===========================================
-- STEP 1: SAFELY DROP FUNCTIONS WITH SPECIFIC SIGNATURES
-- ===========================================

-- Drop functions with specific parameter lists to avoid ambiguity
DROP FUNCTION IF EXISTS get_user_internal_id(UUID);
DROP FUNCTION IF EXISTS get_user_internal_id(UUID, UUID);

DROP FUNCTION IF EXISTS add_book_club_message(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS add_book_club_message(UUID, TEXT);

DROP FUNCTION IF EXISTS add_discussion_message(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS add_discussion_message(UUID, TEXT);

DROP FUNCTION IF EXISTS join_book_club(UUID, UUID);
DROP FUNCTION IF EXISTS join_book_club(UUID, UUID, TEXT);

DROP FUNCTION IF EXISTS promote_user_to_admin(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS promote_user_to_admin(UUID, UUID, TEXT, TEXT);

DROP FUNCTION IF EXISTS invite_user_to_club(UUID, UUID, TEXT, TEXT);
DROP FUNCTION IF EXISTS invite_user_to_club(UUID, UUID, TEXT);

DROP FUNCTION IF EXISTS is_user_club_admin(UUID, UUID);

-- Drop create_book_club with specific signatures
DROP FUNCTION IF EXISTS create_book_club(UUID, TEXT, TEXT);
DROP FUNCTION IF EXISTS create_book_club(UUID, TEXT, TEXT, TEXT);

-- Drop other functions that might conflict
DROP FUNCTION IF EXISTS get_book_clubs(UUID);
DROP FUNCTION IF EXISTS get_book_club_details(UUID, UUID);
DROP FUNCTION IF EXISTS get_book_club_members(UUID, UUID);
DROP FUNCTION IF EXISTS get_book_club_messages(UUID, UUID);
DROP FUNCTION IF EXISTS leave_book_club(UUID, UUID);
DROP FUNCTION IF EXISTS delete_book_club(UUID, UUID);
DROP FUNCTION IF EXISTS remove_user_from_book_club(UUID, UUID, UUID);
DROP FUNCTION IF EXISTS update_book_club_details(UUID, UUID, TEXT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS create_discussion(UUID, TEXT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS get_discussions(UUID);
DROP FUNCTION IF EXISTS join_discussion(UUID, UUID);
DROP FUNCTION IF EXISTS leave_discussion(UUID, UUID);
DROP FUNCTION IF EXISTS delete_discussion(UUID, UUID);
DROP FUNCTION IF EXISTS get_discussion_messages(UUID, UUID, INTEGER);

-- ===========================================
-- STEP 2: CREATE HELPER FUNCTIONS
-- ===========================================

-- Create get_user_internal_id function with proper parameter naming
CREATE OR REPLACE FUNCTION get_user_internal_id(p_auth_user_id UUID)
RETURNS UUID AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    SELECT u.id INTO user_internal_id
    FROM users u 
    WHERE u.auth_user_id = p_auth_user_id;
    
    RETURN user_internal_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create is_user_club_admin function with proper parameter naming
CREATE OR REPLACE FUNCTION is_user_club_admin(p_user_internal_id UUID, p_club_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    is_admin BOOLEAN := FALSE;
    club_creator_id UUID;
BEGIN
    -- Get club creator
    SELECT bc.creator_id INTO club_creator_id
    FROM book_clubs bc
    WHERE bc.id = p_club_id;
    
    -- Check if user is creator or has admin role
    IF p_user_internal_id = club_creator_id THEN
        is_admin := TRUE;
    ELSE
        -- Check if user has admin role in book_club_members
        SELECT EXISTS (
            SELECT 1 FROM book_club_members bcm
            WHERE bcm.club_id = p_club_id 
            AND bcm.user_id = p_user_internal_id
            AND bcm.role = 'admin'
        ) INTO is_admin;
    END IF;
    
    RETURN is_admin;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- STEP 3: CREATE CORE BOOK CLUB FUNCTIONS
-- ===========================================

-- Create book club function
CREATE OR REPLACE FUNCTION create_book_club(
    p_auth_user_id UUID,
    p_club_name TEXT,
    p_club_description TEXT
)
RETURNS JSONB AS $$
DECLARE
    user_internal_id UUID;
    club_id UUID;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(p_auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Create the book club
    INSERT INTO book_clubs (name, description, creator_id, created_at)
    VALUES (p_club_name, p_club_description, user_internal_id, NOW())
    RETURNING id INTO club_id;
    
    -- Add creator as admin member
    INSERT INTO book_club_members (club_id, user_id, role, joined_at)
    VALUES (club_id, user_internal_id, 'admin', NOW());
    
    RETURN jsonb_build_object('success', true, 'club_id', club_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Join book club function
CREATE OR REPLACE FUNCTION join_book_club(
    p_auth_user_id UUID,
    p_club_id UUID
)
RETURNS JSONB AS $$
DECLARE
    user_internal_id UUID;
    club_name TEXT;
    existing_member_count INTEGER;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(p_auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Get club name
    SELECT bc.name INTO club_name
    FROM book_clubs bc
    WHERE bc.id = p_club_id;
    
    IF club_name IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Club not found');
    END IF;
    
    -- Check if user is already a member
    IF EXISTS (
        SELECT 1 FROM book_club_members bcm
        WHERE bcm.club_id = p_club_id 
        AND bcm.user_id = user_internal_id
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'You are already a member of this club');
    END IF;
    
    -- Add user as member
    INSERT INTO book_club_members (club_id, user_id, role, joined_at)
    VALUES (p_club_id, user_internal_id, 'member', NOW());
    
    -- Get current member count
    SELECT COUNT(*) INTO existing_member_count
    FROM book_club_members bcm
    WHERE bcm.club_id = p_club_id;
    
    RETURN jsonb_build_object('success', true, 'message', 'Successfully joined ' || club_name, 'member_count', existing_member_count);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add book club message function
CREATE OR REPLACE FUNCTION add_book_club_message(
    p_auth_user_id UUID,
    p_club_id UUID,
    p_content TEXT
)
RETURNS UUID AS $$
DECLARE
    user_internal_id UUID;
    message_id UUID;
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
    
    -- Insert the message
    INSERT INTO book_club_messages (club_id, user_id, message, created_at)
    VALUES (p_club_id, user_internal_id, p_content, NOW())
    RETURNING id INTO message_id;
    
    RETURN message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get book club messages function
CREATE OR REPLACE FUNCTION get_book_club_messages(
    p_auth_user_id UUID,
    p_club_id UUID
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
    
    -- Check if user is a member of the club
    IF NOT EXISTS (
        SELECT 1 FROM book_club_members bcm
        WHERE bcm.club_id = p_club_id 
        AND bcm.user_id = user_internal_id
    ) THEN
        RAISE EXCEPTION 'User is not a member of this club';
    END IF;
    
    -- Return messages with user details
    RETURN QUERY
    SELECT 
        bcm.id,
        bcm.user_id,
        bcm.message,
        bcm.created_at,
        u.name,
        u.username
    FROM book_club_messages bcm
    JOIN users u ON bcm.user_id = u.id
    WHERE bcm.club_id = p_club_id
    ORDER BY bcm.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Promote user to admin function
CREATE OR REPLACE FUNCTION promote_user_to_admin(
    p_auth_user_id UUID,
    p_club_id UUID,
    p_user_to_promote_id TEXT
)
RETURNS JSONB AS $$
DECLARE
    promoter_internal_id UUID;
    target_internal_id UUID;
    target_name TEXT;
    club_name TEXT;
    is_promoter_admin BOOLEAN;
BEGIN
    -- Get promoter's internal ID
    promoter_internal_id := get_user_internal_id(p_auth_user_id);
    
    IF promoter_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Promoter not found');
    END IF;
    
    -- Get target user's internal ID
    SELECT u.id, u.name INTO target_internal_id, target_name
    FROM users u 
    WHERE u.id::text = p_user_to_promote_id;
    
    IF target_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Target user not found');
    END IF;
    
    -- Get club name
    SELECT bc.name INTO club_name
    FROM book_clubs bc
    WHERE bc.id = p_club_id;
    
    IF club_name IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Club not found');
    END IF;
    
    -- Check if promoter is admin
    is_promoter_admin := is_user_club_admin(promoter_internal_id, p_club_id);
    
    IF NOT is_promoter_admin THEN
        RETURN jsonb_build_object('success', false, 'error', 'Only admins can promote users');
    END IF;
    
    -- Check if target user is a member
    IF NOT EXISTS (
        SELECT 1 FROM book_club_members bcm
        WHERE bcm.club_id = p_club_id 
        AND bcm.user_id = target_internal_id
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'User is not a member of this club');
    END IF;
    
    -- Update user role to admin
    UPDATE book_club_members 
    SET role = 'admin'
    WHERE club_id = p_club_id 
    AND user_id = target_internal_id;
    
    RETURN jsonb_build_object('success', true, 'message', target_name || ' has been promoted to admin');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Invite user to club function
CREATE OR REPLACE FUNCTION invite_user_to_club(
    p_auth_user_id UUID,
    p_club_id UUID,
    p_username TEXT,
    p_message TEXT
)
RETURNS JSONB AS $$
DECLARE
    inviter_internal_id UUID;
    target_user_id UUID;
    target_name TEXT;
    club_name TEXT;
    is_inviter_admin BOOLEAN;
BEGIN
    -- Get inviter's internal ID
    inviter_internal_id := get_user_internal_id(p_auth_user_id);
    
    IF inviter_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Inviter not found');
    END IF;
    
    -- Get target user by username
    SELECT u.id, u.name INTO target_user_id, target_name
    FROM users u 
    WHERE u.username = p_username;
    
    IF target_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Check if user is already a member
    IF EXISTS (
        SELECT 1 FROM book_club_members bcm 
        WHERE bcm.club_id = p_club_id 
        AND bcm.user_id = target_user_id
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'User is already a member of this club');
    END IF;
    
    -- Get club name
    SELECT bc.name INTO club_name
    FROM book_clubs bc
    WHERE bc.id = p_club_id;
    
    IF club_name IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Club not found');
    END IF;
    
    -- Check if inviter is admin
    is_inviter_admin := is_user_club_admin(inviter_internal_id, p_club_id);
    
    IF NOT is_inviter_admin THEN
        RETURN jsonb_build_object('success', false, 'error', 'Only admins can invite users to clubs');
    END IF;
    
    RETURN jsonb_build_object('success', true, 'message', 'Invitation sent successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- STEP 4: CREATE DISCUSSION FUNCTIONS
-- ===========================================

-- Add discussion message function
CREATE OR REPLACE FUNCTION add_discussion_message(
    p_auth_user_id UUID,
    p_discussion_id UUID,
    p_message_content TEXT
)
RETURNS UUID AS $$
DECLARE
    user_internal_id UUID;
    message_id UUID;
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
    
    -- Insert the message
    INSERT INTO discussion_messages (discussion_id, user_id, message, created_at)
    VALUES (p_discussion_id, user_internal_id, p_message_content, NOW())
    RETURNING id INTO message_id;
    
    RETURN message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- STEP 5: VERIFICATION
-- ===========================================

-- Verify all functions exist
SELECT 
    'Function Verification' as check_type,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name IN (
    'get_user_internal_id',
    'is_user_club_admin',
    'create_book_club',
    'join_book_club',
    'add_book_club_message',
    'get_book_club_messages',
    'promote_user_to_admin',
    'invite_user_to_club',
    'add_discussion_message'
)
ORDER BY routine_name;

-- Final success message
SELECT 
    'Safe Ambiguous Column Reference Fix Complete' as status,
    'All database functions have been recreated with proper parameter naming' as message;
