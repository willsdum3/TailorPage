-- Debug version of remove_friend function to see what's happening
CREATE OR REPLACE FUNCTION debug_remove_friend(
    p_auth_user_id UUID,
    p_friend_id UUID
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_conversation_id UUID;
    v_deleted_friendships INTEGER;
    v_deleted_conversations INTEGER;
BEGIN
    -- Get the user ID from auth_user_id
    SELECT id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    RAISE NOTICE 'Debug: p_auth_user_id = %, v_user_id = %', p_auth_user_id, v_user_id;
    
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
        RAISE NOTICE 'Debug: No friendship found between % and %', v_user_id, p_friend_id;
        RETURN json_build_object('success', false, 'error', 'Friendship not found');
    END IF;
    
    RAISE NOTICE 'Debug: Friendship found, proceeding with deletion';
    
    -- Delete the friendship and get count
    DELETE FROM friend_requests
    WHERE ((requester_id = v_user_id AND target_id = p_friend_id) OR 
           (requester_id = p_friend_id AND target_id = v_user_id))
    AND status = 'accepted';
    
    GET DIAGNOSTICS v_deleted_friendships = ROW_COUNT;
    RAISE NOTICE 'Debug: Deleted % friendships', v_deleted_friendships;
    
    -- Get conversation ID if it exists
    SELECT id INTO v_conversation_id
    FROM friend_conversations
    WHERE (user1_id = LEAST(v_user_id, p_friend_id) AND user2_id = GREATEST(v_user_id, p_friend_id));
    
    RAISE NOTICE 'Debug: Found conversation_id = %', v_conversation_id;
    
    -- Delete conversation and all messages
    IF v_conversation_id IS NOT NULL THEN
        DELETE FROM friend_conversations WHERE id = v_conversation_id;
        GET DIAGNOSTICS v_deleted_conversations = ROW_COUNT;
        RAISE NOTICE 'Debug: Deleted % conversations', v_deleted_conversations;
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
        RAISE NOTICE 'Debug: Error occurred: %', SQLERRM;
        RETURN json_build_object(
            'success', false,
            'error', 'Failed to remove friend: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql;
