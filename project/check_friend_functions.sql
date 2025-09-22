-- Simple check for friend functions
-- This will show if the functions exist and their signatures

-- 1. Check if friend functions exist
SELECT 
    'FRIEND_FUNCTIONS_STATUS' as info,
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%friend%'
ORDER BY routine_name;

-- 2. Check function parameters
SELECT 
    'FUNCTION_SIGNATURES' as info,
    p.specific_name,
    p.parameter_name,
    p.data_type,
    p.parameter_mode
FROM information_schema.parameters p
JOIN information_schema.routines r ON p.specific_name = r.specific_name
WHERE p.specific_schema = 'public' 
AND r.routine_name LIKE '%friend%'
ORDER BY r.routine_name, p.ordinal_position;

-- 3. Check if friend_requests table exists
SELECT 
    'FRIEND_REQUESTS_TABLE' as info,
    COUNT(*) as table_exists
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'friend_requests';

-- 4. Check if users table has data
SELECT 
    'USERS_TABLE_DATA' as info,
    COUNT(*) as user_count
FROM users;
