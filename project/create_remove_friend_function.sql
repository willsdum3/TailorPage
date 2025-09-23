-- Create the remove_friend function if it doesn't exist
-- This function removes a friendship and deletes the conversation

CREATE OR REPLACE FUNCTION remove_friend(
    p_auth_user_id UUID,
    p_friend_id UUID
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_conversation_id UUID;
BEGIN
    -- Get the user ID from auth_user_id
    SELECT id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Check if friendship exists
    IF NOT EXISTS (
        SELECT 1 FROM friend_requests
        WHERE ((requester_id = v_user_id AND target_id = p_friend_id) OR 
               (requester_id = p_friend_id AND target_id = v_user_id))
        AND status = 'accepted'
    ) THEN
        RETURN json_build_object('success', false, 'error', 'Friendship not found');
    END IF;
    
    -- Delete the friendship
    DELETE FROM friend_requests
    WHERE ((requester_id = v_user_id AND target_id = p_friend_id) OR 
           (requester_id = p_friend_id AND target_id = v_user_id))
    AND status = 'accepted';
    
    -- Get conversation ID if it exists
    SELECT id INTO v_conversation_id
    FROM friend_conversations
    WHERE (user1_id = LEAST(v_user_id, p_friend_id) AND user2_id = GREATEST(v_user_id, p_friend_id));
    
    -- Delete conversation and all messages
    IF v_conversation_id IS NOT NULL THEN
        DELETE FROM friend_conversations WHERE id = v_conversation_id;
        -- Messages will be deleted by CASCADE
    END IF;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Friend removed successfully'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Failed to remove friend: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql;
