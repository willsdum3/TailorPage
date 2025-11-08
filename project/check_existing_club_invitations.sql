-- Check if club_invitations table already exists and what its structure is
-- This will help us understand if there's a conflict

-- Check if club_invitations table exists in any schema
SELECT 
    table_schema,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name = 'club_invitations'
ORDER BY table_schema;

-- Check if there are any existing club_invitations tables
SELECT 
    schemaname,
    tablename,
    tableowner
FROM pg_tables 
WHERE tablename = 'club_invitations'
ORDER BY schemaname;

-- If the table exists, show its structure
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'club_invitations' AND table_schema = 'public') THEN
        RAISE NOTICE 'club_invitations table exists in public schema';
    ELSE
        RAISE NOTICE 'club_invitations table does not exist in public schema';
    END IF;
END $$;

-- Show structure if table exists
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'club_invitations' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check for any existing constraints
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'club_invitations' AND tc.table_schema = 'public'
ORDER BY tc.constraint_type, kcu.column_name;




















