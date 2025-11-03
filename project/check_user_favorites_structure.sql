-- Check the actual structure of user_favorites table
SELECT '=== USER_FAVORITES TABLE STRUCTURE ===' as header;

-- Get column information
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_favorites' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check if table has any data
SELECT 
    'user_favorites' as table_name,
    COUNT(*) as total_records
FROM user_favorites;

-- Show sample data if it exists
SELECT '=== SAMPLE USER_FAVORITES DATA ===' as header;
SELECT * FROM user_favorites LIMIT 5;
