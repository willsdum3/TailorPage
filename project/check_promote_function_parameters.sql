-- Check the exact parameters of the existing promote_user_to_admin function

-- 1. Get the exact parameters of the existing function
SELECT 
    'promote_user_to_admin Parameters' as check_type,
    parameter_name,
    data_type,
    ordinal_position,
    specific_name
FROM information_schema.parameters 
WHERE specific_schema = 'public'
AND specific_name = 'promote_user_to_admin_94393'
ORDER BY ordinal_position;

-- 2. Get the function definition to see what it expects
SELECT 
    'promote_user_to_admin Definition' as check_type,
    routine_name,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND specific_name = 'promote_user_to_admin_94393';

-- 3. Test the function with the exact parameters the frontend is calling
-- Let's see what happens when we try to call it
SELECT 
    'Function Call Test' as check_type,
    'Testing function signature' as test_description;







