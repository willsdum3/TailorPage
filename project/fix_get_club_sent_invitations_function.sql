-- Recreate get_club_sent_invitations so admins can view invitations they have sent
-- Frontend expects parameters: p_auth_user_id, p_club_id

-- Ensure club_invitations table has the columns our functions rely on
ALTER TABLE club_invitations
    ADD COLUMN IF NOT EXISTS responded_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ;

-- Set sensible defaults for existing rows
UPDATE club_invitations
SET 
    expires_at = COALESCE(expires_at, created_at + INTERVAL '7 days'),
    updated_at = COALESCE(updated_at, created_at)
WHERE expires_at IS NULL OR updated_at IS NULL;

-- Make sure future inserts populate default timestamps
ALTER TABLE club_invitations
    ALTER COLUMN expires_at SET DEFAULT NOW() + INTERVAL '7 days',
    ALTER COLUMN updated_at SET DEFAULT NOW();

DROP FUNCTION IF EXISTS get_club_sent_invitations(UUID, UUID);
DROP FUNCTION IF EXISTS respond_to_club_invitation(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS accept_club_invitation(UUID, UUID);

CREATE OR REPLACE FUNCTION get_club_sent_invitations(
    p_auth_user_id UUID,
    p_club_id UUID
)
RETURNS TABLE (
    id UUID,
    club_id UUID,
    club_name TEXT,
    invitee_id UUID,
    invitee_name TEXT,
    invitee_username TEXT,
    invitee_email TEXT,
    invitee_avatar_url TEXT,
    status TEXT,
    message TEXT,
    created_at TIMESTAMPTZ,
    responded_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ
) AS $$
DECLARE
    v_requester_internal_id UUID;
    v_is_admin BOOLEAN;
BEGIN
    -- Resolve the requester's internal user ID
    v_requester_internal_id := get_user_internal_id(p_auth_user_id);

    -- If the user does not exist, return no rows
    IF v_requester_internal_id IS NULL THEN
        RETURN;
    END IF;

    -- Ensure the requester is an admin/owner of the club
    SELECT EXISTS (
        SELECT 1
        FROM book_club_members bcm
        WHERE bcm.club_id = p_club_id
          AND bcm.user_id = v_requester_internal_id
          AND bcm.role IN ('owner', 'admin')
    ) INTO v_is_admin;

    IF NOT v_is_admin THEN
        RETURN;
    END IF;

    -- Return invitations for the club with invitee details
    RETURN QUERY
    SELECT
        ci.id,
        ci.club_id,
        bc.name AS club_name,
        ci.invitee_id,
        COALESCE(
            NULLIF(btrim(u.name), ''),
            NULLIF(btrim(u.username), ''),
            'Unknown'
        ) AS invitee_name,
        NULLIF(btrim(u.username), '') AS invitee_username,
        u.email AS invitee_email,
        u.avatar_url AS invitee_avatar_url,
        ci.status,
        ci.message,
        ci.created_at,
        ci.responded_at,
        ci.expires_at
    FROM club_invitations ci
    JOIN book_clubs bc ON bc.id = ci.club_id
    LEFT JOIN users u ON u.id = ci.invitee_id
    WHERE ci.club_id = p_club_id
    ORDER BY ci.created_at DESC;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth;

-- Respond to an invitation (accept/decline)
CREATE OR REPLACE FUNCTION respond_to_club_invitation(
    p_auth_user_id UUID,
    p_invitation_id UUID,
    p_response TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_user_internal_id UUID;
    v_invitation RECORD;
BEGIN
    -- Normalize response input
    p_response := LOWER(TRIM(COALESCE(p_response, '')));

    IF p_response NOT IN ('accepted', 'declined') THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Response must be accepted or declined');
    END IF;

    -- Resolve internal ID
    v_user_internal_id := get_user_internal_id(p_auth_user_id);

    IF v_user_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'User not found');
    END IF;

    -- Load invitation
    SELECT * INTO v_invitation
    FROM club_invitations
    WHERE id = p_invitation_id
      AND invitee_id = v_user_internal_id
      AND status = 'pending';

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Invitation not found or already processed');
    END IF;

    -- Check expiration
    IF v_invitation.expires_at IS NOT NULL AND v_invitation.expires_at < NOW() THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Invitation has expired');
    END IF;

    IF p_response = 'accepted' THEN
        -- Prevent duplicate membership
        IF EXISTS (
            SELECT 1 FROM book_club_members
            WHERE club_id = v_invitation.club_id
              AND user_id = v_user_internal_id
        ) THEN
            RETURN jsonb_build_object('success', FALSE, 'error', 'You are already a member of this club');
        END IF;

        INSERT INTO book_club_members (club_id, user_id, role, joined_at)
        VALUES (v_invitation.club_id, v_user_internal_id, 'member', NOW());

        UPDATE club_invitations
        SET status = 'accepted',
            responded_at = NOW(),
            updated_at = NOW()
        WHERE id = p_invitation_id;

        RETURN jsonb_build_object('success', TRUE, 'message', 'Invitation accepted');
    ELSE
        UPDATE club_invitations
        SET status = 'declined',
            responded_at = NOW(),
            updated_at = NOW()
        WHERE id = p_invitation_id;

        RETURN jsonb_build_object('success', TRUE, 'message', 'Invitation declined');
    END IF;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth;

-- Legacy helper used in some scripts to auto-accept invitations
CREATE OR REPLACE FUNCTION accept_club_invitation(
    p_auth_user_id UUID,
    p_invitation_id UUID
)
RETURNS JSONB AS $$
BEGIN
    RETURN respond_to_club_invitation(p_auth_user_id, p_invitation_id, 'accepted');
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth;

