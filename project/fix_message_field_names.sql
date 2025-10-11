-- Fix Book Club Message Field Names
-- The frontend expects specific field names that don't match our function return

-- Update the get_book_club_messages function to return the correct field names
DROP FUNCTION IF EXISTS get_book_club_messages(UUID, UUID) CASCADE;

CREATE OR REPLACE FUNCTION get_book_club_messages(
    auth_user_id UUID,
    club_id_param UUID
)
RETURNS TABLE (
    id UUID,
    content TEXT,  -- Changed from 'message' to 'content'
    created_at TIMESTAMP WITH TIME ZONE,
    user_id UUID,
    name TEXT,     -- Changed from 'user_name' to 'name'
    username TEXT, -- Changed from 'user_username' to 'username'
    avatar_url TEXT -- Changed from 'user_image_url' to 'avatar_url'
) AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if user is a member of the club
    IF NOT EXISTS (
        SELECT 1 FROM book_club_members bcm
        WHERE bcm.club_id = get_book_club_messages.club_id_param 
        AND bcm.user_id = user_internal_id
    ) THEN
        RAISE EXCEPTION 'User is not a member of this club';
    END IF;
    
    -- Return messages with user information, using the correct field names expected by frontend
    RETURN QUERY
    SELECT 
        bcm.id,
        COALESCE(bcm.message, bcm.content) as content, -- Use message first, fallback to content
        bcm.created_at,
        bcm.user_id,
        u.name,           -- Frontend expects 'name'
        u.username,       -- Frontend expects 'username'
        u.avatar_url      -- Frontend expects 'avatar_url'
    FROM book_club_messages bcm
    JOIN users u ON bcm.user_id = u.id
    WHERE bcm.club_id = get_book_club_messages.club_id_param
    ORDER BY bcm.created_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the fix
DO $$
DECLARE
    test_user_id UUID;
    test_club_id UUID;
    test_result RECORD;
BEGIN
    -- Get test data if available
    SELECT u.auth_user_id INTO test_user_id FROM users u LIMIT 1;
    SELECT bc.id INTO test_club_id FROM book_clubs bc LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_club_id IS NOT NULL THEN
        BEGIN
            -- Test the get_book_club_messages function and show the structure
            FOR test_result IN 
                SELECT * FROM get_book_club_messages(test_user_id, test_club_id) LIMIT 1
            LOOP
                RAISE NOTICE '✅ Function test successful';
                RAISE NOTICE 'Sample message structure: id=%, content=%, name=%, username=%, avatar_url=%', 
                    test_result.id, 
                    COALESCE(test_result.content, 'NULL'), 
                    COALESCE(test_result.name, 'NULL'), 
                    COALESCE(test_result.username, 'NULL'), 
                    COALESCE(test_result.avatar_url, 'NULL');
                EXIT; -- Only show first result
            END LOOP;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE '❌ Function test failed: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE '⚠️ No test data available for function test';
    END IF;
END $$;

-- Show the function signature to confirm the return fields
SELECT 
    'Function Return Fields' as check_type,
    parameter_name,
    data_type
FROM information_schema.parameters 
WHERE specific_name IN (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_name = 'get_book_club_messages' 
    AND routine_schema = 'public'
    AND parameter_mode = 'OUT'
)
ORDER BY ordinal_position;
