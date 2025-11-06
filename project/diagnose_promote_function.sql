-- Diagnose why promote_user_to_admin function is still not found

-- 1. Check if the function exists at all
SELECT 
    'Function Existence Check' as check_type,
    routine_name,
    routine_type,
    data_type as return_type,
    specific_name
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name = 'promote_user_to_admin';

-- 2. Check function parameters if it exists
SELECT 
    'promote_user_to_admin Parameters' as check_type,
    parameter_name,
    data_type,
    ordinal_position,
    specific_name
FROM information_schema.parameters 
WHERE specific_schema = 'public'
AND specific_name IN (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_schema = 'public' 
    AND routine_name = 'promote_user_to_admin'
)
ORDER BY specific_name, ordinal_position;

-- 3. Check for any functions with similar names
SELECT 
    'Similar Function Names' as check_type,
    routine_name,
    routine_type,
    data_type as return_type,
    specific_name
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name ILIKE '%promote%'
ORDER BY routine_name, specific_name;

-- 4. Check for any functions with 'admin' in the name
SELECT 
    'Admin Related Functions' as check_type,
    routine_name,
    routine_type,
    data_type as return_type,
    specific_name
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name ILIKE '%admin%'
ORDER BY routine_name, specific_name;

-- 5. List ALL functions to see what's available
SELECT 
    'All Functions in Public Schema' as check_type,
    routine_name,
    routine_type,
    data_type as return_type,
    specific_name
FROM information_schema.routines 
WHERE routine_schema = 'public'
ORDER BY routine_name, specific_name;


















