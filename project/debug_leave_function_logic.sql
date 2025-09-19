-- =====================================================
-- DEBUG LEAVE FUNCTION LOGIC
-- =====================================================
-- Check each step of the leave function logic as table results

-- Step 1: Check if William's user lookup works
SELECT 
    'STEP 1 - USER LOOKUP' as step,
    CASE 
        WHEN u.id IS NOT NULL THEN 'SUCCESS - User found: ' || u.name || ' (ID: ' || u.id::TEXT || ')'
        ELSE 'FAILED - User not found'
    END as result
FROM users u 
WHERE u.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID

UNION ALL

-- Step 2: Check if discussion exists
SELECT 
    'STEP 2 - DISCUSSION EXISTS' as step,
    CASE 
        WHEN d.id IS NOT NULL THEN 'SUCCESS - Discussion found: ' || d.title
        ELSE 'FAILED - Discussion not found'
    END as result
FROM discussions d
WHERE d.id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)

UNION ALL

-- Step 3: Check creator logic (exact same as function)
SELECT 
    'STEP 3 - CREATOR CHECK' as step,
    CASE 
        WHEN EXISTS(
            SELECT 1 FROM discussions d 
            WHERE d.id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)
            AND d.created_by = (SELECT u.id FROM users u WHERE u.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID)
        ) THEN 'FAILED - User IS creator (cannot leave)'
        ELSE 'SUCCESS - User is NOT creator (can leave)'
    END as result

UNION ALL

-- Step 4: Check participation logic (exact same as function)
SELECT 
    'STEP 4 - PARTICIPATION CHECK' as step,
    CASE 
        WHEN EXISTS(
            SELECT 1 FROM discussion_participants dp
            WHERE dp.discussion_id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)
            AND dp.user_id = (SELECT u.id FROM users u WHERE u.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID)
        ) THEN 'SUCCESS - User IS participant (can leave)'
        ELSE 'FAILED - User is NOT participant (cannot leave)'
    END as result

UNION ALL

-- Step 5: Show what should happen
SELECT 
    'STEP 5 - EXPECTED OUTCOME' as step,
    CASE 
        WHEN EXISTS(
            SELECT 1 FROM discussions d 
            WHERE d.id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)
            AND d.created_by = (SELECT u.id FROM users u WHERE u.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID)
        ) THEN 'Should FAIL - User is creator'
        WHEN NOT EXISTS(
            SELECT 1 FROM discussion_participants dp
            WHERE dp.discussion_id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)
            AND dp.user_id = (SELECT u.id FROM users u WHERE u.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID)
        ) THEN 'Should FAIL - User not participant'
        ELSE 'Should SUCCESS - User can leave'
    END as result

ORDER BY step;
