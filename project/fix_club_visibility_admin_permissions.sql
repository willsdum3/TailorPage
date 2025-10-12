-- Fix Club Visibility Admin Permissions
-- Create proper toggle_book_club_visibility function with correct admin permissions

-- Drop the existing function if it exists
DROP FUNCTION IF EXISTS toggle_book_club_visibility(UUID, UUID, BOOLEAN) CASCADE;

-- Create the toggle_book_club_visibility function with proper admin permissions
CREATE OR REPLACE FUNCTION toggle_book_club_visibility(
    auth_user_id UUID,
    club_id_param UUID,
    is_public_param BOOLEAN
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    user_internal_id UUID;
    club_exists BOOLEAN;
    is_admin BOOLEAN;
    is_creator BOOLEAN;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'User not found'::TEXT;
        RETURN;
    END IF;
    
    -- Check if club exists
    SELECT EXISTS(SELECT 1 FROM book_clubs WHERE id = club_id_param) INTO club_exists;
    
    IF NOT club_exists THEN
        RETURN QUERY SELECT FALSE, 'Book club not found'::TEXT;
        RETURN;
    END IF;
    
    -- Check if user is the creator of the club
    SELECT EXISTS(
        SELECT 1 FROM book_clubs 
        WHERE id = club_id_param AND created_by = user_internal_id
    ) INTO is_creator;
    
    -- Check if user is an admin of the club
    SELECT EXISTS(
        SELECT 1 FROM book_club_members 
        WHERE club_id = club_id_param 
        AND user_id = user_internal_id 
        AND role = 'admin'
    ) INTO is_admin;
    
    -- Allow visibility changes if user is creator OR admin
    IF NOT (is_creator OR is_admin) THEN
        RETURN QUERY SELECT FALSE, 'Only admins can change club visibility'::TEXT;
        RETURN;
    END IF;
    
    -- Update the club visibility
    UPDATE book_clubs SET
        is_public = is_public_param,
        updated_at = NOW()
    WHERE id = club_id_param;
    
    -- Return success message with current status
    IF is_public_param THEN
        RETURN QUERY SELECT TRUE, 'Club is now public'::TEXT;
    ELSE
        RETURN QUERY SELECT TRUE, 'Club is now private'::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the function
DO $$
DECLARE
    test_user_id UUID;
    test_club_id UUID;
    test_result RECORD;
BEGIN
    -- Get test data
    SELECT u.auth_user_id INTO test_user_id FROM users u WHERE u.name = 'Kat Slater' LIMIT 1;
    SELECT bc.id INTO test_club_id FROM book_clubs bc LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_club_id IS NOT NULL THEN
        RAISE NOTICE 'Testing toggle_book_club_visibility function...';
        RAISE NOTICE 'User: %, Club: %', test_user_id, test_club_id;
        
        -- Test toggling to private
        FOR test_result IN 
            SELECT * FROM toggle_book_club_visibility(test_user_id, test_club_id, FALSE)
        LOOP
            RAISE NOTICE 'Toggle to private result: success=%, message=%', test_result.success, test_result.message;
        END LOOP;
        
        -- Test toggling to public
        FOR test_result IN 
            SELECT * FROM toggle_book_club_visibility(test_user_id, test_club_id, TRUE)
        LOOP
            RAISE NOTICE 'Toggle to public result: success=%, message=%', test_result.success, test_result.message;
        END LOOP;
    ELSE
        RAISE NOTICE 'No test data found';
    END IF;
END $$;

-- Show the function signature
SELECT 
    'Club Visibility Function' as check_type,
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_name = 'toggle_book_club_visibility' 
AND routine_schema = 'public';
