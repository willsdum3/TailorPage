-- Fix Book Club Message Display Issue
-- The error is: column u.image_url does not exist
-- The correct column name is avatar_url

-- Update the get_book_club_messages function to use the correct column name
DROP FUNCTION IF EXISTS get_book_club_messages(UUID, UUID) CASCADE;

CREATE OR REPLACE FUNCTION get_book_club_messages(
    auth_user_id UUID,
    club_id_param UUID
)
RETURNS TABLE (
    id UUID,
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    user_id UUID,
    user_name TEXT,
    user_username TEXT,
    user_image_url TEXT
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
    
    -- Return messages with user information, using the correct column name avatar_url
    RETURN QUERY
    SELECT 
        bcm.id,
        COALESCE(bcm.message, bcm.content) as message, -- Use message first, fallback to content
        bcm.created_at,
        bcm.user_id,
        u.name as user_name,
        u.username as user_username,
        u.avatar_url as user_image_url  -- Fixed: changed from image_url to avatar_url
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
BEGIN
    -- Get test data if available
    SELECT u.auth_user_id INTO test_user_id FROM users u LIMIT 1;
    SELECT bc.id INTO test_club_id FROM book_clubs bc LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_club_id IS NOT NULL THEN
        BEGIN
            -- Test the get_book_club_messages function
            PERFORM * FROM get_book_club_messages(test_user_id, test_club_id);
            RAISE NOTICE '✅ get_book_club_messages test successful';
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE '❌ get_book_club_messages test failed: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE '⚠️ No test data available for function test';
    END IF;
END $$;

-- Show the users table structure to confirm column names
SELECT 
    'Users Table Structure' as check_type,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'public'
ORDER BY ordinal_position;
