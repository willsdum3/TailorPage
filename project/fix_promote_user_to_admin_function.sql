-- Recreate promote_user_to_admin with the exact parameters the frontend calls
DROP FUNCTION IF EXISTS promote_user_to_admin(UUID, UUID, UUID);
DROP FUNCTION IF EXISTS promote_user_to_admin(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS promote_user_to_admin CASCADE;

CREATE OR REPLACE FUNCTION promote_user_to_admin(
    p_auth_user_id UUID,
    p_club_id UUID,
    p_user_to_promote_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_promoter_internal_id UUID;
    v_target_internal_id UUID;
    v_club_name TEXT;
    v_target_role TEXT;
BEGIN
    -- Resolve the promoter's internal user ID
    SELECT id INTO v_promoter_internal_id
    FROM users
    WHERE auth_user_id = p_auth_user_id;

    IF v_promoter_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', FALSE, 'message', 'Current user not found');
    END IF;

    v_target_internal_id := p_user_to_promote_id;

    IF v_target_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', FALSE, 'message', 'User to promote not found');
    END IF;

    IF v_promoter_internal_id = v_target_internal_id THEN
        RETURN jsonb_build_object('success', FALSE, 'message', 'You cannot promote yourself');
    END IF;

    -- Ensure promoter is an admin/owner of the club
    IF NOT EXISTS (
        SELECT 1
        FROM book_club_members bcm
        WHERE bcm.club_id = p_club_id
          AND bcm.user_id = v_promoter_internal_id
          AND bcm.role IN ('admin', 'owner')
    ) THEN
        RETURN jsonb_build_object('success', FALSE, 'message', 'Only club admins can promote members');
    END IF;

    -- Ensure the target is already a member of the club
    SELECT role INTO v_target_role
    FROM book_club_members
    WHERE club_id = p_club_id
      AND user_id = v_target_internal_id;

    IF v_target_role IS NULL THEN
        RETURN jsonb_build_object('success', FALSE, 'message', 'User is not a member of this club');
    END IF;

    IF v_target_role IN ('admin', 'owner') THEN
        RETURN jsonb_build_object('success', FALSE, 'message', 'User is already an admin');
    END IF;

    -- Promote the member to admin
    UPDATE book_club_members
    SET role = 'admin'
    WHERE club_id = p_club_id
      AND user_id = v_target_internal_id;

    -- Fetch club name for messaging
    SELECT name INTO v_club_name
    FROM book_clubs
    WHERE id = p_club_id;

    -- Notify the promoted user (best effort)
    BEGIN
        INSERT INTO notifications (
            user_id,
            type,
            title,
            message,
            related_id,
            related_name
        ) VALUES (
            v_target_internal_id,
            'club_promotion',
            'You have been promoted to admin!',
            COALESCE(v_club_name, 'Your book club') || ' has promoted you to admin.',
            p_club_id,
            v_club_name
        );
    EXCEPTION
        WHEN OTHERS THEN
            -- Ignore notification failures
            NULL;
    END;

    RETURN jsonb_build_object('success', TRUE, 'message', 'Member promoted to admin successfully');
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', FALSE, 'message', COALESCE(SQLERRM, 'Failed to promote member'));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth;
