-- Fix block friend functionality to remove friend connection and prevent messaging/requests

-- Dynamically drop all overloads of block functions
DO $$
DECLARE
    r RECORD;
BEGIN
    -- Drop all block_friend_flexible overloads
    FOR r IN 
        SELECT oid::regprocedure
        FROM pg_proc
        WHERE proname = 'block_friend_flexible'
          AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
    LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS ' || r.oid || ' CASCADE';
    END LOOP;
    
    -- Drop all block_friend overloads
    FOR r IN 
        SELECT oid::regprocedure
        FROM pg_proc
        WHERE proname = 'block_friend'
          AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
    LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS ' || r.oid || ' CASCADE';
    END LOOP;
    
    -- Drop all unblock_friend overloads
    FOR r IN 
        SELECT oid::regprocedure
        FROM pg_proc
        WHERE proname = 'unblock_friend'
          AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
    LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS ' || r.oid || ' CASCADE';
    END LOOP;
    
    -- Drop all get_blocked_users overloads
    FOR r IN 
        SELECT oid::regprocedure
        FROM pg_proc
        WHERE proname = 'get_blocked_users'
          AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
    LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS ' || r.oid || ' CASCADE';
    END LOOP;
END $$;

-- Function to block a friend (removes friend connection and prevents future interactions)
-- Note: p_blocker_auth_user_id is the auth_user_id, p_blocked_user_id is the internal user ID
CREATE OR REPLACE FUNCTION block_friend_flexible(
    p_blocker_auth_user_id UUID,
    p_blocked_user_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_blocker_internal_id UUID;
    v_blocked_internal_id UUID;
    v_removed_count INTEGER := 0;
BEGIN
    -- Get blocker's internal ID
    SELECT u.id INTO v_blocker_internal_id
    FROM users u
    WHERE u.auth_user_id = p_blocker_auth_user_id;

    IF v_blocker_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Blocker user not found');
    END IF;

    -- Get blocked user's internal ID (p_blocked_user_id is already internal ID)
    v_blocked_internal_id := p_blocked_user_id;

    IF v_blocked_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Blocked user not found');
    END IF;

    IF v_blocker_internal_id = v_blocked_internal_id THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Cannot block yourself');
    END IF;

    -- Remove friend connections in both directions
    WITH deleted AS (
        DELETE FROM friend_connections
        WHERE (user_id = v_blocker_internal_id AND friend_id = v_blocked_internal_id)
           OR (user_id = v_blocked_internal_id AND friend_id = v_blocker_internal_id)
        RETURNING 1
    )
    SELECT COUNT(*) INTO v_removed_count FROM deleted;

    -- Remove any pending friend requests in both directions
    DELETE FROM friend_requests
    WHERE (requester_id = v_blocker_internal_id AND target_id = v_blocked_internal_id)
       OR (requester_id = v_blocked_internal_id AND target_id = v_blocker_internal_id);

    -- Remove conversations and messages
    DELETE FROM friend_messages
    WHERE conversation_id IN (
        SELECT id
        FROM friend_conversations
        WHERE (user1_id = v_blocker_internal_id AND user2_id = v_blocked_internal_id)
           OR (user1_id = v_blocked_internal_id AND user2_id = v_blocker_internal_id)
    );

    DELETE FROM friend_conversations
    WHERE (user1_id = v_blocker_internal_id AND user2_id = v_blocked_internal_id)
       OR (user1_id = v_blocked_internal_id AND user2_id = v_blocker_internal_id);

    -- Add to blocked users table (upsert to handle duplicates)
    INSERT INTO user_blocks (blocker_id, blocked_id, created_at)
    VALUES (v_blocker_internal_id, v_blocked_internal_id, NOW())
    ON CONFLICT (blocker_id, blocked_id) DO NOTHING;

    RETURN jsonb_build_object(
        'success', TRUE,
        'message', 'Friend blocked successfully',
        'removed_connections', v_removed_count
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', FALSE, 'error', COALESCE(SQLERRM, 'Failed to block friend'));
END;
$$;

-- Function to unblock a user
CREATE OR REPLACE FUNCTION unblock_friend(
    p_blocker_auth_user_id UUID,
    p_blocked_user_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_blocker_internal_id UUID;
    v_blocked_internal_id UUID;
    v_removed_count INTEGER := 0;
BEGIN
    -- Get blocker's internal ID
    SELECT u.id INTO v_blocker_internal_id
    FROM users u
    WHERE u.auth_user_id = p_blocker_auth_user_id;

    IF v_blocker_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Blocker user not found');
    END IF;

    -- Get blocked user's internal ID (p_blocked_user_id is already internal ID)
    v_blocked_internal_id := p_blocked_user_id;

    IF v_blocked_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Blocked user not found');
    END IF;

    -- Remove from blocked users table
    DELETE FROM user_blocks
    WHERE blocker_id = v_blocker_internal_id
      AND blocked_id = v_blocked_internal_id;

    GET DIAGNOSTICS v_removed_count = ROW_COUNT;

    IF v_removed_count = 0 THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'User was not blocked');
    END IF;

    RETURN jsonb_build_object(
        'success', TRUE,
        'message', 'User unblocked successfully'
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', FALSE, 'error', COALESCE(SQLERRM, 'Failed to unblock user'));
END;
$$;

-- Function to get blocked users for a user
CREATE OR REPLACE FUNCTION get_blocked_users(
    p_auth_user_id UUID
)
RETURNS TABLE (
    blocked_user_id UUID,
    blocked_user_name TEXT,
    blocked_user_username TEXT,
    blocked_user_image_url TEXT,
    blocked_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    SELECT u.id INTO v_user_id
    FROM users u
    WHERE u.auth_user_id = p_auth_user_id;

    IF v_user_id IS NULL THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        u.id AS blocked_user_id,
        COALESCE(NULLIF(BTRIM(u.name), ''), NULLIF(BTRIM(u.username), ''), 'Unknown')::TEXT AS blocked_user_name,
        u.username::TEXT AS blocked_user_username,
        u.avatar_url::TEXT AS blocked_user_image_url,
        ub.created_at AS blocked_at
    FROM user_blocks ub
    JOIN users u ON u.id = ub.blocked_id
    WHERE ub.blocker_id = v_user_id
    ORDER BY ub.created_at DESC;
END;
$$;

