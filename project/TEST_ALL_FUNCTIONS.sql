-- Quick test of all book club functions
-- Run this to see which function is actually failing

DO $$
DECLARE
    test_user_auth_id UUID;
    test_user_internal_id UUID;
    test_club_id UUID;
    test_result RECORD;
BEGIN
    -- Get a test user
    SELECT auth_user_id, id INTO test_user_auth_id, test_user_internal_id 
    FROM users LIMIT 1;
    
    -- Get a test club
    SELECT id INTO test_club_id 
    FROM book_clubs 
    WHERE created_by = test_user_internal_id OR 
          id IN (SELECT club_id FROM book_club_members WHERE user_id = test_user_internal_id)
    LIMIT 1;
    
    IF test_user_auth_id IS NULL THEN
        RAISE NOTICE 'ERROR: No users found in database';
        RETURN;
    END IF;
    
    IF test_club_id IS NULL THEN
        RAISE NOTICE 'ERROR: No book clubs found for user';
        RETURN;
    END IF;
    
    RAISE NOTICE '=== TEST DATA ===';
    RAISE NOTICE 'User auth_id: %', test_user_auth_id;
    RAISE NOTICE 'Club id: %', test_club_id;
    RAISE NOTICE '';
    
    -- Test 1: add_book_club_message
    BEGIN
        RAISE NOTICE '1. Testing add_book_club_message...';
        FOR test_result IN 
            SELECT * FROM add_book_club_message(test_user_auth_id, test_club_id, 'Test message')
        LOOP
            RAISE NOTICE '   Result: success=%, message=%', test_result.success, test_result.message;
        END LOOP;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '   FAILED: %', SQLERRM;
    END;
    
    -- Test 2: get_book_club_messages
    BEGIN
        RAISE NOTICE '2. Testing get_book_club_messages...';
        DECLARE
            message_count INTEGER := 0;
        BEGIN
            FOR test_result IN 
                SELECT * FROM get_book_club_messages(test_user_auth_id, test_club_id)
            LOOP
                message_count := message_count + 1;
            END LOOP;
            RAISE NOTICE '   SUCCESS: Found % messages', message_count;
        END;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '   FAILED: %', SQLERRM;
    END;
    
    -- Test 3: update_book_club_details
    BEGIN
        RAISE NOTICE '3. Testing update_book_club_details...';
        FOR test_result IN 
            SELECT * FROM update_book_club_details(
                test_user_auth_id, 
                test_club_id,
                NULL, NULL, NULL, NULL, NULL
            )
        LOOP
            RAISE NOTICE '   Result: success=%, message=%', test_result.success, test_result.message;
        END LOOP;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '   FAILED: %', SQLERRM;
    END;
    
    -- Test 4: get_club_polls
    BEGIN
        RAISE NOTICE '4. Testing get_club_polls...';
        DECLARE
            poll_result JSONB;
        BEGIN
            SELECT get_club_polls(test_user_auth_id, test_club_id) INTO poll_result;
            RAISE NOTICE '   SUCCESS: Result type = %', pg_typeof(poll_result);
        END;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '   FAILED: %', SQLERRM;
    END;
    
    -- Test 5: toggle_book_club_visibility
    BEGIN
        RAISE NOTICE '5. Testing toggle_book_club_visibility...';
        FOR test_result IN 
            SELECT * FROM toggle_book_club_visibility(test_user_auth_id, test_club_id, TRUE)
        LOOP
            RAISE NOTICE '   Result: success=%, message=%, is_public=%', 
                test_result.success, test_result.message, test_result.is_public;
        END LOOP;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '   FAILED: %', SQLERRM;
    END;
    
    RAISE NOTICE '';
    RAISE NOTICE '=== TEST COMPLETE ===';
    RAISE NOTICE 'Check which functions succeeded and which failed above';
    
END $$;

-- Show table structures
SELECT 
    'Book Club Messages Table' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'book_club_messages'
AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT 
    'Book Clubs Table' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'book_clubs'
AND table_schema = 'public'
ORDER BY ordinal_position;
