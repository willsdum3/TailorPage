-- =====================================================
-- SIMPLE DISCUSSION MESSAGES DEBUG
-- =====================================================
-- Step by step debugging to see what's happening

-- Test 1: Basic user check
SELECT 
    'USER EXISTS' as test,
    CASE WHEN COUNT(*) > 0 THEN 'YES' ELSE 'NO' END as result
FROM users 
WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID;

-- Test 2: Discussion count
SELECT 
    'DISCUSSIONS EXIST' as test,
    COUNT(*)::TEXT as result
FROM discussions;

-- Test 3: Discussion messages count
SELECT 
    'DISCUSSION MESSAGES EXIST' as test,
    COUNT(*)::TEXT as result
FROM discussion_messages;

-- Test 4: Latest discussion info
SELECT 
    'LATEST DISCUSSION' as test,
    COALESCE(title, 'NO DISCUSSIONS') as result
FROM discussions 
ORDER BY created_at DESC 
LIMIT 1;

-- Test 5: Messages in latest discussion
SELECT 
    'MESSAGES IN LATEST DISCUSSION' as test,
    COUNT(*)::TEXT as result
FROM discussion_messages dm
WHERE dm.discussion_id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1);

-- Test 6: User participation in latest discussion
SELECT 
    'USER IS PARTICIPANT' as test,
    CASE 
        WHEN EXISTS(
            SELECT 1 
            FROM discussion_participants dp
            JOIN users u ON dp.user_id = u.id
            WHERE u.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID
            AND dp.discussion_id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)
        ) THEN 'YES' 
        ELSE 'NO' 
    END as result;

-- Test 7: Force join user to latest discussion
INSERT INTO discussion_participants (discussion_id, user_id, joined_at)
SELECT 
    d.id,
    u.id,
    NOW()
FROM discussions d, users u
WHERE d.id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)
AND u.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID
ON CONFLICT (discussion_id, user_id) DO NOTHING;

-- Test 8: Check participation after force join
SELECT 
    'USER IS PARTICIPANT AFTER FORCE JOIN' as test,
    CASE 
        WHEN EXISTS(
            SELECT 1 
            FROM discussion_participants dp
            JOIN users u ON dp.user_id = u.id
            WHERE u.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID
            AND dp.discussion_id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)
        ) THEN 'YES' 
        ELSE 'NO' 
    END as result;

-- Test 9: Call function directly and show result
SELECT 
    'FUNCTION CALL RESULT' as test,
    COALESCE(
        get_discussion_messages(
            'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,
            (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1),
            10,
            0
        )::TEXT,
        'NULL'
    ) as result;

-- Test 10: Raw messages from database
SELECT 
    'RAW DATABASE MESSAGES' as test,
    COALESCE(
        (SELECT string_agg(content, ' | ' ORDER BY created_at) 
         FROM discussion_messages 
         WHERE discussion_id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)),
        'NO MESSAGES'
    ) as result;
