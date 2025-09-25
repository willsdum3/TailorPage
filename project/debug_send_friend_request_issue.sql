-- Debug the send_friend_request function issue
-- The foreign key constraint error suggests the function is trying to insert invalid user IDs

-- Check the send_friend_request function parameters
SELECT 
    'send_friend_request parameters' as info,
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

-- Check the friend_requests table structure
SELECT 
    'friend_requests structure' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'friend_requests' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check existing friend requests
SELECT 
    'Existing friend requests' as info,
    fr.id,
    fr.requester_id,
    fr.target_id,
    fr.status,
    u1.name as requester_name,
    u2.name as target_name
FROM friend_requests fr
LEFT JOIN users u1 ON fr.requester_id = u1.id
LEFT JOIN users u2 ON fr.target_id = u2.id
ORDER BY fr.created_at DESC;

-- Test the send_friend_request function with William's auth_user_id
-- This will help us see what's happening
SELECT 
    'Test send_friend_request' as info,
    send_friend_request(
        'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,  -- William's auth_user_id
        '309f3f29-aeea-4f26-a936-8d65047dc469'::UUID,  -- Tracey's internal_id
        'Test message'
    ) as result;
