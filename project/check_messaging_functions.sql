-- Check if messaging functions exist
SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%conversation%' 
OR routine_name LIKE '%friend_message%'
ORDER BY routine_name;
