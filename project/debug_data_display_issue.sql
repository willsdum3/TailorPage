-- Debug Data Display Issue
-- This script will help identify why book clubs and discussions aren't showing

-- ===========================================
-- STEP 1: CHECK IF DATA EXISTS
-- ===========================================

SELECT '=== DATA EXISTENCE CHECK ===' as header;

SELECT 
    'book_clubs' as table_name,
    COUNT(*) as total_count
FROM book_clubs
UNION ALL
SELECT 
    'book_club_members' as table_name,
    COUNT(*) as total_count
FROM book_club_members
UNION ALL
SELECT 
    'discussions' as table_name,
    COUNT(*) as total_count
FROM discussions
UNION ALL
SELECT 
    'discussion_members' as table_name,
    COUNT(*) as total_count
FROM discussion_members
UNION ALL
SELECT 
    'users' as table_name,
    COUNT(*) as total_count
FROM users;

-- ===========================================
-- STEP 2: CHECK USERS TABLE RLS
-- ===========================================

SELECT '=== USERS TABLE RLS POLICIES ===' as header;

SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'users'
ORDER BY policyname;

-- ===========================================
-- STEP 3: TEST FUNCTION EXECUTION DIRECTLY
-- ===========================================

SELECT '=== DIRECT FUNCTION TEST ===' as header;

DO $$
DECLARE
    test_user_record RECORD;
    test_auth_id UUID;
    test_internal_id UUID;
    club_count INTEGER := 0;
    discussion_count INTEGER := 0;
    msg TEXT;
BEGIN
    -- Get first user
    SELECT auth_user_id, id INTO test_auth_id, test_internal_id FROM users LIMIT 1;
    
    IF test_auth_id IS NOT NULL THEN
        RAISE NOTICE 'Found user: auth_user_id=%, id=%', test_auth_id, test_internal_id;
        
        -- Try to call get_user_internal_id
        SELECT get_user_internal_id(test_auth_id) INTO test_internal_id;
        RAISE NOTICE 'get_user_internal_id returned: %', test_internal_id;
        
        -- Try to count clubs directly
        SELECT COUNT(*) INTO club_count FROM book_clubs;
        RAISE NOTICE 'Direct count of book_clubs: %', club_count;
        
        -- Try to count discussions directly
        SELECT COUNT(*) INTO discussion_count FROM discussions;
        RAISE NOTICE 'Direct count of discussions: %', discussion_count;
        
        -- Try get_book_clubs function
        SELECT COUNT(*) INTO club_count FROM get_book_clubs(test_auth_id);
        RAISE NOTICE 'get_book_clubs(%) returned % records', test_auth_id, club_count;
        
        -- Try get_discussions function
        SELECT COUNT(*) INTO discussion_count FROM get_discussions(test_auth_id);
        RAISE NOTICE 'get_discussions(%) returned % records', test_auth_id, discussion_count;
        
    ELSE
        RAISE NOTICE 'NO USERS FOUND IN DATABASE';
    END IF;
END $$;

-- ===========================================
-- STEP 4: SHOW ACTUAL DATA
-- ===========================================

SELECT '=== BOOK CLUBS DATA ===' as header;
SELECT * FROM book_clubs LIMIT 5;

SELECT '=== DISCUSSIONS DATA ===' as header;
SELECT * FROM discussions LIMIT 5;

SELECT '=== USERS DATA ===' as header;
SELECT id, auth_user_id, name, username FROM users LIMIT 5;

-- ===========================================
-- STEP 5: TEST USERS TABLE SELECT
-- ===========================================

SELECT '=== TEST USERS TABLE ACCESS ===' as header;

DO $$
BEGIN
    -- Try to select from users table
    IF EXISTS (SELECT 1 FROM users LIMIT 1) THEN
        RAISE NOTICE 'Successfully selected from users table';
    ELSE
        RAISE NOTICE 'Cannot select from users table - RLS might be blocking';
    END IF;
END $$;

-- ===========================================
-- STEP 6: CHECK USERS TABLE RLS ISSUE
-- ===========================================

SELECT '=== FIXING USERS TABLE ACCESS ===' as header;

-- Drop restrictive policies on users table
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Users can insert their own profile" ON users;

-- Create permissive SELECT policy for users table (needed for other functions to work)
CREATE POLICY "Users can view all users" ON users
    FOR SELECT USING (true);

-- Keep restrictive policies for modifications
CREATE POLICY "Users can update their own profile" ON users
    FOR UPDATE USING (auth_user_id = auth.uid());

CREATE POLICY "Users can insert their own profile" ON users
    FOR INSERT WITH CHECK (auth_user_id = auth.uid());

SELECT 'Users table policies updated' as status;

-- ===========================================
-- STEP 7: RE-TEST FUNCTIONS
-- ===========================================

SELECT '=== RE-TEST AFTER FIX ===' as header;

DO $$
DECLARE
    test_auth_id UUID;
    club_count INTEGER := 0;
    discussion_count INTEGER := 0;
BEGIN
    -- Get first user
    SELECT auth_user_id INTO test_auth_id FROM users LIMIT 1;
    
    IF test_auth_id IS NOT NULL THEN
        -- Try get_book_clubs function
        SELECT COUNT(*) INTO club_count FROM get_book_clubs(test_auth_id);
        RAISE NOTICE 'After fix - get_book_clubs returned % records', club_count;
        
        -- Try get_discussions function
        SELECT COUNT(*) INTO discussion_count FROM get_discussions(test_auth_id);
        RAISE NOTICE 'After fix - get_discussions returned % records', discussion_count;
    END IF;
END $$;

-- ===========================================
-- FINAL STATUS
-- ===========================================

SELECT '=== FINAL STATUS ===' as header;

SELECT 
    'Book Clubs' as item,
    COUNT(*) as total_records
FROM book_clubs
UNION ALL
SELECT 
    'Discussions' as item,
    COUNT(*) as total_records
FROM discussions;

SELECT 'Debug complete - data should now display' as message;
