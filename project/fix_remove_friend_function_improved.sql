-- Improved version of remove_friend_by_internal_id function
-- This version has better error handling and debugging

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
    v_friendship_exists BOOLEAN;
BEGIN
    -- Get the current user's internal ID from auth_user_id
    SELECT id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not found', 'debug_step', 'user_lookup');
    END IF;
    
    -- Get the friend's auth_user_id from their internal ID
    SELECT auth_user_id INTO v_friend_auth_user_id
    FROM users 
    WHERE id = p_friend_internal_id;
    
    IF v_friend_auth_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Friend not found', 'debug_step', 'friend_lookup');
    END IF;
    
    -- Check if friendship exists with more detailed logic
    SELECT EXISTS (
        SELECT 1 FROM friend_requests
        WHERE ((requester_id = v_user_id AND target_id = p_friend_internal_id) OR 
               (requester_id = p_friend_internal_id AND target_id = v_user_id))
        AND status = 'accepted'
    ) INTO v_friendship_exists;
    
    IF NOT v_friendship_exists THEN
        RETURN json_build_object(
            'success', false, 
            'error', 'Friendship not found', 
            'debug_step', 'friendship_check',
            'debug_info', json_build_object(
                'user_id', v_user_id,
                'friend_internal_id', p_friend_internal_id,
                'friendship_exists', v_friendship_exists
            )
        );
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
            'conversation_id', v_conversation_id,
            'user_id', v_user_id,
            'friend_internal_id', p_friend_internal_id
        )
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Failed to remove friend: ' || SQLERRM,
            'debug_step', 'exception_handling'
        );
END;
$$ LANGUAGE plpgsql;
