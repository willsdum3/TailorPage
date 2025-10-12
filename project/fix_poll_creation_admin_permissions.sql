-- Fix Poll Creation Admin Permissions
-- Create proper create_book_selection_poll function with correct admin permissions

-- Drop the existing function if it exists
DROP FUNCTION IF EXISTS create_book_selection_poll(UUID, UUID, TEXT, TEXT, JSONB, TIMESTAMP WITH TIME ZONE) CASCADE;

-- Create the create_book_selection_poll function with proper admin permissions
CREATE OR REPLACE FUNCTION create_book_selection_poll(
    auth_user_id UUID,
    club_id_param UUID,
    poll_title TEXT,
    poll_description TEXT DEFAULT NULL,
    book_options JSONB DEFAULT NULL,
    closes_at TIMESTAMP WITH TIME ZONE DEFAULT NULL
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    poll_id UUID
) AS $$
DECLARE
    user_internal_id UUID;
    club_exists BOOLEAN;
    is_admin BOOLEAN;
    is_creator BOOLEAN;
    new_poll_id UUID;
    option_data JSONB;
    i INTEGER;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'User not found'::TEXT, NULL::UUID;
        RETURN;
    END IF;
    
    -- Check if club exists
    SELECT EXISTS(SELECT 1 FROM book_clubs WHERE id = club_id_param) INTO club_exists;
    
    IF NOT club_exists THEN
        RETURN QUERY SELECT FALSE, 'Book club not found'::TEXT, NULL::UUID;
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
    
    -- Allow poll creation if user is creator OR admin
    IF NOT (is_creator OR is_admin) THEN
        RETURN QUERY SELECT FALSE, 'Only admins can create polls'::TEXT, NULL::UUID;
        RETURN;
    END IF;
    
    -- Validate required fields
    IF poll_title IS NULL OR TRIM(poll_title) = '' THEN
        RETURN QUERY SELECT FALSE, 'Poll title is required'::TEXT, NULL::UUID;
        RETURN;
    END IF;
    
    IF book_options IS NULL OR jsonb_array_length(book_options) < 2 THEN
        RETURN QUERY SELECT FALSE, 'At least 2 book options are required'::TEXT, NULL::UUID;
        RETURN;
    END IF;
    
    -- Generate new poll ID
    new_poll_id := gen_random_uuid();
    
    -- Insert the poll
    INSERT INTO book_selection_polls (
        id,
        club_id,
        title,
        description,
        created_by,
        closes_at,
        created_at,
        updated_at
    ) VALUES (
        new_poll_id,
        club_id_param,
        TRIM(poll_title),
        poll_description,
        user_internal_id,
        closes_at,
        NOW(),
        NOW()
    );
    
    -- Insert poll options
    FOR i IN 0..jsonb_array_length(book_options) - 1 LOOP
        option_data := book_options->i;
        
        INSERT INTO poll_options (
            id,
            poll_id,
            option_index,
            title,
            author,
            cover_url,
            description,
            created_at
        ) VALUES (
            gen_random_uuid(),
            new_poll_id,
            i,
            option_data->>'title',
            option_data->>'author',
            option_data->>'coverUrl',
            option_data->>'description',
            NOW()
        );
    END LOOP;
    
    -- Return success
    RETURN QUERY SELECT TRUE, 'Poll created successfully'::TEXT, new_poll_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the function
DO $$
DECLARE
    test_user_id UUID;
    test_club_id UUID;
    test_result RECORD;
    test_options JSONB;
BEGIN
    -- Get test data
    SELECT u.auth_user_id INTO test_user_id FROM users u WHERE u.name = 'Kat Slater' LIMIT 1;
    SELECT bc.id INTO test_club_id FROM book_clubs bc LIMIT 1;
    
    -- Create test book options
    test_options := '[
        {"title": "Test Book 1", "author": "Author 1", "description": "Test description 1"},
        {"title": "Test Book 2", "author": "Author 2", "description": "Test description 2"}
    ]'::jsonb;
    
    IF test_user_id IS NOT NULL AND test_club_id IS NOT NULL THEN
        RAISE NOTICE 'Testing create_book_selection_poll function...';
        RAISE NOTICE 'User: %, Club: %', test_user_id, test_club_id;
        
        -- Test the function
        FOR test_result IN 
            SELECT * FROM create_book_selection_poll(
                test_user_id, 
                test_club_id, 
                'Test Poll Title', 
                'Test Poll Description',
                test_options,
                NOW() + INTERVAL '7 days'
            )
        LOOP
            RAISE NOTICE 'Result: success=%, message=%, poll_id=%', 
                test_result.success, test_result.message, test_result.poll_id;
        END LOOP;
    ELSE
        RAISE NOTICE 'No test data found';
    END IF;
END $$;

-- Show the function signature
SELECT 
    'Create Book Selection Poll Function' as check_type,
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_name = 'create_book_selection_poll' 
AND routine_schema = 'public';
