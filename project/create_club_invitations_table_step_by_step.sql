-- Create club_invitations table step by step
-- This approach creates the table in the most basic way possible

-- Step 1: Create the table with only essential columns first
CREATE TABLE IF NOT EXISTS club_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL,
    invited_user_id UUID NOT NULL,
    invited_by_user_id UUID NOT NULL,
    message TEXT,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    responded_at TIMESTAMP WITH TIME ZONE
);

-- Step 2: Add the check constraint separately
ALTER TABLE club_invitations 
ADD CONSTRAINT check_status 
CHECK (status IN ('pending', 'accepted', 'declined'));

-- Step 3: Add the unique constraint separately
ALTER TABLE club_invitations 
ADD CONSTRAINT unique_club_invitation 
UNIQUE(club_id, invited_user_id);

-- Step 4: Create indexes one by one
CREATE INDEX IF NOT EXISTS idx_club_invitations_club_id ON club_invitations(club_id);
CREATE INDEX IF NOT EXISTS idx_club_invitations_invited_user_id ON club_invitations(invited_user_id);
CREATE INDEX IF NOT EXISTS idx_club_invitations_status ON club_invitations(status);

-- Step 5: Verify the table was created
SELECT 
    'club_invitations table created successfully' as status,
    COUNT(*) as column_count
FROM information_schema.columns 
WHERE table_name = 'club_invitations' AND table_schema = 'public';

-- Step 6: Show the table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'club_invitations' AND table_schema = 'public'
ORDER BY ordinal_position;








