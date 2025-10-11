-- Recreate club_invitations table with a completely different approach
-- This will drop the existing table and create it fresh

-- Drop the existing table and all its dependencies
DROP TABLE IF EXISTS club_invitations CASCADE;

-- Create the table with a different approach
CREATE TABLE club_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL,
    invited_user_id UUID NOT NULL,
    invited_by_user_id UUID NOT NULL,
    message TEXT,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    responded_at TIMESTAMP WITH TIME ZONE
);

-- Add the check constraint
ALTER TABLE club_invitations 
ADD CONSTRAINT check_status 
CHECK (status IN ('pending', 'accepted', 'declined'));

-- Try to add the unique constraint with a different syntax
ALTER TABLE club_invitations 
ADD CONSTRAINT unique_club_invitation 
UNIQUE(club_id, invited_user_id);

-- Create indexes
CREATE INDEX idx_club_invitations_club_id ON club_invitations(club_id);
CREATE INDEX idx_club_invitations_invited_user_id ON club_invitations(invited_user_id);
CREATE INDEX idx_club_invitations_status ON club_invitations(status);

-- Verify the table was created successfully
SELECT 
    'club_invitations table recreated successfully' as status,
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

-- Show constraints
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'club_invitations' AND tc.table_schema = 'public'
ORDER BY tc.constraint_type, kcu.column_name;








