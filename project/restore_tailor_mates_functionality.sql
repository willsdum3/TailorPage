-- Restore Tailor Mates functionality with minimal, working functions

-- 1. Drop all problematic functions and start fresh
DROP FUNCTION IF EXISTS promote_user_to_admin CASCADE;
DROP FUNCTION IF EXISTS promote_member_to_admin CASCADE;
DROP FUNCTION IF EXISTS promote_user_to_admin_v2 CASCADE;

-- 2. Create a simple, working promote function
CREATE OR REPLACE FUNCTION promote_user_to_admin(
    auth_user_id UUID,
    club_id_param UUID,
    user_to_promote_id UUID
)
RETURNS JSON AS $$
DECLARE
    admin_internal_id UUID;
    user_to_promote_internal_id UUID;
BEGIN
    -- Get the internal user ID of the admin
    SELECT id INTO admin_internal_id
    FROM users
    WHERE users.auth_user_id = promote_user_to_admin.auth_user_id;
    
    IF admin_internal_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Admin user not found');
    END IF;
    
    -- user_to_promote_id is already the internal ID from frontend
    user_to_promote_internal_id := promote_user_to_admin.user_to_promote_id;
    
    -- Simple admin check - just check if user is in the club with admin/owner role
    IF NOT EXISTS (
        SELECT 1 FROM book_club_members 
        WHERE book_club_members.user_id = admin_internal_id 
        AND book_club_members.club_id = promote_user_to_admin.club_id_param
        AND book_club_members.role IN ('admin', 'owner')
    ) THEN
        RETURN json_build_object('success', false, 'error', 'You are not an admin of this club');
    END IF;
    
    -- Check if the user to promote is a member of the club
    IF NOT EXISTS (
        SELECT 1 FROM book_club_members 
        WHERE book_club_members.user_id = user_to_promote_internal_id 
        AND book_club_members.club_id = promote_user_to_admin.club_id_param
    ) THEN
        RETURN json_build_object('success', false, 'error', 'User is not a member of this club');
    END IF;
    
    -- Promote the user to admin
    UPDATE book_club_members 
    SET role = 'admin'
    WHERE book_club_members.user_id = user_to_promote_internal_id 
    AND book_club_members.club_id = promote_user_to_admin.club_id_param;
    
    -- Simple notification creation (no complex error handling)
    INSERT INTO notifications (
        user_id,
        type,
        title,
        message,
        related_id,
        related_name
    ) VALUES (
        user_to_promote_internal_id,
        'club_promotion',
        'You have been promoted!',
        'You have been promoted to admin',
        promote_user_to_admin.club_id_param,
        (SELECT name FROM book_clubs WHERE id = promote_user_to_admin.club_id_param)
    );
    
    RETURN json_build_object('success', true, 'message', 'User promoted to admin successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Verify the function was created
SELECT 
    'Function Created' as check_type,
    routine_name,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name = 'promote_user_to_admin';

-- 4. Check parameters
SELECT 
    'Function Parameters' as check_type,
    parameter_name,
    data_type,
    ordinal_position
FROM information_schema.parameters 
WHERE specific_schema = 'public'
AND specific_name IN (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_schema = 'public' 
    AND routine_name = 'promote_user_to_admin'
)
ORDER BY ordinal_position;













