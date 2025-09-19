-- =====================================================
-- DEBUG LEAVE DISCUSSION ISSUE
-- =====================================================
-- Check why leave_discussion is failing for non-creators

-- Test 1: Check if user is actually the creator of the discussion
SELECT 
    'CREATOR CHECK' as test_name,
    d.title as discussion_title,
    creator.name as creator_name,
    creator.username as creator_username,
    CASE 
        WHEN d.created_by = (SELECT u.id FROM users u WHERE u.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID)
        THEN 'YES - User IS the creator'
        ELSE 'NO - User is NOT the creator'
    END as is_creator
FROM discussions d
JOIN users creator ON d.created_by = creator.id
WHERE d.id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1);

-- Test 2: Check participation status
SELECT 
    'PARTICIPATION CHECK' as test_name,
    CASE 
        WHEN EXISTS(
            SELECT 1 FROM discussion_participants dp
            JOIN users u ON dp.user_id = u.id
            WHERE u.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID
            AND dp.discussion_id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)
        ) THEN 'YES - User IS a participant'
        ELSE 'NO - User is NOT a participant'
    END as is_participant;

-- Test 3: Test the leave_discussion function step by step
DO $$
DECLARE
    test_auth_id UUID := 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID;
    test_discussion_id UUID;
    user_uuid UUID;
    is_creator BOOLEAN;
    is_participant BOOLEAN;
    leave_result BOOLEAN;
BEGIN
    RAISE NOTICE '=== DEBUGGING LEAVE DISCUSSION STEP BY STEP ===';
    
    -- Get test data
    SELECT id INTO test_discussion_id FROM discussions ORDER BY created_at DESC LIMIT 1;
    SELECT u.id INTO user_uuid FROM users u WHERE u.auth_user_id = test_auth_id;
    
    RAISE NOTICE 'Testing with discussion: %, user: %', test_discussion_id, user_uuid;
    
    -- Check if user is creator
    SELECT EXISTS(
        SELECT 1 FROM discussions d 
        WHERE d.id = test_discussion_id AND d.created_by = user_uuid
    ) INTO is_creator;
    RAISE NOTICE 'Is creator: %', is_creator;
    
    -- Check if user is participant
    SELECT EXISTS(
        SELECT 1 FROM discussion_participants dp
        WHERE dp.discussion_id = test_discussion_id AND dp.user_id = user_uuid
    ) INTO is_participant;
    RAISE NOTICE 'Is participant: %', is_participant;
    
    -- If not participant, join first
    IF NOT is_participant THEN
        INSERT INTO discussion_participants (discussion_id, user_id, joined_at)
        VALUES (test_discussion_id, user_uuid, NOW());
        RAISE NOTICE 'Joined user to discussion for testing';
    END IF;
    
    -- Now test leave function
    SELECT leave_discussion(test_auth_id, test_discussion_id) INTO leave_result;
    RAISE NOTICE 'Leave function result: %', leave_result;
    
    -- Check if user was actually removed
    SELECT EXISTS(
        SELECT 1 FROM discussion_participants dp
        WHERE dp.discussion_id = test_discussion_id AND dp.user_id = user_uuid
    ) INTO is_participant;
    RAISE NOTICE 'Is participant after leave attempt: %', is_participant;
    
    IF leave_result = true AND is_participant = false THEN
        RAISE NOTICE '✅ SUCCESS: Leave function working correctly';
    ELSIF leave_result = false AND is_creator = true THEN
        RAISE NOTICE '✅ EXPECTED: Creator cannot leave their own discussion';
    ELSE
        RAISE NOTICE '❌ ISSUE: Leave function returned % but user is still participant: %', leave_result, is_participant;
        RAISE NOTICE 'This suggests a problem with the leave_discussion function logic';
    END IF;
END $$;

-- Test 4: Check all participants in the discussion
SELECT 
    'CURRENT PARTICIPANTS' as test_name,
    u.name as participant_name,
    u.username as participant_username,
    CASE 
        WHEN d.created_by = u.id THEN 'CREATOR'
        ELSE 'PARTICIPANT'
    END as role
FROM discussion_participants dp
JOIN users u ON dp.user_id = u.id
JOIN discussions d ON dp.discussion_id = d.id
WHERE dp.discussion_id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)
ORDER BY dp.joined_at;
