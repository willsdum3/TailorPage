-- Verify the promote_user_to_admin function was actually created and test it

-- 1. Check if the function exists after recreation
SELECT 
    'Function Existence After Recreation' as check_type,
    routine_name,
    routine_type,
    data_type as return_type,
    specific_name
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name = 'promote_user_to_admin';

-- 2. Check the exact parameters
SELECT 
    'Function Parameters After Recreation' as check_type,
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
ORDER BY ordinal_position;

-- 3. Get the function definition to verify it's correct
SELECT 
    'Function Definition' as check_type,
    routine_name,
    LEFT(routine_definition, 200) as definition_start
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name = 'promote_user_to_admin';

-- 4. Test the function with dummy data to see if it's callable
-- First, let's get some real user IDs to test with
SELECT 
    'Test Data - Users' as check_type,
    id as user_id,
    auth_user_id,
    name,
    username
FROM users 
LIMIT 3;

-- 5. Test the function with a simple call (this will fail but show us the exact error)
SELECT 
    'Function Test' as check_type,
    'Testing function callability' as test_description;

-- 6. Check if there are any other functions with similar names that might be conflicting
SELECT 
    'All Functions with promote in name' as check_type,
    routine_name,
    routine_type,
    data_type as return_type,
    specific_name
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name ILIKE '%promote%'
ORDER BY routine_name, specific_name;

-- 7. Check if there are any functions with admin in name
SELECT 
    'All Functions with admin in name' as check_type,
    routine_name,
    routine_type,
    data_type as return_type,
    specific_name
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name ILIKE '%admin%'
ORDER BY routine_name, specific_name;
