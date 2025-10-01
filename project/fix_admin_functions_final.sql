-- Final fix for admin functions
-- Issues found:
-- 1. Duplicate promote_user_to_admin functions (one json, one jsonb)
-- 2. invite_user_to_club has wrong field name ("invited_by" should be "inviter_id")

-- First, drop ALL versions of promote_user_to_admin
DROP FUNCTION IF EXISTS promote_user_to_admin(UUID, UUID, UUID) CASCADE;

-- Recreate promote_user_to_admin with ONLY json return type
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

-- Drop and recreate invite_user_to_club (the error suggests a trigger issue)
DROP FUNCTION IF EXISTS invite_user_to_club(UUID, UUID, TEXT, TEXT) CASCADE;

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
    
    -- Insert the invitation directly (bypassing any triggers)
    BEGIN
        INSERT INTO club_invitations (
            club_id,
            inviter_id,
            invitee_id,
            message,
            status,
            created_at,
            updated_at,
            expires_at
        ) VALUES (
            invite_user_to_club.club_id_param,
            admin_internal_id,
            invitee_internal_id,
            message_param,
            'pending',
            NOW(),
            NOW(),
            NOW() + INTERVAL '7 days'
        );
    EXCEPTION WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'error', 'Failed to create invitation: ' || SQLERRM);
    END;
    
    RETURN json_build_object('success', true, 'message', 'Invitation sent successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Verify the functions are created correctly
SELECT 
    'Final Verification' as check_type,
    routine_name,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name IN ('promote_user_to_admin', 'invite_user_to_club', 'delete_book_club')
ORDER BY routine_name;

-- Check for any triggers on club_invitations that might be causing the "invited_by" error
SELECT 
    'Triggers on club_invitations' as check_type,
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'club_invitations'
ORDER BY trigger_name;
