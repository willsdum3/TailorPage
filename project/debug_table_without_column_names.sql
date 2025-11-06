-- Debug the table structure without referencing specific column names
-- This will help us understand what's actually in the table

-- Check if the table exists
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'club_invitations' AND table_schema = 'public') 
        THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as table_status;

-- Show the exact column information without referencing column names
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'club_invitations' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check the table structure using pg_catalog without column names
SELECT 
    attname as column_name,
    atttypid::regtype as data_type,
    attnotnull as not_null,
    attnum as column_number
FROM pg_attribute 
WHERE attrelid = 'club_invitations'::regclass 
AND attnum > 0 
AND NOT attisdropped
ORDER BY attnum;

-- Try to select all columns using *
SELECT 'Testing SELECT *' as test;
SELECT * FROM club_invitations LIMIT 1;

-- Check if there are any hidden or system columns
SELECT 
    attname as column_name,
    atttypid::regtype as data_type,
    attnum as column_number,
    attisdropped as is_dropped,
    attisnull as is_null
FROM pg_attribute 
WHERE attrelid = 'club_invitations'::regclass 
ORDER BY attnum;

-- Check the table definition
SELECT 
    pg_get_tabledef('club_invitations'::regclass) as table_definition;



















