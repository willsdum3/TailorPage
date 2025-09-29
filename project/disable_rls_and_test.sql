-- Disable RLS temporarily to test if that's causing the column access issue
-- This will help us determine if RLS is the root cause

-- First, check current RLS status
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'club_invitations' 
AND schemaname = 'public';

-- Show current RLS policies
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'club_invitations' 
AND schemaname = 'public';

-- Disable RLS temporarily
ALTER TABLE club_invitations DISABLE ROW LEVEL SECURITY;

-- Test if we can now access the columns
SELECT 'Testing SELECT * after disabling RLS' as test;
SELECT * FROM club_invitations LIMIT 1;

-- Test specific columns
SELECT 'Testing specific columns after disabling RLS' as test;
SELECT 
    id,
    club_id,
    invited_user_id,
    invited_by_user_id,
    message,
    status,
    created_at,
    responded_at
FROM club_invitations 
LIMIT 1;

-- Try to add the unique constraint now
DO $$
BEGIN
    BEGIN
        ALTER TABLE club_invitations 
        ADD CONSTRAINT unique_club_invitation 
        UNIQUE(club_id, invited_user_id);
        RAISE NOTICE 'Unique constraint added successfully after disabling RLS';
    EXCEPTION
        WHEN duplicate_object THEN
            RAISE NOTICE 'Unique constraint already exists';
        WHEN OTHERS THEN
            RAISE NOTICE 'Error adding unique constraint: %', SQLERRM;
    END;
END $$;

-- Re-enable RLS
ALTER TABLE club_invitations ENABLE ROW LEVEL SECURITY;

-- Check final status
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'club_invitations' 
AND schemaname = 'public';
