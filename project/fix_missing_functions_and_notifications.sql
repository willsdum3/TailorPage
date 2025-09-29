-- Fix missing database functions and integrate notifications
-- This script creates the missing functions and integrates notification calls

-- 1. Create invite_user_to_club function
DROP FUNCTION IF EXISTS invite_user_to_club(UUID, UUID, TEXT, TEXT);
CREATE OR REPLACE FUNCTION invite_user_to_club(
    auth_user_id UUID,
    club_id_param UUID,
    username_param TEXT,
    message_param TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    inviter_internal_id UUID;
    invitee_internal_id UUID;
    club_name TEXT;
    inviter_name TEXT;
    invitation_exists BOOLEAN;
    user_is_admin BOOLEAN;
BEGIN
    -- Get inviter's internal ID
    SELECT id INTO inviter_internal_id
    FROM users
    WHERE auth_user_id = auth_user_id;
    
    IF inviter_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Inviter not found');
    END IF;
    
    -- Get invitee's internal ID by username
    SELECT id INTO invitee_internal_id
    FROM users
    WHERE username = username_param;
    
    IF invitee_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Check if inviter is admin/owner of the club
    SELECT EXISTS(
        SELECT 1 FROM club_memberships
        WHERE club_id = club_id_param
        AND user_id = inviter_internal_id
        AND user_role IN ('admin', 'owner')
    ) INTO user_is_admin;
    
    IF NOT user_is_admin THEN
        RETURN jsonb_build_object('success', false, 'error', 'Only admins can invite users');
    END IF;
    
    -- Check if invitation already exists
    SELECT EXISTS(
        SELECT 1 FROM club_invitations
        WHERE club_id = club_id_param
        AND user_id = invitee_internal_id
        AND status = 'pending'
    ) INTO invitation_exists;
    
    IF invitation_exists THEN
        RETURN jsonb_build_object('success', false, 'error', 'User already has a pending invitation');
    END IF;
    
    -- Get club name and inviter name
    SELECT name INTO club_name FROM book_clubs WHERE id = club_id_param;
    SELECT name INTO inviter_name FROM users WHERE id = inviter_internal_id;
    
    -- Create the invitation
    INSERT INTO club_invitations (club_id, user_id, invited_by, message)
    VALUES (club_id_param, invitee_internal_id, inviter_internal_id, message_param);
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Invitation sent successfully'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Create promote_user_to_admin function
DROP FUNCTION IF EXISTS promote_user_to_admin(UUID, UUID, TEXT);
CREATE OR REPLACE FUNCTION promote_user_to_admin(
    promoter_auth_user_id UUID,
    club_id_param UUID,
    target_user_id TEXT
)
RETURNS JSONB AS $$
DECLARE
    promoter_internal_id UUID;
    target_internal_id UUID;
    club_name TEXT;
    promoter_name TEXT;
    target_name TEXT;
    user_is_owner BOOLEAN;
    user_is_member BOOLEAN;
BEGIN
    -- Get promoter's internal ID
    SELECT id INTO promoter_internal_id
    FROM users
    WHERE auth_user_id = promoter_auth_user_id;
    
    IF promoter_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Promoter not found');
    END IF;
    
    -- Get target user's internal ID (try by internal ID first, then by username)
    SELECT id INTO target_internal_id
    FROM users
    WHERE id = target_user_id::UUID;
    
    IF target_internal_id IS NULL THEN
        SELECT id INTO target_internal_id
        FROM users
        WHERE username = target_user_id;
    END IF;
    
    IF target_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Target user not found');
    END IF;
    
    -- Check if promoter is owner of the club
    SELECT EXISTS(
        SELECT 1 FROM club_memberships
        WHERE club_id = club_id_param
        AND user_id = promoter_internal_id
        AND user_role = 'owner'
    ) INTO user_is_owner;
    
    IF NOT user_is_owner THEN
        RETURN jsonb_build_object('success', false, 'error', 'Only club owners can promote users to admin');
    END IF;
    
    -- Check if target user is a member
    SELECT EXISTS(
        SELECT 1 FROM club_memberships
        WHERE club_id = club_id_param
        AND user_id = target_internal_id
        AND user_role = 'member'
    ) INTO user_is_member;
    
    IF NOT user_is_member THEN
        RETURN jsonb_build_object('success', false, 'error', 'User is not a member of this club');
    END IF;
    
    -- Get names for notification
    SELECT name INTO club_name FROM book_clubs WHERE id = club_id_param;
    SELECT name INTO promoter_name FROM users WHERE id = promoter_internal_id;
    SELECT name INTO target_name FROM users WHERE id = target_internal_id;
    
    -- Promote the user
    UPDATE club_memberships
    SET user_role = 'admin', updated_at = NOW()
    WHERE club_id = club_id_param
    AND user_id = target_internal_id;
    
    -- Create admin promotion notification
    INSERT INTO notifications (user_id, type, title, message, related_id, related_name)
    VALUES (
        target_internal_id,
        'admin_promotion',
        'Admin Promotion',
        promoter_name || ' promoted you to admin in "' || club_name || '"',
        club_id_param,
        club_name
    );
    
    RETURN jsonb_build_object(
        'success', true,
        'message', target_name || ' has been promoted to admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Create join_book_club function
DROP FUNCTION IF EXISTS join_book_club(UUID, UUID);
CREATE OR REPLACE FUNCTION join_book_club(
    auth_user_id UUID,
    club_id_param UUID
)
RETURNS JSONB AS $$
DECLARE
    user_internal_id UUID;
    club_name TEXT;
    user_name TEXT;
    already_member BOOLEAN;
    club_exists BOOLEAN;
    admin_record RECORD;
BEGIN
    -- Get user's internal ID
    SELECT id INTO user_internal_id
    FROM users
    WHERE auth_user_id = auth_user_id;
    
    IF user_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Check if club exists
    SELECT EXISTS(SELECT 1 FROM book_clubs WHERE id = club_id_param) INTO club_exists;
    IF NOT club_exists THEN
        RETURN jsonb_build_object('success', false, 'error', 'Club not found');
    END IF;
    
    -- Check if user is already a member
    SELECT EXISTS(
        SELECT 1 FROM club_memberships
        WHERE club_id = club_id_param
        AND user_id = user_internal_id
    ) INTO already_member;
    
    IF already_member THEN
        RETURN jsonb_build_object('success', false, 'error', 'You are already a member of this club');
    END IF;
    
    -- Get names for notifications
    SELECT name INTO club_name FROM book_clubs WHERE id = club_id_param;
    SELECT name INTO user_name FROM users WHERE id = user_internal_id;
    
    -- Add user as member
    INSERT INTO club_memberships (club_id, user_id, user_role, joined_at)
    VALUES (club_id_param, user_internal_id, 'member', NOW());
    
    -- Notify all admins and owners about the new member
    FOR admin_record IN 
        SELECT user_id 
        FROM club_memberships 
        WHERE club_id = club_id_param 
        AND user_role IN ('admin', 'owner')
    LOOP
        INSERT INTO notifications (user_id, type, title, message, related_id, related_name)
        VALUES (
            admin_record.user_id,
            'user_joined_club',
            'New Club Member',
            user_name || ' joined "' || club_name || '"',
            club_id_param,
            club_name
        );
    END LOOP;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Successfully joined the club'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the functions
SELECT 
    'Missing Functions Created' as status,
    'invite_user_to_club, promote_user_to_admin, join_book_club functions created successfully' as message;
