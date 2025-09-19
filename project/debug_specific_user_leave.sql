-- =====================================================
-- DEBUG SPECIFIC USER LEAVE ATTEMPT
-- =====================================================
-- Test with a specific user who should be able to leave

-- Test with William Dumbili (hereistand) who is a PARTICIPANT, not creator
DO $$
DECLARE
    william_auth_id UUID;
    test_discussion_id UUID;
    william_user_id UUID;
    is_creator BOOLEAN;
    is_participant BOOLEAN;
    leave_result BOOLEAN;
BEGIN
    RAISE NOTICE '=== TESTING WILLIAM DUMBILI LEAVE ATTEMPT ===';
    
    -- Get William's auth_user_id from the users table
    SELECT auth_user_id, id INTO william_auth_id, william_user_id
    FROM users 
    WHERE username = 'hereistand';
    
    IF william_auth_id IS NULL THEN
        RAISE NOTICE '❌ William not found in users table';
        RETURN;
    END IF;
    
    RAISE NOTICE 'William auth_user_id: %, user_id: %', william_auth_id, william_user_id;
    
    -- Get latest discussion
    SELECT id INTO test_discussion_id FROM discussions ORDER BY created_at DESC LIMIT 1;
    RAISE NOTICE 'Testing with discussion: %', test_discussion_id;
    
    -- Check if William is creator
    SELECT EXISTS(
        SELECT 1 FROM discussions d 
        WHERE d.id = test_discussion_id AND d.created_by = william_user_id
    ) INTO is_creator;
    RAISE NOTICE 'William is creator: %', is_creator;
    
    -- Check if William is participant
    SELECT EXISTS(
        SELECT 1 FROM discussion_participants dp
        WHERE dp.discussion_id = test_discussion_id AND dp.user_id = william_user_id
    ) INTO is_participant;
    RAISE NOTICE 'William is participant: %', is_participant;
    
    -- If William is not creator and is participant, he should be able to leave
    IF NOT is_creator AND is_participant THEN
        RAISE NOTICE 'William should be able to leave - testing function...';
        
        -- Test leave function
        SELECT leave_discussion(william_auth_id, test_discussion_id) INTO leave_result;
        RAISE NOTICE 'Leave function result for William: %', leave_result;
        
        -- Check if he was actually removed
        SELECT EXISTS(
            SELECT 1 FROM discussion_participants dp
            WHERE dp.discussion_id = test_discussion_id AND dp.user_id = william_user_id
        ) INTO is_participant;
        RAISE NOTICE 'William is participant after leave: %', is_participant;
        
        IF leave_result = true AND is_participant = false THEN
            RAISE NOTICE '✅ SUCCESS: William can leave discussions properly';
        ELSE
            RAISE NOTICE '❌ PROBLEM: William should be able to leave but function returned %', leave_result;
        END IF;
    ELSE
        RAISE NOTICE 'William cannot leave: is_creator=%, is_participant=%', is_creator, is_participant;
    END IF;
END $$;

-- Also test with your actual current user
SELECT 
    'YOUR USER INFO' as test_name,
    name,
    username,
    auth_user_id::TEXT as auth_user_id
FROM users 
WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID;
