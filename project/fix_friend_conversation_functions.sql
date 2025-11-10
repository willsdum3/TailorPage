-- Recreate friend conversation helper functions so messaging UI can load history correctly

-- Drop older versions that may reference the removed conversations table
DROP FUNCTION IF EXISTS get_friend_conversations(UUID);
DROP FUNCTION IF EXISTS get_friend_messages(UUID, UUID);

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
    SELECT id INTO v_user_id
    FROM users
    WHERE auth_user_id = p_auth_user_id;

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
    )
    SELECT
        cd.id,
        cd.friend_id,
        COALESCE(NULLIF(BTRIM(u.name), ''), NULLIF(BTRIM(u.username), ''), 'Unknown') AS friend_name,
        u.username AS friend_username,
        u.avatar_url AS friend_image_url,
        lm.content AS last_message,
        lm.created_at AS last_message_at,
        0::INTEGER AS unread_count,
        FALSE::BOOLEAN AS is_online
    FROM conversation_data cd
    JOIN users u ON u.id = cd.friend_id
    LEFT JOIN latest_messages lm ON lm.conversation_id = cd.id
    ORDER BY COALESCE(lm.created_at, cd.created_at) DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth;

-- Return the messages for a specific conversation (if the user participates)
CREATE OR REPLACE FUNCTION get_friend_messages(
    p_auth_user_id UUID,
    p_conversation_id UUID
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
    is_edited BOOLEAN
) AS $$
DECLARE
    v_user_id UUID;
    v_has_access BOOLEAN;
BEGIN
    SELECT id INTO v_user_id
    FROM users
    WHERE auth_user_id = p_auth_user_id;

    IF v_user_id IS NULL THEN
        RETURN;
    END IF;

    SELECT TRUE INTO v_has_access
    FROM friend_conversations fc
    WHERE fc.id = p_conversation_id
      AND (fc.user1_id = v_user_id OR fc.user2_id = v_user_id)
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        fm.id,
        fm.conversation_id,
        fm.sender_id,
        COALESCE(NULLIF(BTRIM(sender.name), ''), NULLIF(BTRIM(sender.username), ''), 'Unknown') AS sender_name,
        sender.username AS sender_username,
        sender.avatar_url AS sender_image_url,
        fm.content,
        fm.message_type,
        fm.book_recommendation,
        fm.created_at,
        COALESCE(fm.is_edited, FALSE) AS is_edited
    FROM friend_messages fm
    LEFT JOIN users sender ON sender.id = fm.sender_id
    WHERE fm.conversation_id = p_conversation_id
    ORDER BY fm.created_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth;
