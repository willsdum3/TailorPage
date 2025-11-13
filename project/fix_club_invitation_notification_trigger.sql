-- Fix club invitation notification trigger
-- Ensure notifications are created when users are invited to book clubs

-- Drop the old trigger if it exists
DROP TRIGGER IF EXISTS trigger_club_invitation_notification ON club_invitations;

-- Update the notification function to work with club_invitations table
CREATE OR REPLACE FUNCTION notify_club_invitation()
RETURNS TRIGGER AS $$
DECLARE
    v_inviter_name TEXT;
    v_club_name TEXT;
BEGIN
    -- Only create notification for pending invitations
    IF NEW.status != 'pending' THEN
        RETURN NEW;
    END IF;
    
    -- Get inviter name (using inviter_id, not invited_by)
    SELECT COALESCE(NULLIF(BTRIM(name), ''), NULLIF(BTRIM(username), ''), 'Unknown') INTO v_inviter_name
    FROM users 
    WHERE id = NEW.inviter_id;
    
    -- Get club name
    SELECT name INTO v_club_name
    FROM book_clubs 
    WHERE id = NEW.club_id;
    
    -- Create notification for the invited user (using invitee_id, not user_id)
    INSERT INTO notifications (user_id, type, title, message, related_id, related_name)
    VALUES (
        NEW.invitee_id,
        'club_invitation',
        'Book Club Invitation',
        COALESCE(v_inviter_name, 'Someone') || ' invited you to join "' || COALESCE(v_club_name, 'a book club') || '"',
        NEW.club_id,  -- related_id is the club's ID
        v_club_name
    );
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't fail the transaction
        RAISE WARNING 'Error creating club invitation notification: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

-- Create trigger on club_invitations table
CREATE TRIGGER trigger_club_invitation_notification
    AFTER INSERT ON club_invitations
    FOR EACH ROW
    WHEN (NEW.status = 'pending')
    EXECUTE FUNCTION notify_club_invitation();

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION notify_club_invitation() TO authenticated;
GRANT EXECUTE ON FUNCTION notify_club_invitation() TO anon;

