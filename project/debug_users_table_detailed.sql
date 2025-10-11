-- Detailed debug script to check the users table structure
-- This will help us understand exactly what columns exist

-- Check if users table exists
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') 
        THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as users_table_status;

-- If users table exists, show its structure
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
        RAISE NOTICE 'Users table exists. Structure:';
    ELSE
        RAISE NOTICE 'Users table does NOT exist!';
    END IF;
END $$;

-- Show the actual structure of users table
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;

-- Check if there are any constraints on the users table
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'users'
ORDER BY tc.constraint_type, kcu.column_name;

-- Check if there are any indexes on the users table
SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'users';

-- Try to select from users table to see if it has data
DO $$
DECLARE
    user_count INTEGER;
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
        SELECT COUNT(*) INTO user_count FROM users;
        RAISE NOTICE 'Users table has % rows', user_count;
        
        -- Show first few rows
        RAISE NOTICE 'Sample users data:';
    ELSE
        RAISE NOTICE 'Cannot check users data - table does not exist';
    END IF;
END $$;



