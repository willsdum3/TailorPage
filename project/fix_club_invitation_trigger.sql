-- Fix the club invitation trigger function that's causing the "invited_by" error

-- 1. First, let's see what triggers exist on club_invitations
SELECT 
    'Current Triggers on club_invitations' as check_type,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table = 'club_invitations';

-- 2. Drop the problematic trigger function
DROP FUNCTION IF EXISTS notify_club_invitation();

-- 3. Create the corrected trigger function using the correct field names
CREATE OR REPLACE FUNCTION notify_club_invitation()
RETURNS TRIGGER AS $$
DECLARE
    v_inviter_name TEXT;
    v_club_name TEXT;
BEGIN
    -- Get inviter name using the correct field name (inviter_id, not invited_by)
    SELECT name INTO v_inviter_name
    FROM users 
    WHERE id = NEW.inviter_id;
    
    -- Get club name
    SELECT name INTO v_club_name
    FROM book_clubs 
    WHERE id = NEW.club_id;
    
    -- Create notification for the invited user using the correct field name (invitee_id, not user_id)
    INSERT INTO notifications (user_id, type, title, message, related_id, related_name)
    VALUES (
        NEW.invitee_id,
        'club_invitation',
        'Book Club Invitation',
        v_inviter_name || ' invited you to join "' || v_club_name || '"',
        NEW.club_id,
        v_club_name
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Recreate the trigger (it should automatically recreate if it was dropped with the function)
-- But let's be explicit and drop/recreate it
DROP TRIGGER IF EXISTS trigger_notify_club_invitation ON club_invitations;

CREATE TRIGGER trigger_notify_club_invitation
    AFTER INSERT ON club_invitations
    FOR EACH ROW
    EXECUTE FUNCTION notify_club_invitation();

-- 5. Verify the trigger was created correctly
SELECT 
    'Updated Triggers on club_invitations' as check_type,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table = 'club_invitations';

-- 6. Test the trigger function by checking its definition
SELECT 
    'Fixed Trigger Function Definition' as check_type,
    routine_name,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name = 'notify_club_invitation';
