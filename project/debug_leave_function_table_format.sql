-- =====================================================
-- DEBUG LEAVE FUNCTION - TABLE FORMAT
-- =====================================================
-- Show all debugging info as table results to see where it fails

-- Test each step of the leave function logic as separate queries
-- Step 1: User lookup test
SELECT 
    'STEP 1 - USER LOOKUP' as step,
    CASE 
        WHEN u.id IS NOT NULL THEN 'SUCCESS - User found: ' || u.id::TEXT
        ELSE 'FAILED - User not found'
    END as result,
    u.id::TEXT as user_id
FROM users u 
WHERE u.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID

UNION ALL

-- Step 2: Discussion exists test
SELECT 
    'STEP 2 - DISCUSSION EXISTS' as step,
    CASE 
        WHEN d.id IS NOT NULL THEN 'SUCCESS - Discussion exists'
        ELSE 'FAILED - Discussion not found'
    END as result,
    d.id::TEXT as discussion_id
FROM discussions d
WHERE d.id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)

UNION ALL

-- Step 3: Creator check test (the exact logic from the function)
SELECT 
    'STEP 3 - CREATOR CHECK' as step,
    CASE 
        WHEN EXISTS(
            SELECT 1 FROM discussions d 
            WHERE d.id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)
            AND d.created_by = (SELECT u.id FROM users u WHERE u.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID)
        ) THEN 'FAILED - User IS creator (cannot leave)'
        ELSE 'SUCCESS - User is NOT creator (can leave)'
    END as result,
    (SELECT creator.name FROM discussions d JOIN users creator ON d.created_by = creator.id 
     WHERE d.id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)) as actual_creator

UNION ALL

-- Step 4: Participation check test
SELECT 
    'STEP 4 - PARTICIPATION CHECK' as step,
    CASE 
        WHEN EXISTS(
            SELECT 1 FROM discussion_participants dp
            WHERE dp.discussion_id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)
            AND dp.user_id = (SELECT u.id FROM users u WHERE u.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID)
        ) THEN 'SUCCESS - User IS participant (can leave)'
        ELSE 'FAILED - User is NOT participant (cannot leave)'
    END as result,
    (SELECT COUNT(*)::TEXT FROM discussion_participants dp
     WHERE dp.discussion_id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)) as total_participants

UNION ALL

-- Step 5: What should the final result be?
SELECT 
    'STEP 5 - EXPECTED RESULT' as step,
    CASE 
        -- If user is creator, should fail
        WHEN EXISTS(
            SELECT 1 FROM discussions d 
            WHERE d.id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)
            AND d.created_by = (SELECT u.id FROM users u WHERE u.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID)
        ) THEN 'Should FAIL - User is creator'
        -- If user is not participant, should fail
        WHEN NOT EXISTS(
            SELECT 1 FROM discussion_participants dp
            WHERE dp.discussion_id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)
            AND dp.user_id = (SELECT u.id FROM users u WHERE u.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID)
        ) THEN 'Should FAIL - User not participant'
        -- Otherwise should succeed
        ELSE 'Should SUCCESS - User can leave'
    END as result,
    'Based on conditions above' as explanation

ORDER BY step;
