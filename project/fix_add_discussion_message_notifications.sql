-- Fix add_discussion_message function to create notifications correctly
-- Ensure notifications are created when users send messages in discussions

-- Drop existing function
DROP FUNCTION IF EXISTS add_discussion_message(UUID, UUID, TEXT) CASCADE;

-- Create the function with correct table names and notification creation
CREATE OR REPLACE FUNCTION add_discussion_message(
    p_auth_user_id UUID,
    p_discussion_id UUID,
    p_message_content TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_user_internal_id UUID;
    v_message_id UUID;
    v_sender_name TEXT;
    v_discussion_title TEXT;
    v_participant_record RECORD;
    v_notification_count INTEGER := 0;
BEGIN
    -- Get user's internal ID
    v_user_internal_id := get_user_internal_id(p_auth_user_id);
    
    IF v_user_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Check if user is a participant of the discussion
    IF NOT EXISTS (
        SELECT 1 FROM discussion_members 
        WHERE user_id = v_user_internal_id 
        AND discussion_id = p_discussion_id
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'You are not a participant of this discussion');
    END IF;
    
    -- Get sender name and discussion title for notifications
    SELECT COALESCE(NULLIF(BTRIM(name), ''), NULLIF(BTRIM(username), ''), 'Unknown') INTO v_sender_name
    FROM users 
    WHERE id = v_user_internal_id;
    
    SELECT title INTO v_discussion_title
    FROM discussions 
    WHERE id = p_discussion_id;
    
    -- Insert the message (column name is 'message', not 'content')
    INSERT INTO discussion_messages (discussion_id, user_id, message, created_at)
    VALUES (p_discussion_id, v_user_internal_id, p_message_content, NOW())
    RETURNING id INTO v_message_id;
    
    -- Create notifications for all participants except the sender
    -- Skip users who have muted this discussion
    FOR v_participant_record IN 
        SELECT dm.user_id 
        FROM discussion_members dm
        WHERE dm.discussion_id = p_discussion_id 
        AND dm.user_id != v_user_internal_id
        AND NOT EXISTS (
            SELECT 1 FROM discussion_mute_preferences dmp
            WHERE dmp.user_id = dm.user_id
            AND dmp.discussion_id = p_discussion_id
            AND dmp.is_muted = TRUE
        )
    LOOP
        BEGIN
            INSERT INTO notifications (user_id, type, title, message, related_id, related_name)
            VALUES (
                v_participant_record.user_id,
                'discussion_message',
                'New Message in ' || COALESCE(v_discussion_title, 'Discussion'),
                COALESCE(v_sender_name, 'Someone') || ': ' || LEFT(p_message_content, 100) || CASE WHEN LENGTH(p_message_content) > 100 THEN '...' ELSE '' END,
                p_discussion_id,
                v_discussion_title
            );
            v_notification_count := v_notification_count + 1;
        EXCEPTION
            WHEN OTHERS THEN
                -- Log error but continue with other participants
                RAISE WARNING 'Error creating notification for user %: %', v_participant_record.user_id, SQLERRM;
        END;
    END LOOP;
    
    -- Return the message object in DiscussionMessage format
    RETURN (
        SELECT jsonb_build_object(
            'id', dm.id::TEXT,
            'content', dm.message,  -- Table column is 'message', but frontend expects 'content'
            'createdAt', dm.created_at::TEXT,
            'userId', u.id::TEXT,
            'userName', COALESCE(NULLIF(BTRIM(u.name), ''), NULLIF(BTRIM(u.username), ''), 'Unknown'),
            'userUsername', u.username,
            'userImageUrl', u.avatar_url,
            'isEdited', false  -- Default to false, can be updated later if editing is implemented
        )
        FROM discussion_messages dm
        JOIN users u ON u.id = dm.user_id
        WHERE dm.id = v_message_id
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', COALESCE(SQLERRM, 'Failed to send message'));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION add_discussion_message(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION add_discussion_message(UUID, UUID, TEXT) TO anon;

-- Note: The function signature uses p_message_content to match the frontend call
-- Frontend calls: add_discussion_message(p_auth_user_id, p_discussion_id, p_message_content)

