-- Fix the remove_friend_by_internal_id function to work with RLS
-- The function needs SECURITY DEFINER to bypass RLS policies

-- Drop the existing function
DROP FUNCTION IF EXISTS remove_friend_by_internal_id(uuid, uuid);

-- Create the function with SECURITY DEFINER
CREATE OR REPLACE FUNCTION remove_friend_by_internal_id(
    p_auth_user_id UUID,
    p_friend_internal_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER  -- This allows the function to bypass RLS policies
AS $$
DECLARE
    current_user_internal_id UUID;
    friend_auth_user_id UUID;
    deleted_friendships INTEGER := 0;
    deleted_conversations INTEGER := 0;
    conversation_id_to_delete UUID;
    result JSON;
BEGIN
    -- Step 1: Get current user's internal ID
    SELECT id INTO current_user_internal_id 
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF current_user_internal_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'User not found',
            'debug_step', 'user_lookup'
        );
    END IF;
    
    -- Step 2: Get friend's auth_user_id
    SELECT auth_user_id INTO friend_auth_user_id 
    FROM users 
    WHERE id = p_friend_internal_id;
    
    IF friend_auth_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Friend not found',
            'debug_step', 'friend_lookup'
        );
    END IF;
    
    -- Step 3: Check if friendship exists
    IF NOT EXISTS(
        SELECT 1 FROM friend_requests 
        WHERE ((requester_id = current_user_internal_id AND target_id = p_friend_internal_id)
               OR (requester_id = p_friend_internal_id AND target_id = current_user_internal_id))
        AND status = 'accepted'
    ) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Friendship not found',
            'debug_step', 'friendship_check'
        );
    END IF;
    
    -- Step 4: Get conversation ID before deletion
    SELECT id INTO conversation_id_to_delete
    FROM friend_conversations
    WHERE (user1_id = current_user_internal_id AND user2_id = p_friend_internal_id)
       OR (user1_id = p_friend_internal_id AND user2_id = current_user_internal_id);
    
    -- Step 5: Delete friendship
    DELETE FROM friend_requests 
    WHERE ((requester_id = current_user_internal_id AND target_id = p_friend_internal_id)
           OR (requester_id = p_friend_internal_id AND target_id = current_user_internal_id))
    AND status = 'accepted';
    
    GET DIAGNOSTICS deleted_friendships = ROW_COUNT;
    
    -- Step 6: Delete conversation and messages
    IF conversation_id_to_delete IS NOT NULL THEN
        -- Delete messages first (due to foreign key constraints)
        DELETE FROM friend_messages WHERE conversation_id = conversation_id_to_delete;
        
        -- Delete conversation
        DELETE FROM friend_conversations WHERE id = conversation_id_to_delete;
        GET DIAGNOSTICS deleted_conversations = ROW_COUNT;
    END IF;
    
    -- Step 7: Return success
    RETURN json_build_object(
        'success', true,
        'message', 'Friend removed successfully',
        'debug_info', json_build_object(
            'deleted_friendships', deleted_friendships,
            'deleted_conversations', deleted_conversations,
            'conversation_id', conversation_id_to_delete,
            'user_id', current_user_internal_id,
            'friend_internal_id', p_friend_internal_id
        )
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Database error: ' || SQLERRM,
            'debug_step', 'exception'
        );
END;
$$;
