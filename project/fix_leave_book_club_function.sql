-- Fix the leave_book_club function so users can reliably leave clubs
-- Frontend sends: p_auth_user_id, p_club_id

-- Drop any old versions to avoid conflicts
DROP FUNCTION IF EXISTS leave_book_club(UUID, UUID);

CREATE OR REPLACE FUNCTION leave_book_club(
    p_auth_user_id UUID,
    p_club_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_user_internal_id UUID;
    v_membership_role TEXT;
    v_club_name TEXT;
BEGIN
    -- Resolve internal ID
    v_user_internal_id := get_user_internal_id(p_auth_user_id);

    IF v_user_internal_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'User not found'
        );
    END IF;

    -- Fetch membership info
    SELECT bcm.role
    INTO v_membership_role
    FROM book_club_members bcm
    WHERE bcm.club_id = p_club_id
      AND bcm.user_id = v_user_internal_id;

    IF v_membership_role IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'You are not a member of this club'
        );
    END IF;

    -- Prevent owners from leaving without transferring ownership
    IF v_membership_role = 'owner' THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Transfer ownership to another admin before leaving'
        );
    END IF;

    -- Capture club name for response message
    SELECT name INTO v_club_name
    FROM book_clubs
    WHERE id = p_club_id;

    DELETE FROM book_club_members
    WHERE club_id = p_club_id
      AND user_id = v_user_internal_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'message', COALESCE('You have left ' || v_club_name, 'You have left the club')
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', COALESCE(SQLERRM, 'Failed to leave the club')
        );
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth;




















