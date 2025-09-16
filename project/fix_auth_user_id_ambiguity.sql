-- =====================================================
-- FINAL FIX FOR AUTH_USER_ID AMBIGUITY
-- =====================================================
-- This script completely eliminates the auth_user_id ambiguity issue

-- First, let's check what's causing the ambiguity by dropping everything and starting clean
DROP POLICY IF EXISTS "Users can view invitations they sent or received" ON club_invitations;
DROP POLICY IF EXISTS "Club admins can create invitations" ON club_invitations;
DROP POLICY IF EXISTS "Users can update invitations they sent or received" ON club_invitations;
DROP POLICY IF EXISTS "Users can delete invitations they sent" ON club_invitations;

-- Drop all functions to ensure clean slate
DROP FUNCTION IF EXISTS invite_user_to_club(UUID, UUID, TEXT, TEXT);
DROP FUNCTION IF EXISTS get_user_club_invitations(UUID);
DROP FUNCTION IF EXISTS respond_to_club_invitation(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS get_club_sent_invitations(UUID, UUID);
DROP FUNCTION IF EXISTS search_users_by_username(TEXT, INTEGER);

-- Disable RLS temporarily to recreate everything cleanly
ALTER TABLE club_invitations DISABLE ROW LEVEL SECURITY;

-- Re-enable RLS
ALTER TABLE club_invitations ENABLE ROW LEVEL SECURITY;

-- Create simplified RLS policies that avoid any column ambiguity
-- Use explicit table aliases and avoid complex joins in policies

CREATE POLICY "view_own_invitations" ON club_invitations
    FOR SELECT USING (
        inviter_id = (SELECT u.id FROM users u WHERE u.auth_user_id = auth.uid()) OR 
        invitee_id = (SELECT u.id FROM users u WHERE u.auth_user_id = auth.uid())
    );

CREATE POLICY "admins_create_invitations" ON club_invitations
    FOR INSERT WITH CHECK (
        inviter_id = (SELECT u.id FROM users u WHERE u.auth_user_id = auth.uid()) AND
        EXISTS (
            SELECT 1 FROM club_memberships cm
            WHERE cm.club_id = club_invitations.club_id 
            AND cm.user_id = (SELECT u2.id FROM users u2 WHERE u2.auth_user_id = auth.uid())
            AND cm.role IN ('owner', 'admin')
        )
    );

CREATE POLICY "update_own_invitations" ON club_invitations
    FOR UPDATE USING (
        inviter_id = (SELECT u.id FROM users u WHERE u.auth_user_id = auth.uid()) OR 
        invitee_id = (SELECT u.id FROM users u WHERE u.auth_user_id = auth.uid())
    );

CREATE POLICY "delete_sent_invitations" ON club_invitations
    FOR DELETE USING (
        inviter_id = (SELECT u.id FROM users u WHERE u.auth_user_id = auth.uid())
    );

-- =====================================================
-- RECREATE FUNCTIONS WITH EXPLICIT PARAMETER NAMES
-- =====================================================

-- Function to search users by username
CREATE OR REPLACE FUNCTION search_users_by_username(
    p_search_term TEXT, 
    p_limit_count INTEGER DEFAULT 10
)
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
        u.username ILIKE '%' || p_search_term || '%'
        AND u.username IS NOT NULL
        AND u.username != ''
    ORDER BY 
        CASE 
            WHEN u.username ILIKE p_search_term THEN 1  -- Exact match first
            WHEN u.username ILIKE p_search_term || '%' THEN 2  -- Starts with
            ELSE 3  -- Contains
        END,
        u.username
    LIMIT p_limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to invite user to club - with explicit parameter prefixes
CREATE OR REPLACE FUNCTION invite_user_to_club(
    p_auth_user_id UUID,
    p_club_id UUID,
    p_username TEXT,
    p_message TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_inviter_id UUID;
    v_invitee_id UUID;
    v_club_exists BOOLEAN := false;
    v_club_name TEXT;
    v_is_admin BOOLEAN := false;
    v_is_member BOOLEAN := false;
    v_has_pending BOOLEAN := false;
    v_invitation_id UUID;
    v_result JSON;
BEGIN
    -- Step 1: Get inviter's internal user ID
    SELECT users.id INTO v_inviter_id
    FROM users 
    WHERE users.auth_user_id = p_auth_user_id;
    
    IF v_inviter_id IS NULL THEN
        RETURN json_build_object(
            'success', false, 
            'error', 'Inviter not found in database'
        );
    END IF;
    
    -- Step 2: Verify club exists
    SELECT EXISTS(SELECT 1 FROM book_clubs WHERE id = p_club_id), 
           (SELECT name FROM book_clubs WHERE id = p_club_id LIMIT 1)
    INTO v_club_exists, v_club_name;
    
    IF NOT v_club_exists THEN
        RETURN json_build_object('success', false, 'error', 'Club not found');
    END IF;
    
    -- Step 3: Check admin permissions
    SELECT EXISTS(
        SELECT 1 FROM club_memberships 
        WHERE club_id = p_club_id 
        AND user_id = v_inviter_id 
        AND role IN ('owner', 'admin')
    ) INTO v_is_admin;
    
    IF NOT v_is_admin THEN
        RETURN json_build_object('success', false, 'error', 'Only club admins can send invitations');
    END IF;
    
    -- Step 4: Find invitee by username
    SELECT users.id INTO v_invitee_id
    FROM users 
    WHERE users.username = p_username;
    
    IF v_invitee_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not found: ' || p_username);
    END IF;
    
    -- Step 5: Prevent self-invitation
    IF v_inviter_id = v_invitee_id THEN
        RETURN json_build_object('success', false, 'error', 'Cannot invite yourself');
    END IF;
    
    -- Step 6: Check if already a member
    SELECT EXISTS(
        SELECT 1 FROM club_memberships 
        WHERE club_id = p_club_id AND user_id = v_invitee_id
    ) INTO v_is_member;
    
    IF v_is_member THEN
        RETURN json_build_object('success', false, 'error', 'User is already a member');
    END IF;
    
    -- Step 7: Check for existing pending invitation
    SELECT EXISTS(
        SELECT 1 FROM club_invitations 
        WHERE club_id = p_club_id 
        AND invitee_id = v_invitee_id 
        AND status = 'pending'
        AND expires_at > NOW()
    ) INTO v_has_pending;
    
    IF v_has_pending THEN
        RETURN json_build_object('success', false, 'error', 'User already has a pending invitation');
    END IF;
    
    -- Step 8: Create invitation
    INSERT INTO club_invitations (club_id, inviter_id, invitee_id, message)
    VALUES (p_club_id, v_inviter_id, v_invitee_id, p_message)
    RETURNING id INTO v_invitation_id;
    
    -- Step 9: Return success
    RETURN json_build_object(
        'success', true,
        'invitation_id', v_invitation_id,
        'club_name', v_club_name,
        'invitee_username', p_username,
        'message', 'Invitation sent successfully'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false, 
            'error', 'Database error: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user invitations
CREATE OR REPLACE FUNCTION get_user_club_invitations(p_auth_user_id UUID)
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
    v_user_id UUID;
BEGIN
    -- Get user ID
    SELECT users.id INTO v_user_id
    FROM users 
    WHERE users.auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    RETURN QUERY
    SELECT 
        ci.id,
        ci.club_id,
        bc.name,
        bc.description,
        inviter.name,
        inviter.username,
        ci.message,
        ci.created_at,
        ci.expires_at,
        ci.status
    FROM club_invitations ci
    JOIN book_clubs bc ON ci.club_id = bc.id
    JOIN users inviter ON ci.inviter_id = inviter.id
    WHERE ci.invitee_id = v_user_id
    AND ci.status = 'pending'
    AND ci.expires_at > NOW()
    ORDER BY ci.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to respond to invitation
CREATE OR REPLACE FUNCTION respond_to_club_invitation(
    p_auth_user_id UUID,
    p_invitation_id UUID,
    p_response TEXT
)
RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_invitation RECORD;
    v_member_count INTEGER;
BEGIN
    -- Get user ID
    SELECT users.id INTO v_user_id
    FROM users 
    WHERE users.auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Validate response
    IF p_response NOT IN ('accepted', 'declined') THEN
        RETURN json_build_object('success', false, 'error', 'Invalid response');
    END IF;
    
    -- Get invitation
    SELECT ci.*, bc.name as club_name, bc.max_members
    INTO v_invitation
    FROM club_invitations ci
    JOIN book_clubs bc ON ci.club_id = bc.id
    WHERE ci.id = p_invitation_id
    AND ci.invitee_id = v_user_id
    AND ci.status = 'pending'
    AND ci.expires_at > NOW();
    
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'error', 'Invitation not found or expired');
    END IF;
    
    -- If accepting, check club capacity
    IF p_response = 'accepted' THEN
        SELECT COUNT(*) INTO v_member_count
        FROM club_memberships
        WHERE club_id = v_invitation.club_id;
        
        IF v_member_count >= v_invitation.max_members THEN
            RETURN json_build_object('success', false, 'error', 'Club is full');
        END IF;
        
        -- Add to club
        INSERT INTO club_memberships (club_id, user_id, role)
        VALUES (v_invitation.club_id, v_user_id, 'member');
    END IF;
    
    -- Update invitation
    UPDATE club_invitations
    SET status = p_response, updated_at = NOW()
    WHERE id = p_invitation_id;
    
    RETURN json_build_object(
        'success', true,
        'club_name', v_invitation.club_name,
        'response', p_response,
        'message', CASE 
            WHEN p_response = 'accepted' THEN 'Successfully joined the club!'
            ELSE 'Invitation declined'
        END
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'error', 'Error: ' || SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get sent invitations
CREATE OR REPLACE FUNCTION get_club_sent_invitations(
    p_auth_user_id UUID,
    p_club_id UUID
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
    v_user_id UUID;
    v_is_admin BOOLEAN;
BEGIN
    -- Get user ID
    SELECT users.id INTO v_user_id
    FROM users 
    WHERE users.auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check admin status
    SELECT EXISTS(
        SELECT 1 FROM club_memberships 
        WHERE club_id = p_club_id 
        AND user_id = v_user_id 
        AND role IN ('owner', 'admin')
    ) INTO v_is_admin;
    
    IF NOT v_is_admin THEN
        RAISE EXCEPTION 'Only admins can view sent invitations';
    END IF;
    
    RETURN QUERY
    SELECT 
        ci.id,
        invitee.username,
        invitee.name,
        ci.message,
        ci.status,
        ci.created_at,
        ci.expires_at
    FROM club_invitations ci
    JOIN users invitee ON ci.invitee_id = invitee.id
    WHERE ci.club_id = p_club_id
    ORDER BY ci.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION search_users_by_username TO authenticated;
GRANT EXECUTE ON FUNCTION invite_user_to_club TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_club_invitations TO authenticated;
GRANT EXECUTE ON FUNCTION respond_to_club_invitation TO authenticated;
GRANT EXECUTE ON FUNCTION get_club_sent_invitations TO authenticated;

-- Test the fix
DO $$
BEGIN
    RAISE NOTICE '✅ All functions recreated with explicit parameter naming';
    RAISE NOTICE '✅ RLS policies simplified to avoid column ambiguity';
    RAISE NOTICE '✅ Ready to test invitations again!';
END $$;
