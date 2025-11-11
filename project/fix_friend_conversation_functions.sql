-- Recreate friend conversation helper functions so messaging UI can load history correctly

-- Drop older versions that may reference the removed conversations table
DROP FUNCTION IF EXISTS get_friend_conversations(UUID);
DROP FUNCTION IF EXISTS get_friend_messages(UUID, UUID);
DROP FUNCTION IF EXISTS get_friend_messages(UUID, UUID, INTEGER, INTEGER);

-- Return the list of conversations for the current user using friend_conversations
CREATE OR REPLACE FUNCTION get_friend_conversations(
    p_auth_user_id UUID
)
RETURNS TABLE (
    conversation_id UUID,
    friend_id UUID,
    friend_name TEXT,
    friend_username TEXT,
    friend_image_url TEXT,
    last_message TEXT,
    last_message_at TIMESTAMPTZ,
    unread_count INTEGER,
    is_online BOOLEAN
) AS $$
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
    WITH conversation_data AS (
        SELECT
            fc.id,
            CASE WHEN fc.user1_id = v_user_id THEN fc.user2_id ELSE fc.user1_id END AS friend_id,
            fc.created_at
        FROM friend_conversations fc
        WHERE fc.user1_id = v_user_id OR fc.user2_id = v_user_id
    ),
    latest_messages AS (
        SELECT DISTINCT ON (fm.conversation_id)
            fm.conversation_id,
            fm.content,
            fm.created_at
        FROM friend_messages fm
        ORDER BY fm.conversation_id, fm.created_at DESC
    ),
    unread_notifications AS (
        SELECT
            n.related_id::TEXT AS conversation_id_text,
            COUNT(*)::INTEGER AS unread_count
        FROM notifications n
        WHERE n.user_id = v_user_id
          AND n.type = 'friend_message'
          AND n.is_read = FALSE
          AND n.related_id IS NOT NULL
        GROUP BY n.related_id::TEXT
    )
    SELECT
        cd.id,
        cd.friend_id,
        COALESCE(NULLIF(BTRIM(u.name), ''), NULLIF(BTRIM(u.username), ''), 'Unknown') AS friend_name,
        u.username AS friend_username,
        u.avatar_url AS friend_image_url,
        lm.content AS last_message,
        lm.created_at AS last_message_at,
        COALESCE(un.unread_count, 0)::INTEGER AS unread_count,
        FALSE::BOOLEAN AS is_online
    FROM conversation_data cd
    JOIN users u ON u.id = cd.friend_id
    LEFT JOIN latest_messages lm ON lm.conversation_id = cd.id
    LEFT JOIN unread_notifications un ON un.conversation_id_text = cd.id::TEXT
    ORDER BY COALESCE(lm.created_at, cd.created_at) DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth;

-- Return the messages for a specific conversation (if the user participates)
CREATE OR REPLACE FUNCTION get_friend_messages(
    p_auth_user_id UUID,
    p_conversation_id UUID,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    conversation_id UUID,
    sender_id UUID,
    sender_name TEXT,
    sender_username TEXT,
    sender_image_url TEXT,
    content TEXT,
    message_type TEXT,
    book_recommendation JSONB,
    created_at TIMESTAMPTZ,
    is_edited BOOLEAN,
    is_read BOOLEAN
) AS $$
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
        fm.id,
        fm.conversation_id,
        fm.sender_id,
        COALESCE(NULLIF(BTRIM(sender.name), ''), NULLIF(BTRIM(sender.username), ''), 'Unknown')::TEXT AS sender_name,
        sender.username::TEXT AS sender_username,
        sender.avatar_url::TEXT AS sender_image_url,
        fm.content,
        fm.message_type::TEXT AS message_type,
        fm.book_recommendation,
        fm.created_at,
        COALESCE(fm.is_edited, FALSE) AS is_edited,
        CASE
            WHEN fm.sender_id = v_user_id THEN TRUE
            ELSE NOT EXISTS (
                SELECT 1
                FROM notifications n
                WHERE n.user_id = v_user_id
                  AND n.type = 'friend_message'
                  AND n.related_id::TEXT = fm.conversation_id::TEXT
                  AND n.is_read = FALSE
            )
        END AS is_read
    FROM friend_messages fm
    JOIN friend_conversations fc ON fc.id = fm.conversation_id
    LEFT JOIN users sender ON sender.id = fm.sender_id
    WHERE fm.conversation_id = p_conversation_id
      AND (fc.user1_id = v_user_id OR fc.user2_id = v_user_id)
    ORDER BY fm.created_at ASC
    LIMIT GREATEST(COALESCE(p_limit, 50), 1)
    OFFSET GREATEST(COALESCE(p_offset, 0), 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth;

-- Helper to mark all notifications for a conversation as read
DROP FUNCTION IF EXISTS mark_conversation_as_read(UUID, UUID);

CREATE OR REPLACE FUNCTION mark_conversation_as_read(
    p_auth_user_id UUID,
    p_conversation_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_updated INTEGER := 0;
BEGIN
    SELECT u.id INTO v_user_id
    FROM users u
    WHERE u.auth_user_id = p_auth_user_id;

    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'User not found');
    END IF;

    UPDATE notifications
    SET is_read = TRUE,
        updated_at = NOW()
    WHERE user_id = v_user_id
      AND type = 'friend_message'
      AND related_id::TEXT = p_conversation_id::TEXT
      AND is_read = FALSE;

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    RETURN jsonb_build_object('success', TRUE, 'updated', v_updated);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth;

-- Helper to get total unread message notifications for a user
DROP FUNCTION IF EXISTS get_total_unread_message_count(UUID);

CREATE OR REPLACE FUNCTION get_total_unread_message_count(
    p_auth_user_id UUID
)
RETURNS INTEGER AS $$
DECLARE
    v_user_id UUID;
    v_count INTEGER := 0;
BEGIN
    SELECT u.id INTO v_user_id
    FROM users u
    WHERE u.auth_user_id = p_auth_user_id;

    IF v_user_id IS NULL THEN
        RETURN 0;
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM notifications n
    WHERE n.user_id = v_user_id
      AND n.type = 'friend_message'
      AND n.is_read = FALSE;

    RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth;
