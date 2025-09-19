-- =====================================================
-- DEBUG MESSAGING STEP BY STEP
-- =====================================================
-- Let's debug exactly what's happening with messaging

-- First, check if messages are actually being saved to the database
DO $$
DECLARE
    test_auth_id UUID := 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID;
    test_discussion_id UUID;
    user_uuid UUID;
    message_count_before INTEGER;
    message_count_after INTEGER;
    is_participant BOOLEAN;
    add_result JSON;
    get_result JSON;
    message_record RECORD;
BEGIN
    RAISE NOTICE '=== STEP-BY-STEP MESSAGING DEBUG ===';
    
    -- Get user info
    SELECT u.id INTO user_uuid FROM users u WHERE u.auth_user_id = test_auth_id;
    RAISE NOTICE 'Step 1: User lookup - Found user: %', COALESCE(user_uuid::TEXT, 'NULL');
    
    -- Get a discussion to test with
    SELECT id INTO test_discussion_id FROM discussions ORDER BY created_at DESC LIMIT 1;
    RAISE NOTICE 'Step 2: Discussion lookup - Using discussion: %', COALESCE(test_discussion_id::TEXT, 'NULL');
    
    IF test_discussion_id IS NULL THEN
        RAISE NOTICE '❌ No discussions found - cannot test messaging';
        RETURN;
    END IF;
    
    -- Check if user is participant
    SELECT EXISTS(
        SELECT 1 FROM discussion_participants dp
        WHERE dp.discussion_id = test_discussion_id AND dp.user_id = user_uuid
    ) INTO is_participant;
    RAISE NOTICE 'Step 3: Participation check - Is participant: %', is_participant;
    
    -- If not participant, join first
    IF NOT is_participant THEN
        INSERT INTO discussion_participants (discussion_id, user_id, joined_at)
        VALUES (test_discussion_id, user_uuid, NOW());
        RAISE NOTICE 'Step 3b: Joined user to discussion';
    END IF;
    
    -- Count messages before
    SELECT COUNT(*) INTO message_count_before 
    FROM discussion_messages 
    WHERE discussion_id = test_discussion_id;
    RAISE NOTICE 'Step 4: Messages before test: %', message_count_before;
    
    -- Test adding a message directly to the table
    INSERT INTO discussion_messages (discussion_id, user_id, content, created_at)
    VALUES (test_discussion_id, user_uuid, 'Direct insert test message', NOW());
    
    -- Count messages after direct insert
    SELECT COUNT(*) INTO message_count_after 
    FROM discussion_messages 
    WHERE discussion_id = test_discussion_id;
    RAISE NOTICE 'Step 5: Messages after direct insert: %', message_count_after;
    
    -- Test the add_discussion_message function
    RAISE NOTICE 'Step 6: Testing add_discussion_message function...';
    SELECT add_discussion_message(test_auth_id, test_discussion_id, 'Function test message') INTO add_result;
    RAISE NOTICE 'Step 6 result: %', add_result;
    
    -- Count messages after function call
    SELECT COUNT(*) INTO message_count_after 
    FROM discussion_messages 
    WHERE discussion_id = test_discussion_id;
    RAISE NOTICE 'Step 7: Messages after function call: %', message_count_after;
    
    -- Test the get_discussion_messages function
    RAISE NOTICE 'Step 8: Testing get_discussion_messages function...';
    SELECT get_discussion_messages(test_auth_id, test_discussion_id, 10, 0) INTO get_result;
    RAISE NOTICE 'Step 8 result: %', LEFT(get_result::TEXT, 300);
    
    -- Show actual messages in the table
    RAISE NOTICE 'Step 9: Actual messages in database:';
    FOR message_record IN 
        SELECT dm.id, dm.content, dm.created_at, u.name
        FROM discussion_messages dm
        JOIN users u ON dm.user_id = u.id
        WHERE dm.discussion_id = test_discussion_id
        ORDER BY dm.created_at DESC
        LIMIT 5
    LOOP
        RAISE NOTICE '- Message: % by % at %', message_record.content, message_record.name, message_record.created_at;
    END LOOP;
    
END $$;

-- Check the actual function signatures that exist
DO $$
DECLARE
    func_record RECORD;
BEGIN
    RAISE NOTICE '=== CURRENT FUNCTION SIGNATURES ===';
    FOR func_record IN 
        SELECT 
            r.routine_name,
            r.data_type as return_type,
            string_agg(
                p.parameter_name || ' ' || p.data_type, 
                ', ' ORDER BY p.ordinal_position
            ) as parameters
        FROM information_schema.routines r
        LEFT JOIN information_schema.parameters p ON r.specific_name = p.specific_name 
            AND p.parameter_mode = 'IN'
        WHERE r.routine_schema = 'public' 
        AND r.routine_name IN ('add_discussion_message', 'get_discussion_messages')
        AND r.routine_type = 'FUNCTION'
        GROUP BY r.routine_name, r.specific_name, r.data_type
        ORDER BY r.routine_name
    LOOP
        RAISE NOTICE '- %(%): returns %', 
                     func_record.routine_name, 
                     COALESCE(func_record.parameters, 'no parameters'), 
                     func_record.return_type;
    END LOOP;
END $$;

-- Test what the frontend service is actually calling
DO $$
DECLARE
    test_auth_id UUID := 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID;
    test_discussion_id UUID;
    test_result JSON;
BEGIN
    RAISE NOTICE '=== FRONTEND SERVICE CALL SIMULATION ===';
    
    SELECT id INTO test_discussion_id FROM discussions ORDER BY created_at DESC LIMIT 1;
    
    -- Simulate exactly what the frontend service calls
    RAISE NOTICE 'Simulating: add_discussion_message with parameters:';
    RAISE NOTICE '- auth_user_id: %', test_auth_id;
    RAISE NOTICE '- discussion_id: %', test_discussion_id;
    RAISE NOTICE '- message_content: "Frontend simulation test"';
    
    BEGIN
        SELECT add_discussion_message(
            test_auth_id,
            test_discussion_id,
            'Frontend simulation test'
        ) INTO test_result;
        
        RAISE NOTICE 'Result: %', test_result;
        
        IF test_result IS NOT NULL AND test_result::TEXT NOT LIKE '%error%' THEN
            RAISE NOTICE '✅ Function call succeeded';
        ELSE
            RAISE NOTICE '❌ Function call failed or returned error';
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '❌ Exception in function call: %', SQLERRM;
    END;
END $$;

DO $$
BEGIN
    RAISE NOTICE '=== DEBUG COMPLETE ===';
    RAISE NOTICE 'Check the logs above to see:';
    RAISE NOTICE '1. If messages are being saved to database';
    RAISE NOTICE '2. If functions exist and work';
    RAISE NOTICE '3. What the actual function signatures are';
    RAISE NOTICE '4. If there are any errors in the function calls';
END $$;
