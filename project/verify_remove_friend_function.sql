-- Verify that the remove_friend function exists and has the correct signature
SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name = 'remove_friend';

-- Check the function parameters
SELECT 
    parameter_name,
    data_type,
    parameter_mode
FROM information_schema.parameters 
WHERE specific_schema = 'public' 
AND specific_name IN (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_schema = 'public' 
    AND routine_name = 'remove_friend'
)
ORDER BY ordinal_position;

-- Test the function with dummy data (this will fail but shows the function exists)
-- SELECT remove_friend('00000000-0000-0000-0000-000000000000'::uuid, '00000000-0000-0000-0000-000000000000'::uuid);
