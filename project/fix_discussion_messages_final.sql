-- Final Fix for Discussion Messages Table Structure
-- Clean version without problematic ROLLBACK commands

-- Step 1: Check current table structure
SELECT 
    'Current Table Structure' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'discussion_messages' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Step 2: Create the table if it doesn't exist
CREATE TABLE IF NOT EXISTS discussion_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    discussion_id UUID NOT NULL,
    user_id UUID NOT NULL,
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 3: Add the message column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'discussion_messages' 
        AND column_name = 'message' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE discussion_messages ADD COLUMN message TEXT;
        RAISE NOTICE 'Added message column to discussion_messages table';
    ELSE
        RAISE NOTICE 'Message column already exists in discussion_messages table';
    END IF;
END $$;

-- Step 4: Handle existing NULL values and make column NOT NULL
DO $$
DECLARE
    null_count INTEGER;
BEGIN
    -- Count existing NULL values
    SELECT COUNT(*) INTO null_count
    FROM discussion_messages 
    WHERE message IS NULL;
    
    IF null_count > 0 THEN
        -- Update existing NULL values
        UPDATE discussion_messages 
        SET message = 'Legacy message' 
        WHERE message IS NULL;
        
        RAISE NOTICE 'Updated % NULL message values to default text', null_count;
    ELSE
        RAISE NOTICE 'No NULL message values found';
    END IF;
    
    -- Now make the column NOT NULL
    ALTER TABLE discussion_messages ALTER COLUMN message SET NOT NULL;
    RAISE NOTICE 'Made message column NOT NULL';
    
END $$;

-- Step 5: Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_discussion_messages_discussion_id ON discussion_messages(discussion_id);
CREATE INDEX IF NOT EXISTS idx_discussion_messages_user_id ON discussion_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_discussion_messages_created_at ON discussion_messages(created_at);

-- Step 6: Add foreign key constraints if they don't exist
DO $$
BEGIN
    -- Add foreign key to discussions table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_discussion_messages_discussion_id'
        AND table_name = 'discussion_messages'
    ) THEN
        BEGIN
            ALTER TABLE discussion_messages 
            ADD CONSTRAINT fk_discussion_messages_discussion_id 
            FOREIGN KEY (discussion_id) REFERENCES discussions(id) ON DELETE CASCADE;
            RAISE NOTICE 'Added foreign key constraint to discussions table';
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Could not add foreign key to discussions: %', SQLERRM;
        END;
    END IF;
    
    -- Add foreign key to users table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_discussion_messages_user_id'
        AND table_name = 'discussion_messages'
    ) THEN
        BEGIN
            ALTER TABLE discussion_messages 
            ADD CONSTRAINT fk_discussion_messages_user_id 
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
            RAISE NOTICE 'Added foreign key constraint to users table';
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Could not add foreign key to users: %', SQLERRM;
        END;
    END IF;
END $$;

-- Step 7: Enable RLS and create policies
ALTER TABLE discussion_messages ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view messages from discussions they belong to" ON discussion_messages;
DROP POLICY IF EXISTS "Users can insert messages to discussions they belong to" ON discussion_messages;

-- Create RLS policies
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

-- Step 8: Verify the final table structure
SELECT 
    'Final Table Structure' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'discussion_messages' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Step 9: Show final verification
SELECT 
    'SUCCESS' as status,
    'discussion_messages table is ready for messaging' as message,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'discussion_messages' AND table_schema = 'public') as column_count;
