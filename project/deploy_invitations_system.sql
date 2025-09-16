-- =====================================================
-- DEPLOY CLUB INVITATIONS SYSTEM
-- =====================================================
-- This script deploys the complete club invitations system
-- Run this in your Supabase SQL Editor

-- First, ensure the main Tailor Mates tables exist
-- (This should already be done, but we'll check)

-- Check if book_clubs table exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'book_clubs') THEN
        RAISE EXCEPTION 'book_clubs table not found. Please run the main Tailor Mates setup first.';
    END IF;
    
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'club_memberships') THEN
        RAISE EXCEPTION 'club_memberships table not found. Please run the main Tailor Mates setup first.';
    END IF;
    
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users') THEN
        RAISE EXCEPTION 'users table not found. Please ensure the main users table exists.';
    END IF;
END $$;

-- =====================================================
-- CREATE CLUB INVITATIONS TABLE
-- =====================================================

-- Club Invitations table
CREATE TABLE IF NOT EXISTS club_invitations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    club_id UUID NOT NULL REFERENCES book_clubs(id) ON DELETE CASCADE,
    inviter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    invitee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'cancelled')),
    message TEXT, -- Optional personal message from inviter
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),
    UNIQUE(club_id, invitee_id), -- Prevent duplicate invitations to same club
    CHECK (inviter_id != invitee_id) -- Can't invite yourself
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_club_invitations_club_id ON club_invitations(club_id);
CREATE INDEX IF NOT EXISTS idx_club_invitations_inviter_id ON club_invitations(inviter_id);
CREATE INDEX IF NOT EXISTS idx_club_invitations_invitee_id ON club_invitations(invitee_id);
CREATE INDEX IF NOT EXISTS idx_club_invitations_status ON club_invitations(status);
CREATE INDEX IF NOT EXISTS idx_club_invitations_expires_at ON club_invitations(expires_at);

-- Enable RLS
ALTER TABLE club_invitations ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- CREATE RLS POLICIES
-- =====================================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view invitations they sent or received" ON club_invitations;
DROP POLICY IF EXISTS "Club admins can create invitations" ON club_invitations;
DROP POLICY IF EXISTS "Users can update invitations they sent or received" ON club_invitations;
DROP POLICY IF EXISTS "Users can delete invitations they sent" ON club_invitations;

-- RLS Policies for club_invitations
CREATE POLICY "Users can view invitations they sent or received" ON club_invitations
    FOR SELECT USING (inviter_id = auth.uid()::uuid OR invitee_id = auth.uid()::uuid);

CREATE POLICY "Club admins can create invitations" ON club_invitations
    FOR INSERT WITH CHECK (
        inviter_id = auth.uid()::uuid AND
        EXISTS (
            SELECT 1 FROM club_memberships cm
            WHERE cm.club_id = club_invitations.club_id 
            AND cm.user_id = auth.uid()::uuid 
            AND cm.role IN ('owner', 'admin')
        )
    );

CREATE POLICY "Users can update invitations they sent or received" ON club_invitations
    FOR UPDATE USING (inviter_id = auth.uid()::uuid OR invitee_id = auth.uid()::uuid);

CREATE POLICY "Users can delete invitations they sent" ON club_invitations
    FOR DELETE USING (inviter_id = auth.uid()::uuid);

-- Add trigger for updated_at
DROP TRIGGER IF EXISTS update_club_invitations_updated_at ON club_invitations;
CREATE TRIGGER update_club_invitations_updated_at
    BEFORE UPDATE ON club_invitations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- CREATE INVITATION FUNCTIONS
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

-- Function to invite user to club by username
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
    -- Get inviter's user ID
    inviter_uuid := get_user_id_from_auth(auth_user_id);
    
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
    user_uuid := get_user_id_from_auth(auth_user_id);
    
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
    club_max_members INTEGER;
    result JSON;
BEGIN
    user_uuid := get_user_id_from_auth(auth_user_id);
    
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
    user_uuid := get_user_id_from_auth(auth_user_id);
    
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

-- Function to clean up expired invitations (can be run periodically)
CREATE OR REPLACE FUNCTION cleanup_expired_invitations()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM club_invitations
    WHERE status = 'pending' AND expires_at < NOW();
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

-- Grant execute permissions on functions to authenticated users
GRANT EXECUTE ON FUNCTION search_users_by_username TO authenticated;
GRANT EXECUTE ON FUNCTION invite_user_to_club TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_club_invitations TO authenticated;
GRANT EXECUTE ON FUNCTION respond_to_club_invitation TO authenticated;
GRANT EXECUTE ON FUNCTION get_club_sent_invitations TO authenticated;
GRANT EXECUTE ON FUNCTION cleanup_expired_invitations TO authenticated;

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '🎉 Club Invitations System deployed successfully!';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Created table: club_invitations';
    RAISE NOTICE '✅ Created indexes for optimal performance';
    RAISE NOTICE '✅ Enabled Row Level Security with appropriate policies';
    RAISE NOTICE '✅ Created functions:';
    RAISE NOTICE '   - search_users_by_username()';
    RAISE NOTICE '   - invite_user_to_club()';
    RAISE NOTICE '   - get_user_club_invitations()';
    RAISE NOTICE '   - respond_to_club_invitation()';
    RAISE NOTICE '   - get_club_sent_invitations()';
    RAISE NOTICE '   - cleanup_expired_invitations()';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 Club admins can now invite users by username!';
    RAISE NOTICE '📧 Users will see invitation notifications in Tailor Mates';
    RAISE NOTICE '⏰ Invitations expire after 7 days';
    RAISE NOTICE '';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '1. Test the invitation system in your app';
    RAISE NOTICE '2. Optionally set up a cron job to run cleanup_expired_invitations()';
END $$;
