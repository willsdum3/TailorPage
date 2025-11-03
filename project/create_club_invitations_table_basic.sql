-- Create club_invitations table (basic version without RLS policies)
-- This table stores invitations sent to users to join book clubs

-- Create the table without any constraints or policies
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

-- Enable RLS (but don't create policies yet)
ALTER TABLE club_invitations ENABLE ROW LEVEL SECURITY;

-- Add a basic policy that allows all operations for now
-- This can be updated later once we confirm the users table structure
DROP POLICY IF EXISTS "Allow all operations temporarily" ON club_invitations;
CREATE POLICY "Allow all operations temporarily" ON club_invitations
    FOR ALL USING (true) WITH CHECK (true);

-- Add foreign key constraints after table creation (if the referenced tables exist)
DO $$
BEGIN
    -- Add foreign key to book_clubs if the table exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'book_clubs') THEN
        BEGIN
            ALTER TABLE club_invitations 
            ADD CONSTRAINT fk_club_invitations_club_id 
            FOREIGN KEY (club_id) REFERENCES book_clubs(id) ON DELETE CASCADE;
        EXCEPTION
            WHEN duplicate_object THEN
                -- Constraint already exists, ignore
                NULL;
        END;
    END IF;
    
    -- Add foreign key to users if the table exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
        BEGIN
            ALTER TABLE club_invitations 
            ADD CONSTRAINT fk_club_invitations_invited_user_id 
            FOREIGN KEY (invited_user_id) REFERENCES users(id) ON DELETE CASCADE;
        EXCEPTION
            WHEN duplicate_object THEN
                -- Constraint already exists, ignore
                NULL;
        END;
        
        BEGIN
            ALTER TABLE club_invitations 
            ADD CONSTRAINT fk_club_invitations_invited_by_user_id 
            FOREIGN KEY (invited_by_user_id) REFERENCES users(id) ON DELETE CASCADE;
        EXCEPTION
            WHEN duplicate_object THEN
                -- Constraint already exists, ignore
                NULL;
        END;
    END IF;
END $$;














