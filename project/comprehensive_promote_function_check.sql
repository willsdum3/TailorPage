-- Comprehensive check of promote_user_to_admin function

-- 1. Check if the function exists and get basic info
SELECT 
    'Function Existence' as check_type,
    routine_name,
    routine_type,
    data_type as return_type,
    specific_name
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name = 'promote_user_to_admin';

-- 2. Check parameters for the specific function we found
SELECT 
    'Function Parameters' as check_type,
    parameter_name,
    data_type,
    ordinal_position,
    specific_name
FROM information_schema.parameters 
WHERE specific_schema = 'public'
AND specific_name = 'promote_user_to_admin_94393'
ORDER BY ordinal_position;

-- 3. If no parameters found, check all parameters for any promote function
SELECT 
    'All Promote Function Parameters' as check_type,
    p.parameter_name,
    p.data_type,
    p.ordinal_position,
    p.specific_name,
    r.routine_name
FROM information_schema.parameters p
JOIN information_schema.routines r ON p.specific_name = r.specific_name
WHERE p.specific_schema = 'public'
AND r.routine_name ILIKE '%promote%'
ORDER BY r.routine_name, p.ordinal_position;

-- 4. Get the function definition
SELECT 
    'Function Definition' as check_type,
    routine_name,
    LEFT(routine_definition, 500) as definition_preview
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND specific_name = 'promote_user_to_admin_94393';

-- 5. Check what the frontend is actually calling by looking at the error
-- The error shows: "Could not find the function public.promote_user_to_admin(au"
-- This suggests it's looking for a function with parameters starting with "au" (likely auth_user_id)
SELECT 
    'Frontend Call Analysis' as check_type,
    'Frontend calls: promote_user_to_admin(auth_user_id, club_id_param, user_to_promote_id)' as frontend_call,
    'Error shows: promote_user_to_admin(au' as error_parameter_start;

-- 6. Try to find any function that matches the frontend signature
SELECT 
    'Matching Functions' as check_type,
    routine_name,
    specific_name,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name = 'promote_user_to_admin'
AND specific_name IN (
    SELECT specific_name 
    FROM information_schema.parameters 
    WHERE specific_schema = 'public'
    AND parameter_name = 'auth_user_id'
    AND ordinal_position = 1
);
