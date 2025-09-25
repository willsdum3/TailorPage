-- Check what parameters the friend functions actually expect
-- This will help us understand the mismatch

-- Check get_friend_connections function parameters
SELECT 
    'get_friend_connections' as function_name,
    parameter_name,
    data_type,
    parameter_mode
FROM information_schema.parameters 
WHERE specific_name IN (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_name = 'get_friend_connections' 
    AND routine_schema = 'public'
)
ORDER BY ordinal_position;

-- Check send_friend_request function parameters
SELECT 
    'send_friend_request' as function_name,
    parameter_name,
    data_type,
    parameter_mode
FROM information_schema.parameters 
WHERE specific_name IN (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_name = 'send_friend_request' 
    AND routine_schema = 'public'
)
ORDER BY ordinal_position;

-- Check get_friend_requests function parameters
SELECT 
    'get_friend_requests' as function_name,
    parameter_name,
    data_type,
    parameter_mode
FROM information_schema.parameters 
WHERE specific_name IN (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_name = 'get_friend_requests' 
    AND routine_schema = 'public'
)
ORDER BY ordinal_position;
