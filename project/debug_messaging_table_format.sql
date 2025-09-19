-- =====================================================
-- DEBUG MESSAGING - TABLE FORMAT
-- =====================================================
-- Show all debug info as table results instead of RAISE NOTICE

-- Test 1: Check user exists
SELECT 
    'USER CHECK' as test_name,
    CASE 
        WHEN u.id IS NOT NULL THEN 'User found: ' || u.name || ' (ID: ' || u.id::TEXT || ')'
        ELSE 'User NOT found'
    END as result
FROM users u 
WHERE u.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID

UNION ALL

-- Test 2: Check discussions exist
SELECT 
    'DISCUSSIONS CHECK' as test_name,
    'Found ' || COUNT(*)::TEXT || ' discussions' as result
FROM discussions

UNION ALL

-- Test 3: Check participation status
SELECT 
    'PARTICIPATION CHECK' as test_name,
    CASE 
        WHEN COUNT(*) > 0 THEN 'User IS participant in ' || COUNT(*)::TEXT || ' discussions'
        ELSE 'User is NOT participant in any discussions'
    END as result
FROM discussion_participants dp
JOIN users u ON dp.user_id = u.id
WHERE u.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID

UNION ALL

-- Test 4: Check if user is participant in latest discussion
SELECT 
    'LATEST DISCUSSION PARTICIPATION' as test_name,
    CASE 
        WHEN dp.user_id IS NOT NULL THEN 'User IS participant in latest discussion'
        ELSE 'User is NOT participant in latest discussion'
    END as result
FROM discussions d
LEFT JOIN discussion_participants dp ON d.id = dp.discussion_id
LEFT JOIN users u ON dp.user_id = u.id AND u.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID
WHERE d.id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)

UNION ALL

-- Test 5: Check messages in latest discussion
SELECT 
    'MESSAGES IN LATEST DISCUSSION' as test_name,
    'Found ' || COUNT(*)::TEXT || ' messages' as result
FROM discussion_messages dm
WHERE dm.discussion_id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)

UNION ALL

-- Test 6: Function signature check
SELECT 
    'FUNCTION SIGNATURES' as test_name,
    'add_discussion_message: ' || COALESCE(string_agg(p.parameter_name, ', '), 'no params') as result
FROM information_schema.routines r
LEFT JOIN information_schema.parameters p ON r.specific_name = p.specific_name AND p.parameter_mode = 'IN'
WHERE r.routine_schema = 'public' 
AND r.routine_name = 'add_discussion_message'
AND r.routine_type = 'FUNCTION'
GROUP BY r.routine_name

UNION ALL

SELECT 
    'FUNCTION SIGNATURES' as test_name,
    'get_discussion_messages: ' || COALESCE(string_agg(p.parameter_name, ', '), 'no params') as result
FROM information_schema.routines r
LEFT JOIN information_schema.parameters p ON r.specific_name = p.specific_name AND p.parameter_mode = 'IN'
WHERE r.routine_schema = 'public' 
AND r.routine_name = 'get_discussion_messages'
AND r.routine_type = 'FUNCTION'
GROUP BY r.routine_name;

-- Now let's force join the user and test messaging
-- Step 1: Force join user to latest discussion
INSERT INTO discussion_participants (discussion_id, user_id, joined_at)
SELECT 
    d.id,
    u.id,
    NOW()
FROM discussions d, users u
WHERE d.id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)
AND u.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID
ON CONFLICT (discussion_id, user_id) DO NOTHING;

-- Step 2: Test add message after forced join
SELECT 
    'FORCE JOIN AND ADD MESSAGE' as test_name,
    CASE 
        WHEN add_discussion_message(
            'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,
            (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1),
            'Test message after force join'
        )::TEXT LIKE '%error%' THEN 'FAILED: ' || add_discussion_message(
            'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,
            (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1),
            'Test message after force join'
        )::TEXT
        ELSE 'SUCCESS: Message added'
    END as result;

-- Step 3: Test get messages after forced join
SELECT 
    'GET MESSAGES AFTER FORCE JOIN' as test_name,
    CASE 
        WHEN get_discussion_messages(
            'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,
            (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1),
            10, 0
        )::TEXT = '[]' THEN 'FAILED: Still returning empty array'
        ELSE 'SUCCESS: Messages returned - ' || LEFT(get_discussion_messages(
            'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,
            (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1),
            10, 0
        )::TEXT, 100)
    END as result;

-- Step 4: Check actual messages in database after our test
SELECT 
    'ACTUAL MESSAGES IN DATABASE' as test_name,
    CASE 
        WHEN COUNT(*) = 0 THEN 'NO messages found in database'
        ELSE 'Found ' || COUNT(*)::TEXT || ' messages. Latest: "' || 
             (SELECT content FROM discussion_messages ORDER BY created_at DESC LIMIT 1) || '"'
    END as result
FROM discussion_messages dm
WHERE dm.discussion_id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1);
