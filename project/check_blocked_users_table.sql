-- Check the structure of the blocked_users table
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'blocked_users' 
AND table_schema = 'public'
ORDER BY ordinal_position;
