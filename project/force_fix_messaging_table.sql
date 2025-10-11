-- Force Fix for Book Club Messaging Table Structure
-- This script specifically addresses the missing 'message' column issue

-- First, let's check what columns currently exist in book_club_messages
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

-- Check if the table exists at all
SELECT 
    'Table Existence Check' as check_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'book_club_messages' AND table_schema = 'public') 
        THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as table_status;

-- If the table doesn't exist, create it with the correct structure
CREATE TABLE IF NOT EXISTS book_club_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL,
    user_id UUID NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- If the table exists but is missing the 'message' column, add it
DO $$
BEGIN
    -- Check if the message column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'book_club_messages' 
        AND column_name = 'message' 
        AND table_schema = 'public'
    ) THEN
        -- Add the missing message column
        ALTER TABLE book_club_messages ADD COLUMN message TEXT;
        
        -- If there are existing rows, you might want to set a default value
        -- UPDATE book_club_messages SET message = 'Legacy message' WHERE message IS NULL;
        
        -- Make it NOT NULL after setting default values
        ALTER TABLE book_club_messages ALTER COLUMN message SET NOT NULL;
        
        RAISE NOTICE 'Added missing message column to book_club_messages table';
    ELSE
        RAISE NOTICE 'Message column already exists in book_club_messages table';
    END IF;
END $$;

-- Ensure the table has all required columns with correct types
DO $$
BEGIN
    -- Ensure club_id column exists and is correct type
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'book_club_messages' 
        AND column_name = 'club_id' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE book_club_messages ADD COLUMN club_id UUID;
    END IF;
    
    -- Ensure user_id column exists and is correct type
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'book_club_messages' 
        AND column_name = 'user_id' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE book_club_messages ADD COLUMN user_id UUID;
    END IF;
    
    -- Ensure created_at column exists and is correct type
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'book_club_messages' 
        AND column_name = 'created_at' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE book_club_messages ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- Create indexes if they don't exist
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
        AND table_name = 'book_club_messages'
    ) THEN
        ALTER TABLE book_club_messages 
        ADD CONSTRAINT fk_book_club_messages_club_id 
        FOREIGN KEY (club_id) REFERENCES book_clubs(id) ON DELETE CASCADE;
    END IF;
    
    -- Add foreign key to users table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_book_club_messages_user_id'
        AND table_name = 'book_club_messages'
    ) THEN
        ALTER TABLE book_club_messages 
        ADD CONSTRAINT fk_book_club_messages_user_id 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Enable RLS if not already enabled
ALTER TABLE book_club_messages ENABLE ROW LEVEL SECURITY;

-- Drop existing policies and recreate them
DROP POLICY IF EXISTS "Users can view messages from clubs they belong to" ON book_club_messages;
DROP POLICY IF EXISTS "Users can insert messages to clubs they belong to" ON book_club_messages;

-- Create RLS policies
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

-- Now let's verify the table structure after the fix
SELECT 
    'Fixed Table Structure' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'book_club_messages' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Test the table by trying to insert a test row (this will be rolled back)
DO $$
DECLARE
    test_user_id UUID;
    test_club_id UUID;
BEGIN
    -- Get test data if available
    SELECT u.id INTO test_user_id FROM users u LIMIT 1;
    SELECT bc.id INTO test_club_id FROM book_clubs bc LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_club_id IS NOT NULL THEN
        -- Start a transaction to test the insert
        BEGIN
            -- Try to insert a test message
            INSERT INTO book_club_messages (club_id, user_id, message, created_at)
            VALUES (test_club_id, test_user_id, 'Test message - this will be rolled back', NOW());
            
            -- If we get here, the insert worked
            RAISE NOTICE '✅ Table structure is correct - test insert successful';
            
            -- Rollback the test insert
            ROLLBACK;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE '❌ Table structure issue - test insert failed: %', SQLERRM;
                ROLLBACK;
        END;
    ELSE
        RAISE NOTICE '⚠️ No test data available for table structure test';
    END IF;
END $$;

-- Final verification - show the complete table structure
SELECT 
    'Final Verification' as check_type,
    'book_club_messages table is ready for messaging' as status,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'book_club_messages' AND table_schema = 'public') as column_count;
