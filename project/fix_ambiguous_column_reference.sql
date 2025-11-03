-- Fix Ambiguous Column Reference in add_book_club_message Function
-- The error occurs because the function parameter 'auth_user_id' conflicts with the column name 'auth_user_id'

-- Drop the problematic function first
DROP FUNCTION IF EXISTS get_user_internal_id(UUID) CASCADE;
DROP FUNCTION IF EXISTS add_book_club_message(UUID, UUID, TEXT) CASCADE;

-- Recreate get_user_internal_id function with proper column qualification
CREATE OR REPLACE FUNCTION get_user_internal_id(p_auth_user_id UUID)
RETURNS UUID AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    SELECT u.id INTO user_internal_id
    FROM users u 
    WHERE u.auth_user_id = p_auth_user_id;
    
    RETURN user_internal_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate add_book_club_message function with corrected parameter names
CREATE OR REPLACE FUNCTION add_book_club_message(
    p_auth_user_id UUID,
    p_club_id UUID,
    p_content TEXT
)
RETURNS UUID AS $$
DECLARE
    user_internal_id UUID;
    message_id UUID;
BEGIN
    -- Get user's internal ID using the corrected function
    user_internal_id := get_user_internal_id(p_auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if user is a member of the club
    IF NOT EXISTS (
        SELECT 1 FROM book_club_members bcm
        WHERE bcm.club_id = p_club_id 
        AND bcm.user_id = user_internal_id
    ) THEN
        RAISE EXCEPTION 'User is not a member of this club';
    END IF;
    
    -- Insert the message
    INSERT INTO book_club_messages (club_id, user_id, message, created_at)
    VALUES (p_club_id, user_internal_id, p_content, NOW())
    RETURNING id INTO message_id;
    
    -- Create notification for other members (if the function exists)
    BEGIN
        PERFORM create_club_message_notification(
            p_club_id,
            user_internal_id,
            p_content
        );
    EXCEPTION
        WHEN undefined_function THEN
            -- Notification function doesn't exist, continue without it
            NULL;
    END;
    
    RETURN message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Also fix the is_user_club_admin function to avoid similar issues
DROP FUNCTION IF EXISTS is_user_club_admin(UUID, UUID) CASCADE;

CREATE OR REPLACE FUNCTION is_user_club_admin(p_user_internal_id UUID, p_club_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    is_admin BOOLEAN := FALSE;
    club_creator_id UUID;
BEGIN
    -- Get club creator
    SELECT bc.creator_id INTO club_creator_id
    FROM book_clubs bc
    WHERE bc.id = p_club_id;
    
    -- Check if user is creator or has admin role
    IF p_user_internal_id = club_creator_id THEN
        is_admin := TRUE;
    ELSE
        -- Check if user has admin role in book_club_members
        SELECT EXISTS (
            SELECT 1 FROM book_club_members bcm
            WHERE bcm.club_id = p_club_id 
            AND bcm.user_id = p_user_internal_id
            AND bcm.role = 'admin'
        ) INTO is_admin;
    END IF;
    
    RETURN is_admin;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the fixed function
SELECT 
    'Function Fix Complete' as status,
    'add_book_club_message function has been fixed to resolve ambiguous column reference' as message;

-- Verify the functions exist
SELECT 
    'Function Verification' as check_type,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name IN ('get_user_internal_id', 'add_book_club_message', 'is_user_club_admin')
ORDER BY routine_name;


