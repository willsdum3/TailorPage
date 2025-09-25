-- Check all versions of remove_friend functions to see which one is being called

-- List all functions with 'remove_friend' in the name
SELECT 
    'All Remove Friend Functions' as info,
    routine_name,
    routine_type,
    specific_name
FROM information_schema.routines 
WHERE routine_name LIKE '%remove_friend%'
AND routine_schema = 'public'
ORDER BY routine_name, specific_name;

-- Check the parameters of each function
SELECT 
    'Function Parameters' as info,
    p.specific_name,
    p.parameter_name,
    p.data_type,
    p.parameter_mode
FROM information_schema.parameters p
WHERE p.specific_name IN (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_name LIKE '%remove_friend%'
    AND routine_schema = 'public'
)
ORDER BY p.specific_name, p.ordinal_position;

-- Test both functions to see which one is working
SELECT 
    'Test remove_friend_by_internal_id' as test_name,
    remove_friend_by_internal_id(
        'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,
        'df1ec11e-9b78-4fb5-8218-c6fb03320100'::UUID
    ) as result;
