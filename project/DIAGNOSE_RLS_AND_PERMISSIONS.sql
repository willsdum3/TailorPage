-- DIAGNOSE RLS POLICIES AND PERMISSIONS
-- Check if RLS is blocking the functions

-- 1. Check if RLS is enabled on tables
SELECT 
    'RLS Status' as check_type,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename IN ('book_clubs', 'book_club_members', 'book_club_messages', 'users', 'book_selection_polls', 'poll_options', 'poll_votes')
AND schemaname = 'public';

-- 2. Check RLS policies
SELECT 
    'RLS Policies' as check_type,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename IN ('book_clubs', 'book_club_members', 'book_club_messages', 'users', 'book_selection_polls', 'poll_options', 'poll_votes')
AND schemaname = 'public';

-- 3. Test function calls directly
DO $$
DECLARE
    test_user_auth_id UUID;
    test_user_internal_id UUID;
    test_club_id UUID;
    test_result RECORD;
BEGIN
    -- Get test data
    SELECT auth_user_id, id INTO test_user_auth_id, test_user_internal_id 
    FROM users LIMIT 1;
    
    SELECT id INTO test_club_id 
    FROM book_clubs 
    WHERE created_by = test_user_internal_id 
    LIMIT 1;
    
    IF test_user_auth_id IS NULL THEN
        RAISE NOTICE 'ERROR: No users found';
        RETURN;
    END IF;
    
    IF test_club_id IS NULL THEN
        RAISE NOTICE 'ERROR: No book clubs found for user %', test_user_internal_id;
        RETURN;
    END IF;
    
    RAISE NOTICE '=== DIRECT FUNCTION TEST ===';
    RAISE NOTICE 'User auth_id: %', test_user_auth_id;
    RAISE NOTICE 'User internal_id: %', test_user_internal_id;
    RAISE NOTICE 'Club id: %', test_club_id;
    RAISE NOTICE '';
    
    -- Test 1: Check user lookup
    BEGIN
        RAISE NOTICE '1. Testing user lookup...';
        SELECT u.id, u.auth_user_id INTO test_result FROM users u WHERE u.auth_user_id::TEXT = test_user_auth_id::TEXT;
        RAISE NOTICE '   User found: internal_id=%, auth_id=%', test_result.id, test_result.auth_user_id;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '   User lookup FAILED: %', SQLERRM;
    END;
    
    -- Test 2: Check club membership
    BEGIN
        RAISE NOTICE '2. Testing club membership...';
        DECLARE
            is_member BOOLEAN;
            is_creator BOOLEAN;
        BEGIN
            SELECT EXISTS(SELECT 1 FROM book_club_members bcm WHERE bcm.club_id = test_club_id AND bcm.user_id = test_user_internal_id) INTO is_member;
            SELECT EXISTS(SELECT 1 FROM book_clubs bc WHERE bc.id = test_club_id AND bc.created_by = test_user_internal_id) INTO is_creator;
            RAISE NOTICE '   Membership: is_member=%, is_creator=%', is_member, is_creator;
        END;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '   Membership check FAILED: %', SQLERRM;
    END;
    
    -- Test 3: Direct function call
    BEGIN
        RAISE NOTICE '3. Testing add_book_club_message directly...';
        FOR test_result IN 
            SELECT * FROM add_book_club_message(test_user_auth_id, test_club_id, 'Direct test message')
        LOOP
            RAISE NOTICE '   Result: success=%, message=%', test_result.success, test_result.message;
        END LOOP;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '   Direct function call FAILED: %', SQLERRM;
    END;
    
END $$;

-- 4. Check if functions have SECURITY DEFINER
SELECT 
    'Function Security' as check_type,
    p.proname as function_name,
    p.prosecdef as security_definer,
    p.provolatile as volatility
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname IN ('add_book_club_message', 'get_book_club_messages', 'create_book_selection_poll', 'get_club_polls', 'vote_on_poll', 'update_book_club_details', 'toggle_book_club_visibility')
AND n.nspname = 'public';

-- 5. Check table access permissions
SELECT 
    'Table Permissions' as check_type,
    t.table_name,
    p.privilege_type,
    p.grantee
FROM information_schema.table_privileges p
JOIN information_schema.tables t ON p.table_name = t.table_name
WHERE t.table_name IN ('book_clubs', 'book_club_members', 'book_club_messages', 'users', 'book_selection_polls', 'poll_options', 'poll_votes')
AND t.table_schema = 'public'
ORDER BY t.table_name, p.privilege_type;
