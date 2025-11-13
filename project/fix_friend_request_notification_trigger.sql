-- Fix friend request notification trigger
-- The trigger was set up for friend_requests table, but the system uses friend_connections table

-- Drop the old trigger if it exists
DROP TRIGGER IF EXISTS trigger_friend_request_notification ON friend_requests;
DROP TRIGGER IF EXISTS trigger_friend_request_notification ON friend_connections;

-- Update the notification function to work with friend_connections table
CREATE OR REPLACE FUNCTION notify_friend_request()
RETURNS TRIGGER AS $$
DECLARE
    v_requester_name TEXT;
    v_target_name TEXT;
BEGIN
    -- Only create notification for pending requests (not accepted/rejected)
    IF NEW.status != 'pending' THEN
        RETURN NEW;
    END IF;
    
    -- Get requester name (user_id is the requester)
    SELECT COALESCE(NULLIF(BTRIM(name), ''), NULLIF(BTRIM(username), ''), 'Unknown') INTO v_requester_name
    FROM users 
    WHERE id = NEW.user_id;
    
    -- Get target name (friend_id is the target/recipient)
    SELECT COALESCE(NULLIF(BTRIM(name), ''), NULLIF(BTRIM(username), ''), 'Unknown') INTO v_target_name
    FROM users 
    WHERE id = NEW.friend_id;
    
    -- Create notification for the target user (friend_id is the recipient)
    INSERT INTO notifications (user_id, type, title, message, related_id, related_name)
    VALUES (
        NEW.friend_id,
        'friend_request',
        'New Friend Request',
        COALESCE(v_requester_name, 'Someone') || ' wants to be your friend!',
        NEW.user_id,  -- related_id is the requester's internal ID
        v_requester_name
    );
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't fail the transaction
        RAISE WARNING 'Error creating friend request notification: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

-- Create trigger on friend_connections table
CREATE TRIGGER trigger_friend_request_notification
    AFTER INSERT ON friend_connections
    FOR EACH ROW
    WHEN (NEW.status = 'pending')
    EXECUTE FUNCTION notify_friend_request();

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION notify_friend_request() TO authenticated;
GRANT EXECUTE ON FUNCTION notify_friend_request() TO anon;

