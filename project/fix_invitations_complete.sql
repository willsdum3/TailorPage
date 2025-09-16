-- =====================================================
-- COMPLETE FIX FOR CLUB INVITATIONS SYSTEM
-- =====================================================
-- This script completely recreates all invitation functions without dependencies

-- First, let's drop all existing functions and policies to start fresh
DROP FUNCTION IF EXISTS invite_user_to_club(UUID, UUID, TEXT, TEXT);
DROP FUNCTION IF EXISTS get_user_club_invitations(UUID);
DROP FUNCTION IF EXISTS respond_to_club_invitation(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS get_club_sent_invitations(UUID, UUID);
DROP FUNCTION IF EXISTS search_users_by_username(TEXT, INTEGER);

-- Drop and recreate RLS policies
DROP POLICY IF EXISTS "Users can view invitations they sent or received" ON club_invitations;
DROP POLICY IF EXISTS "Club admins can create invitations" ON club_invitations;
DROP POLICY IF EXISTS "Users can update invitations they sent or received" ON club_invitations;
DROP POLICY IF EXISTS "Users can delete invitations they sent" ON club_invitations;

-- Recreate RLS policies with proper references
CREATE POLICY "Users can view invitations they sent or received" ON club_invitations
    FOR SELECT USING (
        inviter_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid()) OR 
        invitee_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid())
    );

CREATE POLICY "Club admins can create invitations" ON club_invitations
    FOR INSERT WITH CHECK (
        inviter_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid()) AND
        EXISTS (
            SELECT 1 FROM club_memberships cm
            JOIN users u ON cm.user_id = u.id
            WHERE cm.club_id = club_invitations.club_id 
            AND u.auth_user_id = auth.uid()
            AND cm.role IN ('owner', 'admin')
        )
    );

CREATE POLICY "Users can update invitations they sent or received" ON club_invitations
    FOR UPDATE USING (
        inviter_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid()) OR 
        invitee_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid())
    );

CREATE POLICY "Users can delete invitations they sent" ON club_invitations
    FOR DELETE USING (
        inviter_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid())
    );

-- =====================================================
-- RECREATE ALL FUNCTIONS WITHOUT DEPENDENCIES
-- =====================================================

-- Function to search users by username
CREATE OR REPLACE FUNCTION search_users_by_username(search_term TEXT, limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
    id UUID,
    username TEXT,
    name TEXT,
    avatar_url TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.username,
        u.name,
        u.avatar_url
    FROM users u
    WHERE 
        u.username ILIKE '%' || search_term || '%'
        AND u.username IS NOT NULL
        AND u.username != ''
    ORDER BY 
        CASE 
            WHEN u.username ILIKE search_term THEN 1  -- Exact match first
            WHEN u.username ILIKE search_term || '%' THEN 2  -- Starts with
            ELSE 3  -- Contains
        END,
        u.username
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to invite user to club by username (completely self-contained)
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
    club_name TEXT;
    is_admin BOOLEAN;
    is_already_member BOOLEAN;
    has_pending_invitation BOOLEAN;
    invitation_id UUID;
    result JSON;
BEGIN
    -- Get inviter's user ID directly from users table
    SELECT id INTO inviter_uuid
    FROM users
    WHERE auth_user_id = invite_user_to_club.auth_user_id;
    
    IF inviter_uuid IS NULL THEN
        RETURN json_build_object(
            'success', false, 
            'error', 'User not found in database. Please ensure you are properly signed in.'
        );
    END IF;
    
    -- Check if club exists and get name
    SELECT 
        CASE WHEN COUNT(*) > 0 THEN true ELSE false END,
        MAX(name)
    INTO club_exists, club_name
    FROM book_clubs 
    WHERE id = club_id_param;
    
    IF NOT club_exists THEN
        RETURN json_build_object('success', false, 'error', 'Club not found');
    END IF;
    
    -- Check if inviter is admin or owner of the club
    SELECT 
        CASE WHEN COUNT(*) > 0 THEN true ELSE false END
    INTO is_admin
    FROM club_memberships 
    WHERE club_id = club_id_param 
    AND user_id = inviter_uuid 
    AND role IN ('owner', 'admin');
    
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
    
    -- Prevent self-invitation
    IF inviter_uuid = invitee_uuid THEN
        RETURN json_build_object('success', false, 'error', 'You cannot invite yourself');
    END IF;
    
    -- Check if user is already a member
    SELECT 
        CASE WHEN COUNT(*) > 0 THEN true ELSE false END
    INTO is_already_member
    FROM club_memberships 
    WHERE club_id = club_id_param AND user_id = invitee_uuid;
    
    IF is_already_member THEN
        RETURN json_build_object('success', false, 'error', 'User is already a member of this club');
    END IF;
    
    -- Check if there's already a pending invitation
    SELECT 
        CASE WHEN COUNT(*) > 0 THEN true ELSE false END
    INTO has_pending_invitation
    FROM club_invitations 
    WHERE club_id = club_id_param 
    AND invitee_id = invitee_uuid 
    AND status = 'pending'
    AND expires_at > NOW();
    
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
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false, 
            'error', 'Database error: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get club invitations for a user
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
    -- Get user ID directly from users table
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

-- Function to respond to club invitation
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
    result JSON;
BEGIN
    -- Get user ID directly from users table
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
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false, 
            'error', 'Database error: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get sent invitations for a club admin
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
    -- Get user ID directly from users table
    SELECT u.id INTO user_uuid
    FROM users u
    WHERE u.auth_user_id = get_club_sent_invitations.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'User not found for auth_user_id: %', auth_user_id;
    END IF;
    
    -- Check if user is admin of the club
    SELECT 
        CASE WHEN COUNT(*) > 0 THEN true ELSE false END
    INTO is_admin
    FROM club_memberships 
    WHERE club_id = club_id_param 
    AND user_id = user_uuid 
    AND role IN ('owner', 'admin');
    
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

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION search_users_by_username TO authenticated;
GRANT EXECUTE ON FUNCTION invite_user_to_club TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_club_invitations TO authenticated;
GRANT EXECUTE ON FUNCTION respond_to_club_invitation TO authenticated;
GRANT EXECUTE ON FUNCTION get_club_sent_invitations TO authenticated;

-- =====================================================
-- TEST THE FUNCTIONS
-- =====================================================

-- Let's test if the functions work properly
DO $$
DECLARE
    test_result JSON;
BEGIN
    -- Test search function
    PERFORM search_users_by_username('test', 5);
    RAISE NOTICE '✅ search_users_by_username function works';
    
    RAISE NOTICE '✅ All invitation functions recreated successfully!';
    RAISE NOTICE 'The invitation system should now work without errors.';
END $$;
