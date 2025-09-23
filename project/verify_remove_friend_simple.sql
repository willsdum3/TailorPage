-- Simple verification that remove_friend function exists
-- This will show if the function was created successfully

-- Check if the function exists
SELECT 
    'Function exists' as status,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name = 'remove_friend';

-- Test the function with dummy data (should return "User not found" error)
SELECT 
    'Function test' as status,
    remove_friend(
        '00000000-0000-0000-0000-000000000000'::uuid, 
        '00000000-0000-0000-0000-000000000000'::uuid
    ) as test_result;
