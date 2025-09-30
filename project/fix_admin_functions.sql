-- Fix all admin functions for book clubs
-- This addresses: promote users to admin, invite users to clubs, delete book clubs

-- First, let's check which functions exist
SELECT 
    'Function Existence Check' as check_type,
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name IN ('promote_user_to_admin', 'invite_user_to_club', 'delete_book_club')
ORDER BY routine_name;

-- 1. Fix promote_user_to_admin function
-- Drop existing function
DROP FUNCTION IF EXISTS promote_user_to_admin(UUID, UUID, UUID);

-- Create the function with correct parameters
CREATE OR REPLACE FUNCTION promote_user_to_admin(
    auth_user_id UUID,
    club_id_param UUID,
    user_to_promote_id UUID
)
RETURNS JSON AS $$
DECLARE
    admin_internal_id UUID;
    user_to_promote_internal_id UUID;
    is_admin BOOLEAN;
    result JSON;
BEGIN
    -- Get the internal user ID of the admin
    SELECT id INTO admin_internal_id
    FROM users
    WHERE users.auth_user_id = promote_user_to_admin.auth_user_id;
    
    IF admin_internal_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Admin user not found');
    END IF;
    
    -- Get the internal user ID of the user to promote
    SELECT id INTO user_to_promote_internal_id
    FROM users
    WHERE users.id = promote_user_to_admin.user_to_promote_id;
    
    IF user_to_promote_internal_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User to promote not found');
    END IF;
    
    -- Check if the admin is actually an admin of the club
    SELECT EXISTS (
        SELECT 1 FROM book_club_members 
        WHERE book_club_members.user_id = admin_internal_id 
        AND book_club_members.club_id = promote_user_to_admin.club_id_param
        AND book_club_members.role IN ('admin', 'owner')
    ) INTO is_admin;
    
    IF NOT is_admin THEN
        RETURN json_build_object('success', false, 'error', 'You are not an admin of this club');
    END IF;
    
    -- Check if the user to promote is a member of the club
    IF NOT EXISTS (
        SELECT 1 FROM book_club_members 
        WHERE book_club_members.user_id = user_to_promote_internal_id 
        AND book_club_members.club_id = promote_user_to_admin.club_id_param
    ) THEN
        RETURN json_build_object('success', false, 'error', 'User is not a member of this club');
    END IF;
    
    -- Promote the user to admin
    UPDATE book_club_members 
    SET role = 'admin'
    WHERE book_club_members.user_id = user_to_promote_internal_id 
    AND book_club_members.club_id = promote_user_to_admin.club_id_param;
    
    RETURN json_build_object('success', true, 'message', 'User promoted to admin successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Fix invite_user_to_club function
-- Drop existing function
DROP FUNCTION IF EXISTS invite_user_to_club(UUID, UUID, TEXT, TEXT);

-- Create the function with correct parameters
CREATE OR REPLACE FUNCTION invite_user_to_club(
    auth_user_id UUID,
    club_id_param UUID,
    username_param TEXT,
    message_param TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    admin_internal_id UUID;
    invitee_internal_id UUID;
    is_admin BOOLEAN;
    invitation_exists BOOLEAN;
    result JSON;
BEGIN
    -- Get the internal user ID of the admin
    SELECT id INTO admin_internal_id
    FROM users
    WHERE users.auth_user_id = invite_user_to_club.auth_user_id;
    
    IF admin_internal_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Admin user not found');
    END IF;
    
    -- Get the internal user ID of the user to invite
    SELECT id INTO invitee_internal_id
    FROM users
    WHERE users.username = invite_user_to_club.username_param;
    
    IF invitee_internal_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Check if the admin is actually an admin of the club
    SELECT EXISTS (
        SELECT 1 FROM book_club_members 
        WHERE book_club_members.user_id = admin_internal_id 
        AND book_club_members.club_id = invite_user_to_club.club_id_param
        AND book_club_members.role IN ('admin', 'owner')
    ) INTO is_admin;
    
    IF NOT is_admin THEN
        RETURN json_build_object('success', false, 'error', 'You are not an admin of this club');
    END IF;
    
    -- Check if the user is already a member
    IF EXISTS (
        SELECT 1 FROM book_club_members 
        WHERE book_club_members.user_id = invitee_internal_id 
        AND book_club_members.club_id = invite_user_to_club.club_id_param
    ) THEN
        RETURN json_build_object('success', false, 'error', 'User is already a member of this club');
    END IF;
    
    -- Check if there's already a pending invitation
    SELECT EXISTS (
        SELECT 1 FROM club_invitations 
        WHERE club_invitations.invitee_id = invitee_internal_id 
        AND club_invitations.club_id = invite_user_to_club.club_id_param
        AND club_invitations.status = 'pending'
    ) INTO invitation_exists;
    
    IF invitation_exists THEN
        RETURN json_build_object('success', false, 'error', 'User already has a pending invitation');
    END IF;
    
    -- Create the invitation
    INSERT INTO club_invitations (
        club_id,
        inviter_id,
        invitee_id,
        message,
        status,
        expires_at
    ) VALUES (
        invite_user_to_club.club_id_param,
        admin_internal_id,
        invitee_internal_id,
        message_param,
        'pending',
        NOW() + INTERVAL '7 days'
    );
    
    RETURN json_build_object('success', true, 'message', 'Invitation sent successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Fix delete_book_club function
-- Drop existing function
DROP FUNCTION IF EXISTS delete_book_club(UUID, UUID);

-- Create the function with correct parameters
CREATE OR REPLACE FUNCTION delete_book_club(
    p_auth_user_id UUID,
    p_book_club_id UUID
)
RETURNS JSON AS $$
DECLARE
    admin_internal_id UUID;
    is_admin BOOLEAN;
    result JSON;
BEGIN
    -- Get the internal user ID of the admin
    SELECT id INTO admin_internal_id
    FROM users
    WHERE users.auth_user_id = delete_book_club.p_auth_user_id;
    
    IF admin_internal_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Check if the user is an admin of the club
    SELECT EXISTS (
        SELECT 1 FROM book_club_members 
        WHERE book_club_members.user_id = admin_internal_id 
        AND book_club_members.club_id = delete_book_club.p_book_club_id
        AND book_club_members.role IN ('admin', 'owner')
    ) INTO is_admin;
    
    IF NOT is_admin THEN
        RETURN json_build_object('success', false, 'error', 'You are not an admin of this club');
    END IF;
    
    -- Delete the book club (cascade will handle related records)
    DELETE FROM book_clubs 
    WHERE book_clubs.id = delete_book_club.p_book_club_id;
    
    RETURN json_build_object('success', true, 'message', 'Book club deleted successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the functions
-- Test promote_user_to_admin (this will fail if user is not a member)
SELECT 
    'Test promote_user_to_admin Function' as check_type,
    promote_user_to_admin(
        'ca692e7f-6522-4295-86cd-592d7fd754b5'::UUID,  -- Tracey Beaker's auth_user_id (admin)
        'b2391fc3-cd68-472d-a9a8-10c4353af145'::UUID,  -- yjgbbu club ID
        (SELECT id FROM users WHERE username = 'hereistand')  -- William Dumbili's internal ID
    ) as result;

-- Test invite_user_to_club
SELECT 
    'Test invite_user_to_club Function' as check_type,
    invite_user_to_club(
        'ca692e7f-6522-4295-86cd-592d7fd754b5'::UUID,  -- Tracey Beaker's auth_user_id (admin)
        'b2391fc3-cd68-472d-a9a8-10c4353af145'::UUID,  -- yjgbbu club ID
        'paulinedumbili6',  -- Pauline's username
        'Welcome to our book club!'
    ) as result;

-- Test delete_book_club (this will fail if user is not admin)
SELECT 
    'Test delete_book_club Function' as check_type,
    delete_book_club(
        'ca692e7f-6522-4295-86cd-592d7fd754b5'::UUID,  -- Tracey Beaker's auth_user_id (admin)
        'b2391fc3-cd68-472d-a9a8-10c4353af145'::UUID   -- yjgbbu club ID
    ) as result;
