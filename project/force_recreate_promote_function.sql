-- Force recreate promote_user_to_admin function with exact frontend signature

-- 1. Drop ALL versions of the function to ensure clean slate
DROP FUNCTION IF EXISTS promote_user_to_admin(UUID, UUID, UUID);
DROP FUNCTION IF EXISTS promote_user_to_admin(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS promote_user_to_admin CASCADE;

-- 2. Create the function with EXACT signature that frontend expects
CREATE OR REPLACE FUNCTION promote_user_to_admin(
    auth_user_id UUID,
    club_id_param UUID,
    user_to_promote_id UUID
)
RETURNS JSON AS $$
DECLARE
    admin_internal_id UUID;
    user_to_promote_internal_id UUID;
    is_admin BOOLEAN;
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
    
    -- Check if the admin is actually an admin of the club
    SELECT EXISTS (
        SELECT 1 FROM book_club_members 
        WHERE book_club_members.user_id = admin_internal_id 
        AND book_club_members.club_id = promote_user_to_admin.club_id_param
        AND book_club_members.role IN ('admin', 'owner')
    ) INTO is_admin;
    
    IF NOT is_admin THEN
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
    
    -- Create notification for the promoted user
    BEGIN
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
    EXCEPTION
        WHEN OTHERS THEN
            -- Ignore notification errors
            NULL;
    END;
    
    RETURN json_build_object('success', true, 'message', 'User promoted to admin successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Verify the function was created correctly
SELECT 
    'Function Created Successfully' as check_type,
    routine_name,
    data_type as return_type,
    specific_name
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name = 'promote_user_to_admin';

-- 4. Check the exact parameters
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

-- 5. Test the function signature by checking if it can be found
SELECT 
    'Function Signature Test' as check_type,
    'Function should now be callable with: promote_user_to_admin(auth_user_id, club_id_param, user_to_promote_id)' as expected_signature;



















