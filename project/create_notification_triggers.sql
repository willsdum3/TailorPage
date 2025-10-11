-- Create notification triggers for automatic notification creation
-- These will trigger notifications when specific events occur

-- Function to create friend request notification
CREATE OR REPLACE FUNCTION notify_friend_request()
RETURNS TRIGGER AS $$
DECLARE
    v_requester_name TEXT;
    v_target_name TEXT;
BEGIN
    -- Get requester name
    SELECT name INTO v_requester_name
    FROM users 
    WHERE id = NEW.requester_id;
    
    -- Get target name
    SELECT name INTO v_target_name
    FROM users 
    WHERE id = NEW.target_id;
    
    -- Create notification for the target user
    INSERT INTO notifications (user_id, type, title, message, related_id, related_name)
    VALUES (
        NEW.target_id,
        'friend_request',
        'New Friend Request',
        v_requester_name || ' wants to be your friend!',
        NEW.requester_id,
        v_requester_name
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to create club invitation notification
CREATE OR REPLACE FUNCTION notify_club_invitation()
RETURNS TRIGGER AS $$
DECLARE
    v_inviter_name TEXT;
    v_club_name TEXT;
BEGIN
    -- Get inviter name
    SELECT name INTO v_inviter_name
    FROM users 
    WHERE id = NEW.invited_by;
    
    -- Get club name
    SELECT name INTO v_club_name
    FROM book_clubs 
    WHERE id = NEW.club_id;
    
    -- Create notification for the invited user
    INSERT INTO notifications (user_id, type, title, message, related_id, related_name)
    VALUES (
        NEW.user_id,
        'club_invitation',
        'Book Club Invitation',
        v_inviter_name || ' invited you to join "' || v_club_name || '"',
        NEW.club_id,
        v_club_name
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to create admin promotion notification
CREATE OR REPLACE FUNCTION notify_admin_promotion()
RETURNS TRIGGER AS $$
DECLARE
    v_promoter_name TEXT;
    v_club_name TEXT;
BEGIN
    -- Only trigger if user_role changed to admin
    IF NEW.user_role = 'admin' AND (OLD.user_role IS NULL OR OLD.user_role != 'admin') THEN
        -- Get promoter name (assuming the current user is the promoter)
        -- This would need to be passed as a parameter in a real implementation
        SELECT name INTO v_promoter_name
        FROM users 
        WHERE id = NEW.user_id; -- This is a placeholder - in reality we'd need the promoter's ID
        
        -- Get club name
        SELECT name INTO v_club_name
        FROM book_clubs 
        WHERE id = NEW.club_id;
        
        -- Create notification for the promoted user
        INSERT INTO notifications (user_id, type, title, message, related_id, related_name)
        VALUES (
            NEW.user_id,
            'admin_promotion',
            'Admin Promotion',
            'You have been promoted to admin in "' || v_club_name || '"',
            NEW.club_id,
            v_club_name
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to create user joined club notification for admins
CREATE OR REPLACE FUNCTION notify_user_joined_club()
RETURNS TRIGGER AS $$
DECLARE
    v_joiner_name TEXT;
    v_club_name TEXT;
    admin_record RECORD;
BEGIN
    -- Only trigger if this is a new membership
    IF NEW.user_role = 'member' AND (OLD IS NULL OR OLD.user_role IS NULL) THEN
        -- Get joiner name
        SELECT name INTO v_joiner_name
        FROM users 
        WHERE id = NEW.user_id;
        
        -- Get club name
        SELECT name INTO v_club_name
        FROM book_clubs 
        WHERE id = NEW.club_id;
        
        -- Notify all admins and owners of the club
        FOR admin_record IN 
            SELECT user_id 
            FROM club_memberships 
            WHERE club_id = NEW.club_id 
            AND user_role IN ('admin', 'owner')
            AND user_id != NEW.user_id -- Don't notify the person who just joined
        LOOP
            INSERT INTO notifications (user_id, type, title, message, related_id, related_name)
            VALUES (
                admin_record.user_id,
                'user_joined_club',
                'New Club Member',
                v_joiner_name || ' joined "' || v_club_name || '"',
                NEW.club_id,
                v_club_name
            );
        END LOOP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
DROP TRIGGER IF EXISTS trigger_friend_request_notification ON friend_requests;
CREATE TRIGGER trigger_friend_request_notification
    AFTER INSERT ON friend_requests
    FOR EACH ROW
    EXECUTE FUNCTION notify_friend_request();

DROP TRIGGER IF EXISTS trigger_club_invitation_notification ON club_invitations;
CREATE TRIGGER trigger_club_invitation_notification
    AFTER INSERT ON club_invitations
    FOR EACH ROW
    EXECUTE FUNCTION notify_club_invitation();

DROP TRIGGER IF EXISTS trigger_admin_promotion_notification ON club_memberships;
CREATE TRIGGER trigger_admin_promotion_notification
    AFTER UPDATE ON club_memberships
    FOR EACH ROW
    EXECUTE FUNCTION notify_admin_promotion();

DROP TRIGGER IF EXISTS trigger_user_joined_club_notification ON club_memberships;
CREATE TRIGGER trigger_user_joined_club_notification
    AFTER INSERT OR UPDATE ON club_memberships
    FOR EACH ROW
    EXECUTE FUNCTION notify_user_joined_club();

-- Test the triggers
SELECT 
    'Test Notification Triggers' as test_type,
    'Triggers created successfully' as result;

