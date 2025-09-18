-- =====================================================
-- DEBUG GET_DISCUSSIONS FUNCTION ISSUE
-- =====================================================
-- This script will test why get_discussions is returning empty array

-- Test the get_discussions function with the actual user ID from console
DO $$
DECLARE
    test_auth_id UUID := 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID; -- From your console log
    test_result RECORD;
    result_count INTEGER := 0;
    user_found BOOLEAN;
    user_internal_id UUID;
BEGIN
    RAISE NOTICE '=== TESTING GET_DISCUSSIONS WITH REAL USER ID ===';
    RAISE NOTICE 'Testing with auth_user_id: %', test_auth_id;
    
    -- First check if this user exists in the users table
    SELECT EXISTS(SELECT 1 FROM users WHERE auth_user_id = test_auth_id) INTO user_found;
    RAISE NOTICE 'User exists in users table: %', user_found;
    
    IF user_found THEN
        SELECT id INTO user_internal_id FROM users WHERE auth_user_id = test_auth_id;
        RAISE NOTICE 'User internal ID: %', user_internal_id;
    END IF;
    
    -- Test the get_discussions function
    RAISE NOTICE 'Calling get_discussions function...';
    FOR test_result IN SELECT * FROM get_discussions(test_auth_id)
    LOOP
        result_count := result_count + 1;
        RAISE NOTICE 'Discussion %: % (ID: %)', result_count, test_result.title, test_result.id;
        RAISE NOTICE '  Participant: %, Creator: %', test_result.is_participant, test_result.creator_name;
    END LOOP;
    
    RAISE NOTICE 'get_discussions returned % discussions', result_count;
    
    -- If no results, let's check the discussions table directly
    IF result_count = 0 THEN
        RAISE NOTICE 'No results from function, checking discussions table directly...';
        
        result_count := 0;
        FOR test_result IN 
            SELECT id, title, created_by, created_at 
            FROM discussions 
            ORDER BY created_at DESC
        LOOP
            result_count := result_count + 1;
            RAISE NOTICE 'Direct query - Discussion %: % (ID: %)', result_count, test_result.title, test_result.id;
        END LOOP;
        
        RAISE NOTICE 'Direct query found % discussions', result_count;
        
        -- Check if the function has an error
        BEGIN
            PERFORM get_discussions(test_auth_id);
            RAISE NOTICE 'Function executed without error';
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Function error: %', SQLERRM;
        END;
    END IF;
END $$;

-- Test with a different approach - check if RLS is blocking access
SET row_security = off;
SELECT 'With RLS OFF' as test, COUNT(*) as discussion_count FROM discussions;
SET row_security = on;
SELECT 'With RLS ON' as test, COUNT(*) as discussion_count FROM discussions;

-- Check RLS policies on discussions table
SELECT 
    'Discussion RLS Policies' as info,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'discussions';

-- Final test - try to call the function as if from the frontend
DO $$
DECLARE
    frontend_result JSON;
BEGIN
    RAISE NOTICE '=== SIMULATING FRONTEND CALL ===';
    
    -- This simulates what the frontend service is doing
    BEGIN
        SELECT json_agg(row_to_json(t)) INTO frontend_result
        FROM (
            SELECT * FROM get_discussions('ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID)
        ) t;
        
        RAISE NOTICE 'Simulated frontend result: %', frontend_result;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Simulated frontend call failed: %', SQLERRM;
    END;
END $$;
