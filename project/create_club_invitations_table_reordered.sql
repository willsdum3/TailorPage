-- Create club_invitations table with reordered columns
-- Sometimes column order can affect constraint creation

-- Drop the existing table if it exists
DROP TABLE IF EXISTS club_invitations;

-- Create the table with columns in a different order
CREATE TABLE club_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invited_user_id UUID NOT NULL,
    invited_by_user_id UUID NOT NULL,
    club_id UUID NOT NULL,
    message TEXT,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    responded_at TIMESTAMP WITH TIME ZONE
);

-- Add the check constraint
ALTER TABLE club_invitations 
ADD CONSTRAINT check_status 
CHECK (status IN ('pending', 'accepted', 'declined'));

-- Try to add the unique constraint
DO $$
BEGIN
    BEGIN
        ALTER TABLE club_invitations 
        ADD CONSTRAINT unique_club_invitation 
        UNIQUE(club_id, invited_user_id);
        RAISE NOTICE 'Unique constraint added successfully with reordered columns';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Error adding unique constraint: %', SQLERRM;
    END;
END $$;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_club_invitations_club_id ON club_invitations(club_id);
CREATE INDEX IF NOT EXISTS idx_club_invitations_invited_user_id ON club_invitations(invited_user_id);
CREATE INDEX IF NOT EXISTS idx_club_invitations_status ON club_invitations(status);

-- Verify the table was created successfully
SELECT 
    'club_invitations table created successfully with reordered columns' as status,
    COUNT(*) as column_count
FROM information_schema.columns 
WHERE table_name = 'club_invitations' AND table_schema = 'public';

-- Show the table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'club_invitations' AND table_schema = 'public'
ORDER BY ordinal_position;



















