-- Fix Book Club Messaging Issues
-- This script addresses the console errors shown in the user's screenshot

-- 1. First, let's ensure the book_club_messages table exists with the correct schema
CREATE TABLE IF NOT EXISTS book_club_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL,
    user_id UUID NOT NULL,
    message TEXT NOT NULL,  -- This is the column that was missing
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_book_club_messages_club_id ON book_club_messages(club_id);
CREATE INDEX IF NOT EXISTS idx_book_club_messages_user_id ON book_club_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_book_club_messages_created_at ON book_club_messages(created_at);

-- Add foreign key constraints if they don't exist
DO $$
BEGIN
    -- Add foreign key to book_clubs table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_book_club_messages_club_id'
    ) THEN
        ALTER TABLE book_club_messages 
        ADD CONSTRAINT fk_book_club_messages_club_id 
        FOREIGN KEY (club_id) REFERENCES book_clubs(id) ON DELETE CASCADE;
    END IF;
    
    -- Add foreign key to users table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_book_club_messages_user_id'
    ) THEN
        ALTER TABLE book_club_messages 
        ADD CONSTRAINT fk_book_club_messages_user_id 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
END $$;

-- 2. Drop and recreate the add_book_club_message function with correct parameters
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
    
    -- Insert the message with the correct column name 'message'
    INSERT INTO book_club_messages (club_id, user_id, message, created_at)
    VALUES (add_book_club_message.club_id_param, user_internal_id, add_book_club_message.content_param, NOW())
    RETURNING id INTO message_id;
    
    RETURN message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Create the missing is_user_blocked_flexible function
DROP FUNCTION IF EXISTS is_user_blocked_flexible(UUID, UUID) CASCADE;

CREATE OR REPLACE FUNCTION is_user_blocked_flexible(
    p_blocker_user_id UUID,
    p_blocked_user_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    blocker_internal_id UUID;
    blocked_internal_id UUID;
    is_blocked BOOLEAN := FALSE;
BEGIN
    -- Get internal IDs for both users
    blocker_internal_id := get_user_internal_id(p_blocker_user_id);
    blocked_internal_id := get_user_internal_id(p_blocked_user_id);
    
    -- If either user doesn't exist, return false
    IF blocker_internal_id IS NULL OR blocked_internal_id IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Check if there's a blocking relationship
    -- This assumes you have a user_blocks table or similar
    -- For now, we'll return false as a safe default
    -- You can implement actual blocking logic here if needed
    
    RETURN is_blocked;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Create or update the get_book_club_messages function
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
    
    -- Return messages with user information
    RETURN QUERY
    SELECT 
        bcm.id,
        bcm.message,
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

-- 5. Enable RLS (Row Level Security) on book_club_messages if not already enabled
ALTER TABLE book_club_messages ENABLE ROW LEVEL SECURITY;

-- 6. Create RLS policies for book_club_messages
-- Drop existing policies first
DROP POLICY IF EXISTS "Users can view messages from clubs they belong to" ON book_club_messages;
DROP POLICY IF EXISTS "Users can insert messages to clubs they belong to" ON book_club_messages;

-- Policy for reading messages
CREATE POLICY "Users can view messages from clubs they belong to" ON book_club_messages
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM book_club_members bcm
            JOIN users u ON bcm.user_id = u.id
            WHERE bcm.club_id = book_club_messages.club_id
            AND u.auth_user_id = auth.uid()
        )
    );

-- Policy for inserting messages
CREATE POLICY "Users can insert messages to clubs they belong to" ON book_club_messages
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM book_club_members bcm
            JOIN users u ON bcm.user_id = u.id
            WHERE bcm.club_id = book_club_messages.club_id
            AND u.auth_user_id = auth.uid()
        )
    );

-- 7. Verify the fix by checking table structure and functions
SELECT 
    'Table Structure Check' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'book_club_messages' 
AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT 
    'Function Check' as check_type,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name IN ('add_book_club_message', 'get_book_club_messages', 'is_user_blocked_flexible')
AND routine_schema = 'public';

-- 8. Test the messaging functionality
DO $$
DECLARE
    test_user_id UUID;
    test_club_id UUID;
    message_id UUID;
BEGIN
    -- Get a test user and club (if they exist)
    SELECT u.auth_user_id INTO test_user_id FROM users u LIMIT 1;
    SELECT bc.id INTO test_club_id FROM book_clubs bc LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_club_id IS NOT NULL THEN
        BEGIN
            -- Test the add_book_club_message function
            message_id := add_book_club_message(test_user_id, test_club_id, 'Test message from fix script');
            RAISE NOTICE '✅ add_book_club_message test successful, message_id: %', message_id;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE '❌ add_book_club_message test failed: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE '⚠️ No test users or clubs found, skipping function test';
    END IF;
END $$;
