-- Check the structure of the public.users table specifically
-- This will help us understand the exact column names and structure

-- Check if public.users table exists
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') 
        THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as public_users_table_status;

-- Show the structure of public.users table
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check constraints on public.users table
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'users' AND tc.table_schema = 'public'
ORDER BY tc.constraint_type, kcu.column_name;

-- Try to select from public.users table
DO $$
DECLARE
    user_count INTEGER;
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') THEN
        SELECT COUNT(*) INTO user_count FROM public.users;
        RAISE NOTICE 'public.users table has % rows', user_count;
        
        -- Show first few rows
        RAISE NOTICE 'Sample public.users data:';
    ELSE
        RAISE NOTICE 'public.users table does not exist';
    END IF;
END $$;

-- Show sample data from public.users (if it exists)
SELECT * FROM public.users LIMIT 3;




















