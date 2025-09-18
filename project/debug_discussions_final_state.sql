-- =====================================================
-- DEBUG DISCUSSIONS FINAL STATE
-- =====================================================
-- Check what functions exist and test them

-- Check current discussion functions
DO $$
DECLARE
    func_record RECORD;
BEGIN
    RAISE NOTICE '=== CURRENT DISCUSSION FUNCTIONS ===';
    FOR func_record IN 
        SELECT routine_name, routine_type, data_type 
        FROM information_schema.routines 
        WHERE routine_name LIKE '%discussion%' 
        AND routine_schema = 'public'
        ORDER BY routine_name
    LOOP
        RAISE NOTICE '- %: % (%)', func_record.routine_name, func_record.routine_type, func_record.data_type;
    END LOOP;
END $$;

-- Test the get_discussions function directly
DO $$
DECLARE
    test_auth_id UUID := 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID;
    test_result RECORD;
    result_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== TESTING GET_DISCUSSIONS FUNCTION ===';
    
    -- Test if function exists and works
    BEGIN
        FOR test_result IN SELECT * FROM get_discussions(test_auth_id)
        LOOP
            result_count := result_count + 1;
            RAISE NOTICE 'Discussion %: %', result_count, test_result.title;
            RAISE NOTICE '  ID: %', test_result.id;
            RAISE NOTICE '  Participant: %', test_result.is_participant;
            RAISE NOTICE '  Creator: %', test_result.creator_name;
            RAISE NOTICE '---';
        END LOOP;
        
        RAISE NOTICE 'GET_DISCUSSIONS RETURNED % DISCUSSIONS', result_count;
        
        IF result_count = 0 THEN
            RAISE NOTICE '❌ Function returned 0 discussions';
            
            -- Check if discussions exist in database
            SELECT COUNT(*) INTO result_count FROM discussions;
            RAISE NOTICE 'Total discussions in database: %', result_count;
            
            IF result_count > 0 THEN
                RAISE NOTICE '❌ Problem: Discussions exist but function returns none';
                RAISE NOTICE 'This suggests an issue with the function logic';
            ELSE
                RAISE NOTICE '✅ No discussions in database - this is expected';
            END IF;
        ELSE
            RAISE NOTICE '✅ Function working correctly';
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '❌ Error calling get_discussions: %', SQLERRM;
    END;
END $$;

-- Check if user exists
DO $$
DECLARE
    test_auth_id UUID := 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID;
    user_uuid UUID;
    user_name TEXT;
BEGIN
    RAISE NOTICE '=== USER VERIFICATION ===';
    
    SELECT u.id, u.name INTO user_uuid, user_name
    FROM users u
    WHERE u.auth_user_id = test_auth_id;
    
    IF user_uuid IS NOT NULL THEN
        RAISE NOTICE '✅ User found: % (ID: %)', user_name, user_uuid;
    ELSE
        RAISE NOTICE '❌ User not found for auth_user_id: %', test_auth_id;
    END IF;
END $$;

-- Check discussions table
DO $$
DECLARE
    discussion_count INTEGER;
    discussion_record RECORD;
BEGIN
    RAISE NOTICE '=== DISCUSSIONS TABLE CHECK ===';
    
    SELECT COUNT(*) INTO discussion_count FROM discussions;
    RAISE NOTICE 'Total discussions: %', discussion_count;
    
    IF discussion_count > 0 THEN
        RAISE NOTICE 'Sample discussions:';
        FOR discussion_record IN 
            SELECT id, title, created_at, created_by
            FROM discussions
            ORDER BY created_at DESC
            LIMIT 3
        LOOP
            RAISE NOTICE '- %: % (Created: %, By: %)', 
                         discussion_record.id, 
                         discussion_record.title, 
                         discussion_record.created_at,
                         discussion_record.created_by;
        END LOOP;
    END IF;
END $$;

-- Final diagnosis
DO $$
BEGIN
    RAISE NOTICE '=== DIAGNOSIS COMPLETE ===';
    RAISE NOTICE 'Check the logs above to see:';
    RAISE NOTICE '1. What discussion functions exist';
    RAISE NOTICE '2. If get_discussions works';
    RAISE NOTICE '3. If user exists';
    RAISE NOTICE '4. If discussions exist in database';
    RAISE NOTICE 'This will help identify the root cause';
END $$;
