-- Create club_invitations table (minimal version - no RLS, no policies)
-- This table stores invitations sent to users to join book clubs

-- Create the table with absolutely minimal setup
CREATE TABLE IF NOT EXISTS club_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL,
    invited_user_id UUID NOT NULL,
    invited_by_user_id UUID NOT NULL,
    message TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    responded_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(club_id, invited_user_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_club_invitations_club_id ON club_invitations(club_id);
CREATE INDEX IF NOT EXISTS idx_club_invitations_invited_user_id ON club_invitations(invited_user_id);
CREATE INDEX IF NOT EXISTS idx_club_invitations_status ON club_invitations(status);

-- DO NOT enable RLS for now - we'll add it later
-- ALTER TABLE club_invitations ENABLE ROW LEVEL SECURITY;

-- Add foreign key constraints after table creation (if the referenced tables exist)
DO $$
BEGIN
    -- Add foreign key to book_clubs if the table exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'book_clubs' AND table_schema = 'public') THEN
        BEGIN
            ALTER TABLE club_invitations 
            ADD CONSTRAINT fk_club_invitations_club_id 
            FOREIGN KEY (club_id) REFERENCES book_clubs(id) ON DELETE CASCADE;
            RAISE NOTICE 'Added foreign key constraint to book_clubs';
        EXCEPTION
            WHEN duplicate_object THEN
                RAISE NOTICE 'Foreign key constraint to book_clubs already exists';
        END;
    ELSE
        RAISE NOTICE 'book_clubs table does not exist - skipping foreign key constraint';
    END IF;
    
    -- Add foreign key to public.users if the table exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') THEN
        BEGIN
            ALTER TABLE club_invitations 
            ADD CONSTRAINT fk_club_invitations_invited_user_id 
            FOREIGN KEY (invited_user_id) REFERENCES public.users(id) ON DELETE CASCADE;
            RAISE NOTICE 'Added foreign key constraint to public.users for invited_user_id';
        EXCEPTION
            WHEN duplicate_object THEN
                RAISE NOTICE 'Foreign key constraint to public.users for invited_user_id already exists';
        END;
        
        BEGIN
            ALTER TABLE club_invitations 
            ADD CONSTRAINT fk_club_invitations_invited_by_user_id 
            FOREIGN KEY (invited_by_user_id) REFERENCES public.users(id) ON DELETE CASCADE;
            RAISE NOTICE 'Added foreign key constraint to public.users for invited_by_user_id';
        EXCEPTION
            WHEN duplicate_object THEN
                RAISE NOTICE 'Foreign key constraint to public.users for invited_by_user_id already exists';
        END;
    ELSE
        RAISE NOTICE 'public.users table does not exist - skipping foreign key constraints';
    END IF;
END $$;

-- Verify the table was created successfully
SELECT 
    'club_invitations table created successfully' as status,
    COUNT(*) as column_count
FROM information_schema.columns 
WHERE table_name = 'club_invitations' AND table_schema = 'public';














