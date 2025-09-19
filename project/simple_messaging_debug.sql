-- =====================================================
-- SIMPLE MESSAGING DEBUG
-- =====================================================
-- Basic checks to see what's happening

-- Test 1: Check if user exists
SELECT 
    'USER CHECK' as test_name,
    u.id,
    u.name,
    u.username,
    u.auth_user_id
FROM users u 
WHERE u.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID;

-- Test 2: Check discussions
SELECT 
    'DISCUSSIONS CHECK' as test_name,
    COUNT(*) as discussion_count
FROM discussions;

-- Test 3: Check if there are any discussion messages
SELECT 
    'MESSAGES CHECK' as test_name,
    COUNT(*) as message_count
FROM discussion_messages;

-- Test 4: Check discussion participants
SELECT 
    'PARTICIPANTS CHECK' as test_name,
    COUNT(*) as participant_count
FROM discussion_participants;

-- Test 5: Check function existence
SELECT 
    'FUNCTION CHECK' as test_name,
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_name IN ('add_discussion_message', 'get_discussion_messages', 'join_discussion')
AND routine_schema = 'public'
ORDER BY routine_name;

-- Test 6: Try to call add_discussion_message function directly
SELECT 
    'FUNCTION CALL TEST' as test_name,
    add_discussion_message(
        'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,
        (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1),
        'Simple debug test message'
    ) as result;

-- Test 7: Check what messages exist after the function call
SELECT 
    'MESSAGES AFTER FUNCTION' as test_name,
    dm.id,
    dm.content,
    dm.created_at,
    u.name as user_name
FROM discussion_messages dm
JOIN users u ON dm.user_id = u.id
ORDER BY dm.created_at DESC
LIMIT 5;

-- Test 8: Try get_discussion_messages function
SELECT 
    'GET MESSAGES TEST' as test_name,
    get_discussion_messages(
        'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,
        (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1),
        10,
        0
    ) as messages_result;
