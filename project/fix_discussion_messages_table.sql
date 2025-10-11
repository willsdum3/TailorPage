-- Fix Discussion Messages Table Structure
-- The error shows: column "message" of relation "discussion_messages" does not exist

-- First, let's check the current table structure
SELECT 
    'Current Discussion Messages Table Structure' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'discussion_messages' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check if the table exists at all
SELECT 
    'Table Existence Check' as check_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'discussion_messages' AND table_schema = 'public') 
        THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as table_status;

-- Create the discussion_messages table if it doesn't exist, or fix the structure
CREATE TABLE IF NOT EXISTS discussion_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    discussion_id UUID NOT NULL,
    user_id UUID NOT NULL,
    message TEXT NOT NULL,  -- This is the column that was missing
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- If the table exists but is missing the 'message' column, add it
DO $$
BEGIN
    -- Check if the message column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'discussion_messages' 
        AND column_name = 'message' 
        AND table_schema = 'public'
    ) THEN
        -- Add the missing message column
        ALTER TABLE discussion_messages ADD COLUMN message TEXT;
        
        -- If there are existing rows, you might want to set a default value
        -- UPDATE discussion_messages SET message = 'Legacy message' WHERE message IS NULL;
        
        -- Make it NOT NULL after setting default values
        ALTER TABLE discussion_messages ALTER COLUMN message SET NOT NULL;
        
        RAISE NOTICE 'Added missing message column to discussion_messages table';
    ELSE
        RAISE NOTICE 'Message column already exists in discussion_messages table';
    END IF;
END $$;

-- Ensure the table has all required columns with correct types
DO $$
BEGIN
    -- Ensure discussion_id column exists and is correct type
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'discussion_messages' 
        AND column_name = 'discussion_id' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE discussion_messages ADD COLUMN discussion_id UUID;
    END IF;
    
    -- Ensure user_id column exists and is correct type
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'discussion_messages' 
        AND column_name = 'user_id' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE discussion_messages ADD COLUMN user_id UUID;
    END IF;
    
    -- Ensure created_at column exists and is correct type
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'discussion_messages' 
        AND column_name = 'created_at' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE discussion_messages ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    
    -- Ensure updated_at column exists and is correct type
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'discussion_messages' 
        AND column_name = 'updated_at' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE discussion_messages ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_discussion_messages_discussion_id ON discussion_messages(discussion_id);
CREATE INDEX IF NOT EXISTS idx_discussion_messages_user_id ON discussion_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_discussion_messages_created_at ON discussion_messages(created_at);

-- Add foreign key constraints if they don't exist
DO $$
BEGIN
    -- Add foreign key to discussions table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_discussion_messages_discussion_id'
        AND table_name = 'discussion_messages'
    ) THEN
        ALTER TABLE discussion_messages 
        ADD CONSTRAINT fk_discussion_messages_discussion_id 
        FOREIGN KEY (discussion_id) REFERENCES discussions(id) ON DELETE CASCADE;
    END IF;
    
    -- Add foreign key to users table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_discussion_messages_user_id'
        AND table_name = 'discussion_messages'
    ) THEN
        ALTER TABLE discussion_messages 
        ADD CONSTRAINT fk_discussion_messages_user_id 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Enable RLS (Row Level Security) on discussion_messages if not already enabled
ALTER TABLE discussion_messages ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for discussion_messages
-- Drop existing policies first
DROP POLICY IF EXISTS "Users can view messages from discussions they belong to" ON discussion_messages;
DROP POLICY IF EXISTS "Users can insert messages to discussions they belong to" ON discussion_messages;

-- Policy for reading messages
CREATE POLICY "Users can view messages from discussions they belong to" ON discussion_messages
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM discussion_members dm
            JOIN users u ON dm.user_id = u.id
            WHERE dm.discussion_id = discussion_messages.discussion_id
            AND u.auth_user_id = auth.uid()
        )
    );

-- Policy for inserting messages
CREATE POLICY "Users can insert messages to discussions they belong to" ON discussion_messages
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM discussion_members dm
            JOIN users u ON dm.user_id = u.id
            WHERE dm.discussion_id = discussion_messages.discussion_id
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
WHERE table_name = 'discussion_messages' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Test the table by trying to insert a test row (this will be rolled back)
DO $$
DECLARE
    test_user_id UUID;
    test_discussion_id UUID;
BEGIN
    -- Get test data if available
    SELECT u.id INTO test_user_id FROM users u LIMIT 1;
    SELECT d.id INTO test_discussion_id FROM discussions d LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_discussion_id IS NOT NULL THEN
        -- Start a transaction to test the insert
        BEGIN
            -- Try to insert a test message
            INSERT INTO discussion_messages (discussion_id, user_id, message, created_at)
            VALUES (test_discussion_id, test_user_id, 'Test message - this will be rolled back', NOW());
            
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
    'discussion_messages table is ready for messaging' as status,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'discussion_messages' AND table_schema = 'public') as column_count;
