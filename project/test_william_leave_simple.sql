-- =====================================================
-- TEST WILLIAM LEAVE SIMPLE
-- =====================================================
-- Simple test to see what happens when William tries to leave

-- Test 1: Call the function directly with William's data
SELECT 
    'WILLIAM LEAVE TEST' as test_name,
    leave_discussion(
        'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,  -- William's auth_user_id
        (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)
    ) as leave_result;

-- Test 2: Check who is actually the creator of this discussion
SELECT 
    'DISCUSSION CREATOR' as test_name,
    d.title as discussion_title,
    creator.name as creator_name,
    creator.username as creator_username,
    creator.id as creator_user_id,
    creator.auth_user_id as creator_auth_user_id
FROM discussions d
JOIN users creator ON d.created_by = creator.id
WHERE d.id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1);

-- Test 3: Check William's user data
SELECT 
    'WILLIAM USER DATA' as test_name,
    u.name,
    u.username,
    u.id as user_id,
    u.auth_user_id
FROM users u 
WHERE u.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID;

-- Test 4: Manual creator check (same logic as function)
SELECT 
    'MANUAL CREATOR CHECK' as test_name,
    CASE 
        WHEN EXISTS(
            SELECT 1 FROM discussions d 
            WHERE d.id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)
            AND d.created_by = (SELECT u.id FROM users u WHERE u.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID)
        ) THEN 'WILLIAM IS CREATOR'
        ELSE 'WILLIAM IS NOT CREATOR'
    END as creator_check_result;
