-- Create missing tables that the functions need
-- Based on the console errors, we need to create several missing tables

-- 1. Create book_club_members table if it doesn't exist
CREATE TABLE IF NOT EXISTS book_club_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL,
    user_id UUID NOT NULL,
    role TEXT DEFAULT 'member' CHECK (role IN ('member', 'admin')),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(club_id, user_id)
);

-- Create indexes for book_club_members
CREATE INDEX IF NOT EXISTS idx_book_club_members_club_id ON book_club_members(club_id);
CREATE INDEX IF NOT EXISTS idx_book_club_members_user_id ON book_club_members(user_id);
CREATE INDEX IF NOT EXISTS idx_book_club_members_role ON book_club_members(role);

-- 2. Create book_club_messages table if it doesn't exist
CREATE TABLE IF NOT EXISTS book_club_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL,
    user_id UUID NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for book_club_messages
CREATE INDEX IF NOT EXISTS idx_book_club_messages_club_id ON book_club_messages(club_id);
CREATE INDEX IF NOT EXISTS idx_book_club_messages_user_id ON book_club_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_book_club_messages_created_at ON book_club_messages(created_at);

-- 3. Create discussion_members table if it doesn't exist
CREATE TABLE IF NOT EXISTS discussion_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    discussion_id UUID NOT NULL,
    user_id UUID NOT NULL,
    role TEXT DEFAULT 'member' CHECK (role IN ('member', 'admin')),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(discussion_id, user_id)
);

-- Create indexes for discussion_members
CREATE INDEX IF NOT EXISTS idx_discussion_members_discussion_id ON discussion_members(discussion_id);
CREATE INDEX IF NOT EXISTS idx_discussion_members_user_id ON discussion_members(user_id);
CREATE INDEX IF NOT EXISTS idx_discussion_members_role ON discussion_members(role);

-- 4. Create discussion_messages table if it doesn't exist
CREATE TABLE IF NOT EXISTS discussion_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    discussion_id UUID NOT NULL,
    user_id UUID NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for discussion_messages
CREATE INDEX IF NOT EXISTS idx_discussion_messages_discussion_id ON discussion_messages(discussion_id);
CREATE INDEX IF NOT EXISTS idx_discussion_messages_user_id ON discussion_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_discussion_messages_created_at ON discussion_messages(created_at);

-- 5. Check if book_clubs table has creator_id column, if not add it
DO $$
BEGIN
    -- Check if creator_id column exists in book_clubs table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'book_clubs' 
        AND table_schema = 'public' 
        AND column_name = 'creator_id'
    ) THEN
        -- Add creator_id column
        ALTER TABLE book_clubs ADD COLUMN creator_id UUID;
        
        -- Create index on creator_id
        CREATE INDEX IF NOT EXISTS idx_book_clubs_creator_id ON book_clubs(creator_id);
        
        RAISE NOTICE 'Added creator_id column to book_clubs table';
    ELSE
        RAISE NOTICE 'creator_id column already exists in book_clubs table';
    END IF;
END $$;

-- 6. Add foreign key constraints if the referenced tables exist
DO $$
BEGIN
    -- Add foreign key constraints for book_club_members
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'book_clubs' AND table_schema = 'public') THEN
        BEGIN
            ALTER TABLE book_club_members 
            ADD CONSTRAINT fk_book_club_members_club_id 
            FOREIGN KEY (club_id) REFERENCES book_clubs(id) ON DELETE CASCADE;
        EXCEPTION
            WHEN duplicate_object THEN
                RAISE NOTICE 'Foreign key constraint fk_book_club_members_club_id already exists';
        END;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') THEN
        BEGIN
            ALTER TABLE book_club_members 
            ADD CONSTRAINT fk_book_club_members_user_id 
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
        EXCEPTION
            WHEN duplicate_object THEN
                RAISE NOTICE 'Foreign key constraint fk_book_club_members_user_id already exists';
        END;
    END IF;
    
    -- Add foreign key constraints for book_club_messages
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'book_clubs' AND table_schema = 'public') THEN
        BEGIN
            ALTER TABLE book_club_messages 
            ADD CONSTRAINT fk_book_club_messages_club_id 
            FOREIGN KEY (club_id) REFERENCES book_clubs(id) ON DELETE CASCADE;
        EXCEPTION
            WHEN duplicate_object THEN
                RAISE NOTICE 'Foreign key constraint fk_book_club_messages_club_id already exists';
        END;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') THEN
        BEGIN
            ALTER TABLE book_club_messages 
            ADD CONSTRAINT fk_book_club_messages_user_id 
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
        EXCEPTION
            WHEN duplicate_object THEN
                RAISE NOTICE 'Foreign key constraint fk_book_club_messages_user_id already exists';
        END;
    END IF;
    
    -- Add foreign key constraints for discussion_members
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'discussions' AND table_schema = 'public') THEN
        BEGIN
            ALTER TABLE discussion_members 
            ADD CONSTRAINT fk_discussion_members_discussion_id 
            FOREIGN KEY (discussion_id) REFERENCES discussions(id) ON DELETE CASCADE;
        EXCEPTION
            WHEN duplicate_object THEN
                RAISE NOTICE 'Foreign key constraint fk_discussion_members_discussion_id already exists';
        END;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') THEN
        BEGIN
            ALTER TABLE discussion_members 
            ADD CONSTRAINT fk_discussion_members_user_id 
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
        EXCEPTION
            WHEN duplicate_object THEN
                RAISE NOTICE 'Foreign key constraint fk_discussion_members_user_id already exists';
        END;
    END IF;
    
    -- Add foreign key constraints for discussion_messages
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'discussions' AND table_schema = 'public') THEN
        BEGIN
            ALTER TABLE discussion_messages 
            ADD CONSTRAINT fk_discussion_messages_discussion_id 
            FOREIGN KEY (discussion_id) REFERENCES discussions(id) ON DELETE CASCADE;
        EXCEPTION
            WHEN duplicate_object THEN
                RAISE NOTICE 'Foreign key constraint fk_discussion_messages_discussion_id already exists';
        END;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') THEN
        BEGIN
            ALTER TABLE discussion_messages 
            ADD CONSTRAINT fk_discussion_messages_user_id 
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
        EXCEPTION
            WHEN duplicate_object THEN
                RAISE NOTICE 'Foreign key constraint fk_discussion_messages_user_id already exists';
        END;
    END IF;
END $$;

-- Verify all tables were created
SELECT 
    'Tables created successfully' as status,
    COUNT(*) as table_count
FROM information_schema.tables 
WHERE table_schema = 'public'
AND table_name IN (
    'book_club_members',
    'book_club_messages', 
    'discussion_members',
    'discussion_messages'
);




















