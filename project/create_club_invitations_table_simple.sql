-- Create club_invitations table (simple version without foreign key constraints)
-- This table stores invitations sent to users to join book clubs

-- First, create the table without foreign key constraints
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

-- Enable RLS
ALTER TABLE club_invitations ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
DROP POLICY IF EXISTS "Users can view their own invitations" ON club_invitations;
CREATE POLICY "Users can view their own invitations" ON club_invitations
    FOR SELECT USING (invited_user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

DROP POLICY IF EXISTS "Club admins can view club invitations" ON club_invitations;
CREATE POLICY "Club admins can view club invitations" ON club_invitations
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM book_club_members bcm
            WHERE bcm.club_id = club_invitations.club_id
            AND bcm.user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid())
            AND bcm.role = 'admin'
        )
    );

DROP POLICY IF EXISTS "Club admins can create invitations" ON club_invitations;
CREATE POLICY "Club admins can create invitations" ON club_invitations
    FOR INSERT WITH CHECK (
        invited_by_user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid())
        AND EXISTS (
            SELECT 1 FROM book_club_members bcm
            WHERE bcm.club_id = club_invitations.club_id
            AND bcm.user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid())
            AND bcm.role = 'admin'
        )
    );

DROP POLICY IF EXISTS "Users can update their own invitations" ON club_invitations;
CREATE POLICY "Users can update their own invitations" ON club_invitations
    FOR UPDATE USING (invited_user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

-- Add foreign key constraints after table creation (if the referenced tables exist)
DO $$
BEGIN
    -- Add foreign key to book_clubs if the table exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'book_clubs') THEN
        ALTER TABLE club_invitations 
        ADD CONSTRAINT fk_club_invitations_club_id 
        FOREIGN KEY (club_id) REFERENCES book_clubs(id) ON DELETE CASCADE;
    END IF;
    
    -- Add foreign key to users if the table exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
        ALTER TABLE club_invitations 
        ADD CONSTRAINT fk_club_invitations_invited_user_id 
        FOREIGN KEY (invited_user_id) REFERENCES users(id) ON DELETE CASCADE;
        
        ALTER TABLE club_invitations 
        ADD CONSTRAINT fk_club_invitations_invited_by_user_id 
        FOREIGN KEY (invited_by_user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
END $$;



