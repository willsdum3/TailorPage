-- Check if is_public column exists and add it if missing
DO $$
BEGIN
    -- Check if is_public column exists in book_clubs table
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'book_clubs' 
        AND column_name = 'is_public'
    ) THEN
        -- Add is_public column with default value of true (public)
        ALTER TABLE book_clubs ADD COLUMN is_public BOOLEAN DEFAULT TRUE;
        
        -- Update existing clubs to be public by default
        UPDATE book_clubs SET is_public = TRUE WHERE is_public IS NULL;
        
        -- Make the column NOT NULL after setting default values
        ALTER TABLE book_clubs ALTER COLUMN is_public SET NOT NULL;
        
        RAISE NOTICE 'Added is_public column to book_clubs table';
    ELSE
        RAISE NOTICE 'is_public column already exists in book_clubs table';
    END IF;
END $$;

-- Show the current structure of book_clubs table
SELECT 
    'Book Clubs Table Structure' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'book_clubs'
ORDER BY ordinal_position;
