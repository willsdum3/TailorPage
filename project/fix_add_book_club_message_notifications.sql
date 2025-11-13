-- Fix add_book_club_message function to create notifications correctly
-- Ensure notifications are created when users send messages in book clubs

-- Drop existing function
DROP FUNCTION IF EXISTS add_book_club_message(UUID, UUID, TEXT) CASCADE;

-- Create the function with correct table names and notification creation
CREATE OR REPLACE FUNCTION add_book_club_message(
    p_auth_user_id UUID,
    p_club_id UUID,
    p_content TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_user_internal_id UUID;
    v_message_id UUID;
    v_sender_name TEXT;
    v_club_name TEXT;
    v_member_record RECORD;
    v_notification_count INTEGER := 0;
BEGIN
    -- Get user's internal ID
    v_user_internal_id := get_user_internal_id(p_auth_user_id);
    
    IF v_user_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Check if user is a member of the club
    IF NOT EXISTS (
        SELECT 1 FROM book_club_members 
        WHERE user_id = v_user_internal_id 
        AND club_id = p_club_id
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'You are not a member of this club');
    END IF;
    
    -- Get sender name and club name for notifications
    SELECT COALESCE(NULLIF(BTRIM(name), ''), NULLIF(BTRIM(username), ''), 'Unknown') INTO v_sender_name
    FROM users 
    WHERE id = v_user_internal_id;
    
    SELECT name INTO v_club_name
    FROM book_clubs 
    WHERE id = p_club_id;
    
    -- Insert the message
    INSERT INTO book_club_messages (club_id, user_id, message, created_at)
    VALUES (p_club_id, v_user_internal_id, p_content, NOW())
    RETURNING id INTO v_message_id;
    
    -- Create notifications for all members except the sender
    -- Skip users who have muted this club
    FOR v_member_record IN 
        SELECT bcm.user_id 
        FROM book_club_members bcm
        WHERE bcm.club_id = p_club_id 
        AND bcm.user_id != v_user_internal_id
        AND NOT EXISTS (
            SELECT 1 FROM club_mute_preferences cmp
            WHERE cmp.user_id = bcm.user_id
            AND cmp.club_id = p_club_id
            AND cmp.is_muted = TRUE
        )
    LOOP
        BEGIN
            INSERT INTO notifications (user_id, type, title, message, related_id, related_name)
            VALUES (
                v_member_record.user_id,
                'club_message',
                'New Message in ' || COALESCE(v_club_name, 'Book Club'),
                COALESCE(v_sender_name, 'Someone') || ': ' || LEFT(p_content, 100) || CASE WHEN LENGTH(p_content) > 100 THEN '...' ELSE '' END,
                p_club_id,
                v_club_name
            );
            v_notification_count := v_notification_count + 1;
        EXCEPTION
            WHEN OTHERS THEN
                -- Log error but continue with other members
                RAISE WARNING 'Error creating notification for user %: %', v_member_record.user_id, SQLERRM;
        END;
    END LOOP;
    
    RETURN jsonb_build_object(
        'success', true, 
        'message_id', v_message_id,
        'message', 'Message sent successfully',
        'notifications_created', v_notification_count
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', COALESCE(SQLERRM, 'Failed to send message'));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION add_book_club_message(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION add_book_club_message(UUID, UUID, TEXT) TO anon;

