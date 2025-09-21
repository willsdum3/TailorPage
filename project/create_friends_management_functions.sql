-- Create Friends management functions
-- This script creates all functions for friend requests, blocking, and management

-- =====================================================
-- FRIEND REQUEST FUNCTIONS
-- =====================================================

-- Send a friend request
CREATE OR REPLACE FUNCTION send_friend_request(
    p_auth_user_id UUID,
    p_target_user_id UUID,
    p_message TEXT DEFAULT NULL
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_target_user RECORD;
    v_request_id UUID;
BEGIN
    -- Get the user ID from auth_user_id
    SELECT id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Can't send friend request to yourself
    IF v_user_id = p_target_user_id THEN
        RETURN json_build_object('success', false, 'error', 'Cannot send friend request to yourself');
    END IF;
    
    -- Check if target user exists
    SELECT name, username INTO v_target_user
    FROM users WHERE id = p_target_user_id;
    
    IF v_target_user IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Target user not found');
    END IF;
    
    -- Check if user is blocked
    IF EXISTS (
        SELECT 1 FROM blocked_users
        WHERE (blocker_id = v_user_id AND blocked_id = p_target_user_id) OR
              (blocker_id = p_target_user_id AND blocked_id = v_user_id)
    ) THEN
        RETURN json_build_object('success', false, 'error', 'Cannot send friend request');
    END IF;
    
    -- Check if friend request already exists
    IF EXISTS (
        SELECT 1 FROM friend_requests
        WHERE (requester_id = v_user_id AND target_id = p_target_user_id) OR
              (requester_id = p_target_user_id AND target_id = v_user_id)
    ) THEN
        RETURN json_build_object('success', false, 'error', 'Friend request already exists');
    END IF;
    
    -- Insert friend request
    INSERT INTO friend_requests (requester_id, target_id, message, status)
    VALUES (v_user_id, p_target_user_id, p_message, 'pending')
    RETURNING id INTO v_request_id;
    
    -- Create notification for target user
    INSERT INTO notifications (user_id, type, title, message, related_id, related_name)
    SELECT 
        p_target_user_id,
        'friend_request',
        'New Friend Request',
        (SELECT name FROM users WHERE id = v_user_id) || ' wants to be your friend',
        v_user_id,
        (SELECT name FROM users WHERE id = v_user_id);
    
    RETURN json_build_object(
        'success', true,
        'message', 'Friend request sent to ' || v_target_user.name,
        'requestId', v_request_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Accept a friend request
CREATE OR REPLACE FUNCTION accept_friend_request(
    p_auth_user_id UUID,
    p_requester_id UUID
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_requester_name TEXT;
BEGIN
    -- Get the user ID from auth_user_id
    SELECT id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Check if friend request exists and is pending
    IF NOT EXISTS (
        SELECT 1 FROM friend_requests
        WHERE requester_id = p_requester_id 
        AND target_id = v_user_id 
        AND status = 'pending'
    ) THEN
        RETURN json_build_object('success', false, 'error', 'Friend request not found');
    END IF;
    
    -- Update friend request status
    UPDATE friend_requests
    SET status = 'accepted', updated_at = NOW()
    WHERE requester_id = p_requester_id AND target_id = v_user_id;
    
    -- Get requester name for notification
    SELECT name INTO v_requester_name
    FROM users WHERE id = p_requester_id;
    
    -- Create notification for requester
    INSERT INTO notifications (user_id, type, title, message, related_id, related_name)
    SELECT 
        p_requester_id,
        'friend_request',
        'Friend Request Accepted',
        (SELECT name FROM users WHERE id = v_user_id) || ' accepted your friend request',
        v_user_id,
        (SELECT name FROM users WHERE id = v_user_id);
    
    RETURN json_build_object(
        'success', true,
        'message', 'Friend request accepted'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Reject a friend request
CREATE OR REPLACE FUNCTION reject_friend_request(
    p_auth_user_id UUID,
    p_requester_id UUID
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Get the user ID from auth_user_id
    SELECT id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Check if friend request exists and is pending
    IF NOT EXISTS (
        SELECT 1 FROM friend_requests
        WHERE requester_id = p_requester_id 
        AND target_id = v_user_id 
        AND status = 'pending'
    ) THEN
        RETURN json_build_object('success', false, 'error', 'Friend request not found');
    END IF;
    
    -- Update friend request status
    UPDATE friend_requests
    SET status = 'rejected', updated_at = NOW()
    WHERE requester_id = p_requester_id AND target_id = v_user_id;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Friend request rejected'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Remove a friend
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
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Block a user
CREATE OR REPLACE FUNCTION block_friend(
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
    
    -- Can't block yourself
    IF v_user_id = p_friend_id THEN
        RETURN json_build_object('success', false, 'error', 'Cannot block yourself');
    END IF;
    
    -- Remove friendship if it exists
    DELETE FROM friend_requests
    WHERE ((requester_id = v_user_id AND target_id = p_friend_id) OR 
           (requester_id = p_friend_id AND target_id = v_user_id));
    
    -- Get conversation ID if it exists
    SELECT id INTO v_conversation_id
    FROM friend_conversations
    WHERE (user1_id = LEAST(v_user_id, p_friend_id) AND user2_id = GREATEST(v_user_id, p_friend_id));
    
    -- Delete conversation and all messages
    IF v_conversation_id IS NOT NULL THEN
        DELETE FROM friend_conversations WHERE id = v_conversation_id;
    END IF;
    
    -- Add to blocked users (if not already blocked)
    INSERT INTO blocked_users (blocker_id, blocked_id)
    VALUES (v_user_id, p_friend_id)
    ON CONFLICT (blocker_id, blocked_id) DO NOTHING;
    
    RETURN json_build_object(
        'success', true,
        'message', 'User blocked successfully'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Unblock a user
CREATE OR REPLACE FUNCTION unblock_user(
    p_auth_user_id UUID,
    p_blocked_user_id UUID
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Get the user ID from auth_user_id
    SELECT id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Remove from blocked users
    DELETE FROM blocked_users
    WHERE blocker_id = v_user_id AND blocked_id = p_blocked_user_id;
    
    RETURN json_build_object(
        'success', true,
        'message', 'User unblocked successfully'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get blocked users
CREATE OR REPLACE FUNCTION get_blocked_users(
    p_auth_user_id UUID
) RETURNS TABLE(
    id UUID,
    blocked_user_id UUID,
    blocked_user_name TEXT,
    blocked_user_username TEXT,
    blocked_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Get the user ID from auth_user_id
    SELECT users.id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RETURN;
    END IF;
    
    RETURN QUERY
    SELECT 
        bu.id,
        bu.blocked_id as blocked_user_id,
        u.name as blocked_user_name,
        u.username as blocked_user_username,
        bu.created_at as blocked_at
    FROM blocked_users bu
    JOIN users u ON bu.blocked_id = u.id
    WHERE bu.blocker_id = v_user_id
    ORDER BY bu.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Test the functions exist
SELECT 
    routine_name as function_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN (
    'send_friend_request',
    'accept_friend_request',
    'reject_friend_request',
    'remove_friend',
    'block_friend',
    'unblock_user',
    'get_blocked_users'
)
ORDER BY routine_name;
