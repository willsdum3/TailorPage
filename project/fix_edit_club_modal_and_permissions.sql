-- Fix Edit Club Modal and Admin Permissions Issues
-- 1. Create proper update_book_club_details function with correct admin permissions
-- 2. Ensure admins can update club details

-- Drop the existing function if it exists
DROP FUNCTION IF EXISTS update_book_club_details(UUID, UUID, TEXT, TEXT, TEXT, TEXT, TEXT) CASCADE;

-- Create the update_book_club_details function with proper admin permissions
CREATE OR REPLACE FUNCTION update_book_club_details(
    auth_user_id UUID,
    club_id_param UUID,
    new_name TEXT DEFAULT NULL,
    new_description TEXT DEFAULT NULL,
    new_current_book_title TEXT DEFAULT NULL,
    new_current_book_author TEXT DEFAULT NULL,
    new_meeting_info TEXT DEFAULT NULL
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
    
    -- Allow updates if user is creator OR admin
    IF NOT (is_creator OR is_admin) THEN
        RETURN QUERY SELECT FALSE, 'Only admins can update club details'::TEXT;
        RETURN;
    END IF;
    
    -- Update the club details
    UPDATE book_clubs SET
        name = COALESCE(new_name, name),
        description = COALESCE(new_description, description),
        current_book_title = COALESCE(new_current_book_title, current_book_title),
        current_book_author = COALESCE(new_current_book_author, current_book_author),
        meeting_info = COALESCE(new_meeting_info, meeting_info),
        updated_at = NOW()
    WHERE id = club_id_param;
    
    -- Return success
    RETURN QUERY SELECT TRUE, 'Club details updated successfully'::TEXT;
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
        RAISE NOTICE 'Testing update_book_club_details function...';
        RAISE NOTICE 'User: %, Club: %', test_user_id, test_club_id;
        
        -- Test the function
        FOR test_result IN 
            SELECT * FROM update_book_club_details(test_user_id, test_club_id, 'Updated Club Name', 'Updated Description')
        LOOP
            RAISE NOTICE 'Result: success=%, message=%', test_result.success, test_result.message;
        END LOOP;
    ELSE
        RAISE NOTICE 'No test data found';
    END IF;
END $$;

-- Show the function signature
SELECT 
    'Update Club Details Function' as check_type,
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_name = 'update_book_club_details' 
AND routine_schema = 'public';
