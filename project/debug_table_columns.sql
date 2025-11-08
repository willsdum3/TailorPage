-- Debug the exact column names and data types in club_invitations table
-- This will help us understand why PostgreSQL can't find the invited_user_id column

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
    character_maximum_length,
    numeric_precision,
    numeric_scale
FROM information_schema.columns 
WHERE table_name = 'club_invitations' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check the table structure using pg_catalog
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

-- Try to select from the table to see if columns are accessible
SELECT 
    'Testing column access' as test,
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




















