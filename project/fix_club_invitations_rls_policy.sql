-- =====================================================
-- FIX CLUB INVITATIONS RLS POLICY
-- =====================================================
-- This script fixes the ambiguous column reference error in the RLS policy

-- Drop the problematic policy
DROP POLICY IF EXISTS "Club admins can create invitations" ON club_invitations;

-- Create the corrected policy with proper table references
CREATE POLICY "Club admins can create invitations" ON club_invitations
    FOR INSERT WITH CHECK (
        inviter_id = auth.uid()::uuid AND
        EXISTS (
            SELECT 1 FROM club_memberships cm
            JOIN users u ON cm.user_id = u.id
            WHERE cm.club_id = club_invitations.club_id 
            AND u.auth_user_id = auth.uid()::uuid 
            AND cm.role IN ('owner', 'admin')
        )
    );

-- Also fix the function to use proper user ID resolution
CREATE OR REPLACE FUNCTION invite_user_to_club(
    auth_user_id UUID,
    club_id_param UUID,
    username_param TEXT,
    message_param TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    inviter_uuid UUID;
    invitee_uuid UUID;
    club_exists BOOLEAN;
    is_admin BOOLEAN;
    is_already_member BOOLEAN;
    has_pending_invitation BOOLEAN;
    club_name TEXT;
    invitation_id UUID;
    result JSON;
BEGIN
    -- Get inviter's user ID from users table using auth_user_id
    SELECT id INTO inviter_uuid
    FROM users
    WHERE auth_user_id = invite_user_to_club.auth_user_id;
    
    IF inviter_uuid IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not found in database. Please ensure you are properly signed in.');
    END IF;
    
    -- Check if club exists and get name
    SELECT EXISTS(SELECT 1 FROM book_clubs WHERE id = club_id_param), name
    INTO club_exists, club_name
    FROM book_clubs 
    WHERE id = club_id_param;
    
    IF NOT club_exists THEN
        RETURN json_build_object('success', false, 'error', 'Club not found');
    END IF;
    
    -- Check if inviter is admin or owner of the club
    SELECT EXISTS(
        SELECT 1 FROM club_memberships 
        WHERE club_id = club_id_param 
        AND user_id = inviter_uuid 
        AND role IN ('owner', 'admin')
    ) INTO is_admin;
    
    IF NOT is_admin THEN
        RETURN json_build_object('success', false, 'error', 'Only club admins can send invitations');
    END IF;
    
    -- Find user by username
    SELECT id INTO invitee_uuid
    FROM users
    WHERE username = username_param;
    
    IF invitee_uuid IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not found with username: ' || username_param);
    END IF;
    
    -- Check if user is already a member
    SELECT EXISTS(
        SELECT 1 FROM club_memberships 
        WHERE club_id = club_id_param AND user_id = invitee_uuid
    ) INTO is_already_member;
    
    IF is_already_member THEN
        RETURN json_build_object('success', false, 'error', 'User is already a member of this club');
    END IF;
    
    -- Check if there's already a pending invitation
    SELECT EXISTS(
        SELECT 1 FROM club_invitations 
        WHERE club_id = club_id_param 
        AND invitee_id = invitee_uuid 
        AND status = 'pending'
        AND expires_at > NOW()
    ) INTO has_pending_invitation;
    
    IF has_pending_invitation THEN
        RETURN json_build_object('success', false, 'error', 'User already has a pending invitation to this club');
    END IF;
    
    -- Create the invitation
    INSERT INTO club_invitations (club_id, inviter_id, invitee_id, message)
    VALUES (club_id_param, inviter_uuid, invitee_uuid, message_param)
    RETURNING id INTO invitation_id;
    
    -- Return success with details
    result := json_build_object(
        'success', true,
        'invitation_id', invitation_id,
        'club_name', club_name,
        'invitee_username', username_param,
        'message', 'Invitation sent successfully'
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Also fix the other functions to use direct user ID resolution
CREATE OR REPLACE FUNCTION get_user_club_invitations(auth_user_id UUID)
RETURNS TABLE (
    id UUID,
    club_id UUID,
    club_name TEXT,
    club_description TEXT,
    inviter_name TEXT,
    inviter_username TEXT,
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    status TEXT
) AS $$
DECLARE
    user_uuid UUID;
BEGIN
    -- Get user ID from users table using auth_user_id
    SELECT u.id INTO user_uuid
    FROM users u
    WHERE u.auth_user_id = get_user_club_invitations.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'User not found for auth_user_id: %', auth_user_id;
    END IF;
    
    RETURN QUERY
    SELECT 
        ci.id,
        ci.club_id,
        bc.name as club_name,
        bc.description as club_description,
        u.name as inviter_name,
        u.username as inviter_username,
        ci.message,
        ci.created_at,
        ci.expires_at,
        ci.status
    FROM club_invitations ci
    JOIN book_clubs bc ON ci.club_id = bc.id
    JOIN users u ON ci.inviter_id = u.id
    WHERE ci.invitee_id = user_uuid
    AND ci.status = 'pending'
    AND ci.expires_at > NOW()
    ORDER BY ci.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION respond_to_club_invitation(
    auth_user_id UUID,
    invitation_id_param UUID,
    response TEXT -- 'accepted' or 'declined'
)
RETURNS JSON AS $$
DECLARE
    user_uuid UUID;
    invitation_record RECORD;
    club_member_count INTEGER;
    club_max_members INTEGER;
    result JSON;
BEGIN
    -- Get user ID from users table using auth_user_id
    SELECT u.id INTO user_uuid
    FROM users u
    WHERE u.auth_user_id = respond_to_club_invitation.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not found in database');
    END IF;
    
    -- Validate response
    IF response NOT IN ('accepted', 'declined') THEN
        RETURN json_build_object('success', false, 'error', 'Invalid response. Must be accepted or declined');
    END IF;
    
    -- Get invitation details
    SELECT ci.*, bc.name as club_name, bc.max_members
    INTO invitation_record
    FROM club_invitations ci
    JOIN book_clubs bc ON ci.club_id = bc.id
    WHERE ci.id = invitation_id_param
    AND ci.invitee_id = user_uuid
    AND ci.status = 'pending'
    AND ci.expires_at > NOW();
    
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'error', 'Invitation not found or expired');
    END IF;
    
    -- If accepting, check if club has space
    IF response = 'accepted' THEN
        SELECT COUNT(*) INTO club_member_count
        FROM club_memberships
        WHERE club_id = invitation_record.club_id;
        
        IF club_member_count >= invitation_record.max_members THEN
            RETURN json_build_object('success', false, 'error', 'Club is full');
        END IF;
        
        -- Add user to club
        INSERT INTO club_memberships (club_id, user_id, role)
        VALUES (invitation_record.club_id, user_uuid, 'member');
    END IF;
    
    -- Update invitation status
    UPDATE club_invitations
    SET status = response, updated_at = NOW()
    WHERE id = invitation_id_param;
    
    result := json_build_object(
        'success', true,
        'club_name', invitation_record.club_name,
        'response', response,
        'message', CASE 
            WHEN response = 'accepted' THEN 'Successfully joined the club!'
            ELSE 'Invitation declined'
        END
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_club_sent_invitations(
    auth_user_id UUID,
    club_id_param UUID
)
RETURNS TABLE (
    id UUID,
    invitee_username TEXT,
    invitee_name TEXT,
    message TEXT,
    status TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    user_uuid UUID;
    is_admin BOOLEAN;
BEGIN
    -- Get user ID from users table using auth_user_id
    SELECT u.id INTO user_uuid
    FROM users u
    WHERE u.auth_user_id = get_club_sent_invitations.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'User not found for auth_user_id: %', auth_user_id;
    END IF;
    
    -- Check if user is admin of the club
    SELECT EXISTS(
        SELECT 1 FROM club_memberships 
        WHERE club_id = club_id_param 
        AND user_id = user_uuid 
        AND role IN ('owner', 'admin')
    ) INTO is_admin;
    
    IF NOT is_admin THEN
        RAISE EXCEPTION 'Only club admins can view sent invitations';
    END IF;
    
    RETURN QUERY
    SELECT 
        ci.id,
        u.username as invitee_username,
        u.name as invitee_name,
        ci.message,
        ci.status,
        ci.created_at,
        ci.expires_at
    FROM club_invitations ci
    JOIN users u ON ci.invitee_id = u.id
    WHERE ci.club_id = club_id_param
    ORDER BY ci.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Club invitations RLS policy and functions fixed!';
    RAISE NOTICE 'The ambiguous column reference error should now be resolved.';
    RAISE NOTICE 'You can now try sending invitations again.';
END $$;
