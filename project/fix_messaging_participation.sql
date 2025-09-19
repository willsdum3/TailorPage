-- =====================================================
-- FIX MESSAGING PARTICIPATION ISSUE
-- =====================================================
-- Ensure user is properly joined to discussion and can message

-- Step 1: Get user and discussion info
DO $$
DECLARE
    test_auth_id UUID := 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID;
    user_uuid UUID;
    test_discussion_id UUID;
    is_participant BOOLEAN;
    message_result JSON;
    messages_result JSON;
BEGIN
    RAISE NOTICE '=== FIXING MESSAGING PARTICIPATION ===';
    
    -- Get user
    SELECT u.id INTO user_uuid FROM users u WHERE u.auth_user_id = test_auth_id;
    RAISE NOTICE 'User ID: %', COALESCE(user_uuid::TEXT, 'NULL');
    
    -- Get discussion
    SELECT id INTO test_discussion_id FROM discussions ORDER BY created_at DESC LIMIT 1;
    RAISE NOTICE 'Discussion ID: %', COALESCE(test_discussion_id::TEXT, 'NULL');
    
    IF user_uuid IS NULL OR test_discussion_id IS NULL THEN
        RAISE NOTICE '❌ Missing user or discussion - cannot proceed';
        RETURN;
    END IF;
    
    -- Check if user is participant
    SELECT EXISTS(
        SELECT 1 FROM discussion_participants dp
        WHERE dp.discussion_id = test_discussion_id AND dp.user_id = user_uuid
    ) INTO is_participant;
    RAISE NOTICE 'Is participant before join: %', is_participant;
    
    -- Force join user to discussion
    INSERT INTO discussion_participants (discussion_id, user_id, joined_at)
    VALUES (test_discussion_id, user_uuid, NOW())
    ON CONFLICT (discussion_id, user_id) DO NOTHING;
    RAISE NOTICE '✅ User joined to discussion (or was already joined)';
    
    -- Verify participation
    SELECT EXISTS(
        SELECT 1 FROM discussion_participants dp
        WHERE dp.discussion_id = test_discussion_id AND dp.user_id = user_uuid
    ) INTO is_participant;
    RAISE NOTICE 'Is participant after join: %', is_participant;
    
    -- Now try adding a message
    SELECT add_discussion_message(test_auth_id, test_discussion_id, 'Test message after forced join') INTO message_result;
    RAISE NOTICE 'Add message result: %', message_result;
    
    -- Try getting messages
    SELECT get_discussion_messages(test_auth_id, test_discussion_id, 10, 0) INTO messages_result;
    RAISE NOTICE 'Get messages result: %', LEFT(messages_result::TEXT, 200);
    
    IF messages_result::TEXT != '[]' THEN
        RAISE NOTICE '✅ SUCCESS: Messages are now working!';
    ELSE
        RAISE NOTICE '❌ Still no messages returned';
    END IF;
END $$;

-- Also check if the issue is with the frontend service parameter mismatch
-- The service might be calling with wrong parameter names

-- Check actual function signatures
SELECT 
    'FUNCTION SIGNATURES' as info,
    r.routine_name,
    string_agg(p.parameter_name, ', ' ORDER BY p.ordinal_position) as parameter_names
FROM information_schema.routines r
LEFT JOIN information_schema.parameters p ON r.specific_name = p.specific_name 
    AND p.parameter_mode = 'IN'
WHERE r.routine_schema = 'public' 
AND r.routine_name IN ('add_discussion_message', 'get_discussion_messages')
AND r.routine_type = 'FUNCTION'
GROUP BY r.routine_name, r.specific_name
ORDER BY r.routine_name;

-- Test with exact parameter names the frontend uses
SELECT 
    'FRONTEND SIMULATION' as test_name,
    'Testing add_discussion_message with frontend parameters' as description;

-- Test what happens when we call with the exact same parameters as the frontend
DO $$
DECLARE
    test_result JSON;
    test_auth_id UUID := 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID;
    test_discussion_id UUID;
BEGIN
    SELECT id INTO test_discussion_id FROM discussions ORDER BY created_at DESC LIMIT 1;
    
    -- This simulates exactly what TailorMatesService.addDiscussionMessage calls
    BEGIN
        SELECT add_discussion_message(
            test_auth_id,           -- auth_user_id
            test_discussion_id,     -- discussion_id  
            'Frontend simulation'   -- message_content
        ) INTO test_result;
        
        RAISE NOTICE 'Frontend simulation result: %', test_result;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Frontend simulation error: %', SQLERRM;
    END;
END $$;
