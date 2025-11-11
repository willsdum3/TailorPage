-- Recreate remove_friend_by_internal_id to ensure friend removal works for internal UUIDs

DROP FUNCTION IF EXISTS remove_friend_by_internal_id(UUID, UUID);

CREATE OR REPLACE FUNCTION remove_friend_by_internal_id(
    p_auth_user_id UUID,
    p_friend_internal_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_current_user_id UUID;
    v_removed_count INTEGER := 0;
BEGIN
    SELECT id INTO v_current_user_id
    FROM users
    WHERE auth_user_id = p_auth_user_id;

    IF v_current_user_id IS NULL THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Current user not found');
    END IF;

    -- Delete friend connections in both directions and capture affected rows
    WITH deleted AS (
        DELETE FROM friend_connections
        WHERE (user_id = v_current_user_id AND friend_id = p_friend_internal_id)
           OR (user_id = p_friend_internal_id AND friend_id = v_current_user_id)
        RETURNING 1
    )
    SELECT COUNT(*) INTO v_removed_count FROM deleted;

    -- Clean up any pending friend requests in both directions
    DELETE FROM friend_requests
    WHERE (requester_id = v_current_user_id AND target_id = p_friend_internal_id)
       OR (requester_id = p_friend_internal_id AND target_id = v_current_user_id);

    -- Remove associated conversations and messages if they exist
    DELETE FROM friend_messages
    WHERE conversation_id IN (
        SELECT id
        FROM friend_conversations
        WHERE (user1_id = v_current_user_id AND user2_id = p_friend_internal_id)
           OR (user1_id = p_friend_internal_id AND user2_id = v_current_user_id)
    );

    DELETE FROM friend_conversations
    WHERE (user1_id = v_current_user_id AND user2_id = p_friend_internal_id)
       OR (user1_id = p_friend_internal_id AND user2_id = v_current_user_id);

    IF v_removed_count > 0 THEN
        RETURN jsonb_build_object('success', TRUE, 'message', 'Friend removed successfully');
    ELSE
        RETURN jsonb_build_object('success', FALSE, 'error', 'Friendship not found');
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth;
