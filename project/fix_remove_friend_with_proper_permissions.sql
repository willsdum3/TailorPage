-- Fix remove_friend function to handle user ID lookup internally
-- This avoids RLS issues by doing the lookup within the database function

CREATE OR REPLACE FUNCTION remove_friend_by_internal_id(
    p_auth_user_id UUID,
    p_friend_internal_id UUID
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_friend_auth_user_id UUID;
    v_conversation_id UUID;
    v_deleted_friendships INTEGER;
    v_deleted_conversations INTEGER;
BEGIN
    -- Get the current user's internal ID from auth_user_id
    SELECT id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Get the friend's auth_user_id from their internal ID
    SELECT auth_user_id INTO v_friend_auth_user_id
    FROM users 
    WHERE id = p_friend_internal_id;
    
    IF v_friend_auth_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Friend not found');
    END IF;
    
    -- Check if friendship exists
    IF NOT EXISTS (
        SELECT 1 FROM friend_requests
        WHERE ((requester_id = v_user_id AND target_id = p_friend_internal_id) OR 
               (requester_id = p_friend_internal_id AND target_id = v_user_id))
        AND status = 'accepted'
    ) THEN
        RETURN json_build_object('success', false, 'error', 'Friendship not found');
    END IF;
    
    -- Delete the friendship and get count
    DELETE FROM friend_requests
    WHERE ((requester_id = v_user_id AND target_id = p_friend_internal_id) OR 
           (requester_id = p_friend_internal_id AND target_id = v_user_id))
    AND status = 'accepted';
    
    GET DIAGNOSTICS v_deleted_friendships = ROW_COUNT;
    
    -- Get conversation ID if it exists
    SELECT id INTO v_conversation_id
    FROM friend_conversations
    WHERE (user1_id = LEAST(v_user_id, p_friend_internal_id) AND user2_id = GREATEST(v_user_id, p_friend_internal_id));
    
    -- Delete conversation and all messages
    IF v_conversation_id IS NOT NULL THEN
        DELETE FROM friend_conversations WHERE id = v_conversation_id;
        GET DIAGNOSTICS v_deleted_conversations = ROW_COUNT;
    END IF;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Friend removed successfully',
        'debug_info', json_build_object(
            'deleted_friendships', v_deleted_friendships,
            'deleted_conversations', v_deleted_conversations,
            'conversation_id', v_conversation_id
        )
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Failed to remove friend: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql;
