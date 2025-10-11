-- Create a test table with a different name to see if there's corruption
-- This will help us determine if the issue is with the table or something else

-- Drop any existing test table
DROP TABLE IF EXISTS club_invitations_test CASCADE;

-- Create the test table with the same structure
CREATE TABLE club_invitations_test (
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
ALTER TABLE club_invitations_test 
ADD CONSTRAINT check_status_test 
CHECK (status IN ('pending', 'accepted', 'declined'));

-- Try to add the unique constraint
DO $$
BEGIN
    BEGIN
        ALTER TABLE club_invitations_test 
        ADD CONSTRAINT unique_club_invitation_test 
        UNIQUE(club_id, invited_user_id);
        RAISE NOTICE 'Unique constraint added successfully to test table';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Error adding unique constraint to test table: %', SQLERRM;
    END;
END $$;

-- Create indexes
CREATE INDEX idx_club_invitations_test_club_id ON club_invitations_test(club_id);
CREATE INDEX idx_club_invitations_test_invited_user_id ON club_invitations_test(invited_user_id);
CREATE INDEX idx_club_invitations_test_status ON club_invitations_test(status);

-- Test selecting from the test table
SELECT 'Testing SELECT * from test table' as test;
SELECT * FROM club_invitations_test LIMIT 1;

-- Test selecting specific columns
SELECT 'Testing specific columns from test table' as test;
SELECT 
    id,
    club_id,
    invited_user_id,
    invited_by_user_id,
    message,
    status,
    created_at,
    responded_at
FROM club_invitations_test 
LIMIT 1;

-- Verify the test table was created successfully
SELECT 
    'club_invitations_test table created successfully' as status,
    COUNT(*) as column_count
FROM information_schema.columns 
WHERE table_name = 'club_invitations_test' AND table_schema = 'public';

-- Show the test table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'club_invitations_test' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Show constraints on test table
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'club_invitations_test' AND tc.table_schema = 'public'
ORDER BY tc.constraint_type, kcu.column_name;








