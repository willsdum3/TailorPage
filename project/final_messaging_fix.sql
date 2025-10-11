-- Final Fix for Book Club Messaging
-- This addresses the content vs message column issue

-- First, let's see the exact current state
SELECT 
    'Current Table Structure' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'book_club_messages' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- The issue is that we have both 'content' and 'message' columns
-- The function is trying to insert into 'message' but there might be a NOT NULL constraint on 'content'
-- Let's fix this by either:
-- 1. Making the content column nullable, OR
-- 2. Updating the function to populate both columns, OR  
-- 3. Dropping the content column if it's not needed

-- Option 1: Make content column nullable and set a default
DO $$
BEGIN
    -- Check if content column has a NOT NULL constraint
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'book_club_messages' 
        AND column_name = 'content' 
        AND table_schema = 'public'
        AND is_nullable = 'NO'
    ) THEN
        -- Make content column nullable
        ALTER TABLE book_club_messages ALTER COLUMN content DROP NOT NULL;
        RAISE NOTICE 'Made content column nullable';
    END IF;
END $$;

-- Option 2: Update the function to populate both columns
DROP FUNCTION IF EXISTS add_book_club_message(UUID, UUID, TEXT) CASCADE;

CREATE OR REPLACE FUNCTION add_book_club_message(
    auth_user_id UUID,
    club_id_param UUID,
    content_param TEXT
)
RETURNS UUID AS $$
DECLARE
    user_internal_id UUID;
    message_id UUID;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if user is a member of the club
    IF NOT EXISTS (
        SELECT 1 FROM book_club_members bcm
        WHERE bcm.club_id = add_book_club_message.club_id_param 
        AND bcm.user_id = user_internal_id
    ) THEN
        RAISE EXCEPTION 'User is not a member of this club';
    END IF;
    
    -- Insert the message into BOTH content and message columns to be safe
    INSERT INTO book_club_messages (club_id, user_id, content, message, created_at)
    VALUES (
        add_book_club_message.club_id_param, 
        user_internal_id, 
        add_book_club_message.content_param,
        add_book_club_message.content_param,
        NOW()
    )
    RETURNING id INTO message_id;
    
    RETURN message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Also update the get_book_club_messages function to read from the message column
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
    
    -- Return messages with user information, using COALESCE to handle both columns
    RETURN QUERY
    SELECT 
        bcm.id,
        COALESCE(bcm.message, bcm.content) as message, -- Use message first, fallback to content
        bcm.created_at,
        bcm.user_id,
        u.name as user_name,
        u.username as user_username,
        u.image_url as user_image_url
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
    message_id UUID;
BEGIN
    -- Get test data if available
    SELECT u.auth_user_id INTO test_user_id FROM users u LIMIT 1;
    SELECT bc.id INTO test_club_id FROM book_clubs bc LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_club_id IS NOT NULL THEN
        BEGIN
            -- Test the add_book_club_message function
            message_id := add_book_club_message(test_user_id, test_club_id, 'Test message from final fix');
            RAISE NOTICE '✅ add_book_club_message test successful, message_id: %', message_id;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE '❌ add_book_club_message test failed: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE '⚠️ No test data available for function test';
    END IF;
END $$;

-- Show the final table structure
SELECT 
    'Final Table Structure' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'book_club_messages' 
AND table_schema = 'public'
ORDER BY ordinal_position;
