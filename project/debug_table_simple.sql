-- Simple debug script to check the table structure
-- This will avoid the column name typo and focus on the core issue

-- Check if the table exists
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'club_invitations' AND table_schema = 'public') 
        THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as table_status;

-- Show the exact column information
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'club_invitations' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check if RLS is enabled (we know it is, but let's confirm)
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'club_invitations' 
AND schemaname = 'public';

-- Check for RLS policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'club_invitations' 
AND schemaname = 'public';

-- Try to select all columns using * (this should work even with RLS)
SELECT 'Testing SELECT *' as test;
SELECT * FROM club_invitations LIMIT 1;

-- Check the table definition
SELECT 
    pg_get_tabledef('club_invitations'::regclass) as table_definition;





















