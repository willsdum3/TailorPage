-- =====================================================
-- DEBUG USER CREATION ISSUES
-- =====================================================
-- Run this script to debug user creation problems

-- =====================================================
-- STEP 1: Check current database state
-- =====================================================

SELECT '=== CURRENT DATABASE STATE ===' as info;

-- Check if tables exist
SELECT 'Tables in database:' as info;
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Check if functions exist
SELECT 'Functions in database:' as info;
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_type = 'FUNCTION'
ORDER BY routine_name;

-- Check current users
SELECT 'Current users in users table:' as info;
SELECT id, auth_user_id, name, email, username, created_at 
FROM users 
ORDER BY created_at DESC;

-- Check RLS policies
SELECT 'RLS policies:' as info;
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- =====================================================
-- STEP 2: Test the get_or_create_user function
-- =====================================================

SELECT '=== TESTING get_or_create_user FUNCTION ===' as info;

-- Test with a dummy UUID (this will fail but show us the function works)
DO $$
DECLARE
    test_result UUID;
    test_error TEXT;
BEGIN
    BEGIN
        SELECT get_or_create_user(
            '00000000-0000-0000-0000-000000000000'::UUID,
            'Test User',
            'test@example.com',
            'testuser',
            NULL
        ) INTO test_result;
        
        RAISE NOTICE 'Function executed successfully, returned: %', test_result;
    EXCEPTION WHEN OTHERS THEN
        test_error := SQLERRM;
        RAISE NOTICE 'Function error: %', test_error;
    END;
END $$;

-- =====================================================
-- STEP 3: Check for common issues
-- =====================================================

SELECT '=== CHECKING FOR COMMON ISSUES ===' as info;

-- Check if there are any duplicate auth_user_ids
SELECT 'Duplicate auth_user_ids (should be empty):' as info;
SELECT auth_user_id, COUNT(*) as count
FROM users 
GROUP BY auth_user_id 
HAVING COUNT(*) > 1;

-- Check if there are any duplicate emails
SELECT 'Duplicate emails (should be empty):' as info;
SELECT email, COUNT(*) as count
FROM users 
GROUP BY email 
HAVING COUNT(*) > 1;

-- Check if there are any duplicate usernames
SELECT 'Duplicate usernames (should be empty):' as info;
SELECT username, COUNT(*) as count
FROM users 
WHERE username IS NOT NULL
GROUP BY username 
HAVING COUNT(*) > 1;

-- Check for any NULL values in required fields
SELECT 'Users with NULL required fields:' as info;
SELECT id, auth_user_id, name, email
FROM users 
WHERE auth_user_id IS NULL 
   OR name IS NULL 
   OR email IS NULL;

-- =====================================================
-- STEP 4: Check function permissions
-- =====================================================

SELECT '=== CHECKING FUNCTION PERMISSIONS ===' as info;

SELECT 'Function permissions:' as info;
SELECT 
    routine_name,
    routine_type,
    security_type,
    is_deterministic
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_type = 'FUNCTION'
ORDER BY routine_name;

-- =====================================================
-- STEP 5: Manual test with real data
-- =====================================================

-- Uncomment and modify the following section to test with a real user ID
-- Replace 'YOUR_TEST_USER_ID' with an actual Supabase Auth user ID

/*
SELECT '=== MANUAL TEST WITH REAL USER ===' as info;

DO $$
DECLARE
    test_user_id UUID := 'YOUR_TEST_USER_ID'::UUID;
    test_result UUID;
BEGIN
    SELECT get_or_create_user(
        test_user_id,
        'Manual Test User',
        'manual-test@example.com',
        'manualtestuser',
        NULL
    ) INTO test_result;
    
    RAISE NOTICE 'Manual test successful, user ID: %', test_result;
    
    -- Verify the user was created
    SELECT 'Created user details:' as info;
    SELECT id, auth_user_id, name, email, username 
    FROM users 
    WHERE auth_user_id = test_user_id;
END $$;
*/

-- =====================================================
-- STEP 6: Summary
-- =====================================================

SELECT '=== DEBUG SUMMARY ===' as info;
SELECT 
    'Total users in database:' as metric,
    COUNT(*)::TEXT as value
FROM users
UNION ALL
SELECT 
    'Users created today:' as metric,
    COUNT(*)::TEXT as value
FROM users 
WHERE DATE(created_at) = CURRENT_DATE
UNION ALL
SELECT 
    'Functions available:' as metric,
    COUNT(*)::TEXT as value
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_type = 'FUNCTION';
