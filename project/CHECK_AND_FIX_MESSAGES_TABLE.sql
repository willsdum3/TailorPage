-- Check if book_club_messages table exists and has correct structure
-- If not, create/fix it

-- First, check if table exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'book_club_messages') THEN
        RAISE NOTICE 'book_club_messages table does not exist - creating it...';
        
        CREATE TABLE book_club_messages (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            club_id UUID NOT NULL REFERENCES book_clubs(id) ON DELETE CASCADE,
            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            content TEXT,
            message TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        CREATE INDEX idx_book_club_messages_club_id ON book_club_messages(club_id);
        CREATE INDEX idx_book_club_messages_user_id ON book_club_messages(user_id);
        CREATE INDEX idx_book_club_messages_created_at ON book_club_messages(created_at DESC);
        
        RAISE NOTICE 'book_club_messages table created';
    ELSE
        RAISE NOTICE 'book_club_messages table exists';
        
        -- Ensure content and message columns exist
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'book_club_messages' AND column_name = 'content') THEN
            ALTER TABLE book_club_messages ADD COLUMN content TEXT;
            RAISE NOTICE 'Added content column';
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'book_club_messages' AND column_name = 'message') THEN
            ALTER TABLE book_club_messages ADD COLUMN message TEXT;
            RAISE NOTICE 'Added message column';
        END IF;
    END IF;
END $$;

-- Show table structure
SELECT 
    'book_club_messages structure' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'book_club_messages'
AND table_schema = 'public'
ORDER BY ordinal_position;
