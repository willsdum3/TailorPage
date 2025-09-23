-- Fix the get_friend_conversations function to use consistent conversation IDs
-- This should resolve the 400 errors by ensuring conversation IDs match between functions

DROP FUNCTION IF EXISTS get_friend_conversations(UUID);

CREATE OR REPLACE FUNCTION get_friend_conversations(
    p_auth_user_id UUID
) RETURNS TABLE(
    id UUID,
    friend_id UUID,
    friend_name TEXT,
    friend_username TEXT,
    friend_image_url TEXT,
    last_message TEXT,
    last_message_at TIMESTAMP WITH TIME ZONE,
    unread_count INTEGER,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Get the user ID from auth_user_id
    SELECT users.id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Return conversations from friend_requests with consistent conversation IDs
    RETURN QUERY
    SELECT DISTINCT
        -- Use the same conversation ID generation as messaging functions
        md5(LEAST(fr.requester_id, fr.target_id)::text || GREATEST(fr.requester_id, fr.target_id)::text)::uuid as id,
        CASE 
            WHEN fr.requester_id = v_user_id THEN fr.target_id 
            ELSE fr.requester_id 
        END as friend_id,
        CASE 
            WHEN fr.requester_id = v_user_id THEN u2.name 
            ELSE u1.name 
        END as friend_name,
        CASE 
            WHEN fr.requester_id = v_user_id THEN u2.username 
            ELSE u1.username 
        END as friend_username,
        CASE 
            WHEN fr.requester_id = v_user_id THEN u2.avatar_url 
            ELSE u1.avatar_url 
        END as friend_image_url,
        COALESCE(
            (SELECT fm.content 
             FROM friend_messages fm 
             WHERE fm.conversation_id = md5(LEAST(fr.requester_id, fr.target_id)::text || GREATEST(fr.requester_id, fr.target_id)::text)::uuid
             ORDER BY fm.created_at DESC 
             LIMIT 1),
            'No messages yet'
        ) as last_message,
        COALESCE(
            (SELECT fm.created_at 
             FROM friend_messages fm 
             WHERE fm.conversation_id = md5(LEAST(fr.requester_id, fr.target_id)::text || GREATEST(fr.requester_id, fr.target_id)::text)::uuid
             ORDER BY fm.created_at DESC 
             LIMIT 1),
            fr.created_at
        ) as last_message_at,
        COALESCE(
            (SELECT COUNT(*)::INTEGER 
             FROM friend_messages fm 
             WHERE fm.conversation_id = md5(LEAST(fr.requester_id, fr.target_id)::text || GREATEST(fr.requester_id, fr.target_id)::text)::uuid
             AND fm.sender_id != v_user_id
             AND fm.created_at > COALESCE(
                 (SELECT last_read_at FROM user_conversation_reads 
                  WHERE conversation_id = md5(LEAST(fr.requester_id, fr.target_id)::text || GREATEST(fr.requester_id, fr.target_id)::text)::uuid
                  AND user_id = v_user_id),
                 '1970-01-01'::timestamp
             )),
            0
        ) as unread_count,
        fr.created_at
    FROM friend_requests fr
    LEFT JOIN users u1 ON fr.requester_id = u1.id
    LEFT JOIN users u2 ON fr.target_id = u2.id
    WHERE (fr.requester_id = v_user_id OR fr.target_id = v_user_id)
    AND fr.status = 'accepted'
    ORDER BY fr.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
