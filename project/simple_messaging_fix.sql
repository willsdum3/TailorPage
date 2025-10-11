-- Simple Fix for Missing Message Column
-- This is a minimal fix that just adds the missing 'message' column

-- Check current table structure
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'book_club_messages' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Add the missing message column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'book_club_messages' 
        AND column_name = 'message' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE book_club_messages ADD COLUMN message TEXT;
        RAISE NOTICE 'Added message column to book_club_messages table';
    ELSE
        RAISE NOTICE 'Message column already exists';
    END IF;
END $$;

-- Verify the fix
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'book_club_messages' 
AND table_schema = 'public'
ORDER BY ordinal_position;
