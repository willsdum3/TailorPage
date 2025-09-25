-- Simple test to check which function is being called

-- Check if friend_connections table exists
SELECT 
    'Table Check' as test_type,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name IN ('friend_connections', 'friend_requests')
AND table_schema = 'public';

-- Check the function signatures to see which parameters they expect
SELECT 
    'Function Signatures' as test_type,
    p.specific_name,
    p.parameter_name,
    p.data_type,
    p.parameter_mode
FROM information_schema.parameters p
WHERE p.specific_name IN (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_name = 'get_friend_connections'
    AND routine_schema = 'public'
)
ORDER BY p.specific_name, p.ordinal_position;

-- Test the function that should work (with UUID parameter)
SELECT 
    'Working Function Test' as test_type,
    get_friend_connections('3bd64865-45b6-4b2b-81d2-4940a8bf3200'::UUID) as result;
