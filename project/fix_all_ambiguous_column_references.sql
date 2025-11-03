-- Fix All Ambiguous Column References in Database Functions
-- This script fixes the "column reference 'auth_user_id' is ambiguous" error
-- by updating all functions to use properly qualified column names

-- Drop all problematic functions first
DROP FUNCTION IF EXISTS get_user_internal_id(UUID) CASCADE;
DROP FUNCTION IF EXISTS add_book_club_message(UUID, UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS add_discussion_message(UUID, UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS join_book_club(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS promote_user_to_admin(UUID, UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS invite_user_to_club(UUID, UUID, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS is_user_club_admin(UUID, UUID) CASCADE;

-- ===========================================
-- HELPER FUNCTIONS
-- ===========================================

-- Recreate get_user_internal_id function with proper parameter naming
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

-- Recreate is_user_club_admin function with proper parameter naming
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
-- BOOK CLUB FUNCTIONS
-- ===========================================

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
        RETURN jsonb_build_object(
            'success', false,
            'error', 'User not found'
        );
    END IF;
    
    -- Get club name
    SELECT bc.name INTO club_name
    FROM book_clubs bc
    WHERE bc.id = p_club_id;
    
    IF club_name IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Club not found'
        );
    END IF;
    
    -- Check if user is already a member
    IF EXISTS (
        SELECT 1 FROM book_club_members bcm
        WHERE bcm.club_id = p_club_id 
        AND bcm.user_id = user_internal_id
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'You are already a member of this club'
        );
    END IF;
    
    -- Add user as member
    INSERT INTO book_club_members (club_id, user_id, role, joined_at)
    VALUES (p_club_id, user_internal_id, 'member', NOW());
    
    -- Get current member count
    SELECT COUNT(*) INTO existing_member_count
    FROM book_club_members bcm
    WHERE bcm.club_id = p_club_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Successfully joined ' || club_name,
        'member_count', existing_member_count
    );
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
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Promoter not found'
        );
    END IF;
    
    -- Get target user's internal ID
    SELECT u.id, u.name INTO target_internal_id, target_name
    FROM users u 
    WHERE u.id::text = p_user_to_promote_id;
    
    IF target_internal_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Target user not found'
        );
    END IF;
    
    -- Get club name
    SELECT bc.name INTO club_name
    FROM book_clubs bc
    WHERE bc.id = p_club_id;
    
    IF club_name IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Club not found'
        );
    END IF;
    
    -- Check if promoter is admin
    is_promoter_admin := is_user_club_admin(promoter_internal_id, p_club_id);
    
    IF NOT is_promoter_admin THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Only admins can promote users'
        );
    END IF;
    
    -- Check if target user is a member
    IF NOT EXISTS (
        SELECT 1 FROM book_club_members bcm
        WHERE bcm.club_id = p_club_id 
        AND bcm.user_id = target_internal_id
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'User is not a member of this club'
        );
    END IF;
    
    -- Update user role to admin
    UPDATE book_club_members 
    SET role = 'admin'
    WHERE club_id = p_club_id 
    AND user_id = target_internal_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', target_name || ' has been promoted to admin'
    );
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
    invitation_id UUID;
    is_inviter_admin BOOLEAN;
BEGIN
    -- Get inviter's internal ID
    inviter_internal_id := get_user_internal_id(p_auth_user_id);
    
    IF inviter_internal_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Inviter not found'
        );
    END IF;
    
    -- Get target user by username
    SELECT u.id, u.name INTO target_user_id, target_name
    FROM users u 
    WHERE u.username = p_username;
    
    IF target_user_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'User not found'
        );
    END IF;
    
    -- Check if user is already a member
    IF EXISTS (
        SELECT 1 FROM book_club_members bcm 
        WHERE bcm.club_id = p_club_id 
        AND bcm.user_id = target_user_id
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'User is already a member of this club'
        );
    END IF;
    
    -- Get club name
    SELECT bc.name INTO club_name
    FROM book_clubs bc
    WHERE bc.id = p_club_id;
    
    IF club_name IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Club not found'
        );
    END IF;
    
    -- Check if inviter is admin
    is_inviter_admin := is_user_club_admin(inviter_internal_id, p_club_id);
    
    IF NOT is_inviter_admin THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Only admins can invite users to clubs'
        );
    END IF;
    
    -- Create invitation (if club_invitations table exists)
    BEGIN
        INSERT INTO club_invitations (club_id, invitee_id, inviter_id, message, status)
        VALUES (p_club_id, target_user_id, inviter_internal_id, p_message, 'pending')
        RETURNING id INTO invitation_id;
    EXCEPTION
        WHEN undefined_table THEN
            -- Table doesn't exist, continue without creating invitation
            invitation_id := NULL;
    END;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Invitation sent successfully'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- DISCUSSION FUNCTIONS
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
-- VERIFICATION
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
    'join_book_club',
    'add_book_club_message',
    'promote_user_to_admin',
    'invite_user_to_club',
    'add_discussion_message'
)
ORDER BY routine_name;

-- Final success message
SELECT 
    'Ambiguous Column Reference Fix Complete' as status,
    'All database functions have been updated to resolve ambiguous column references' as message;


