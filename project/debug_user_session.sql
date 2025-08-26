-- =====================================================
-- DEBUG USER SESSION ISSUES
-- =====================================================
-- Run this script to debug user session and logout problems

-- =====================================================
-- STEP 1: Check current user state
-- =====================================================

SELECT '=== CURRENT USER STATE ===' as info;

-- Check all users in the database
SELECT 'All users in database:' as info;
SELECT 
    id,
    auth_user_id,
    name,
    email,
    username,
    created_at,
    updated_at
FROM users 
ORDER BY created_at DESC;

-- =====================================================
-- STEP 2: Check for session-related issues
-- =====================================================

SELECT '=== SESSION ANALYSIS ===' as info;

-- Check if there are any orphaned records
SELECT 'Users without proper auth_user_id:' as info;
SELECT id, auth_user_id, name, email
FROM users 
WHERE auth_user_id IS NULL OR auth_user_id = '';

-- Check for duplicate auth_user_ids
SELECT 'Duplicate auth_user_ids (should be empty):' as info;
SELECT auth_user_id, COUNT(*) as count
FROM users 
GROUP BY auth_user_id 
HAVING COUNT(*) > 1;

-- =====================================================
-- STEP 3: Check RLS policies
-- =====================================================

SELECT '=== RLS POLICY CHECK ===' as info;

SELECT 'Current RLS policies:' as info;
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- =====================================================
-- STEP 4: Test function permissions
-- =====================================================

SELECT '=== FUNCTION PERMISSIONS ===' as info;

SELECT 'Function security types:' as info;
SELECT 
    routine_name,
    security_type,
    is_deterministic
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_type = 'FUNCTION'
ORDER BY routine_name;

-- =====================================================
-- STEP 5: Manual cleanup (if needed)
-- =====================================================

-- Uncomment the following section if you need to clean up a specific user
-- Replace 'USER_AUTH_ID_HERE' with the actual auth_user_id from your user

/*
SELECT '=== MANUAL USER CLEANUP ===' as info;

-- Get the user details first
SELECT 'User to clean up:' as info;
SELECT id, auth_user_id, name, email, created_at
FROM users 
WHERE auth_user_id = 'USER_AUTH_ID_HERE';

-- Delete the user (uncomment if needed)
-- DELETE FROM users WHERE auth_user_id = 'USER_AUTH_ID_HERE';

-- Verify deletion
SELECT 'Users after cleanup:' as info;
SELECT id, auth_user_id, name, email
FROM users 
ORDER BY created_at DESC;
*/

-- =====================================================
-- STEP 6: Check for any database constraints
-- =====================================================

SELECT '=== DATABASE CONSTRAINTS ===' as info;

SELECT 'Table constraints:' as info;
SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_schema = 'public'
AND tc.table_name IN ('users', 'user_personality_profiles', 'user_favorites')
ORDER BY tc.table_name, tc.constraint_type;

-- =====================================================
-- STEP 7: Summary
-- =====================================================

SELECT '=== DEBUG SUMMARY ===' as info;

SELECT 
    'Total users:' as metric,
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
    'Users with NULL auth_user_id:' as metric,
    COUNT(*)::TEXT as value
FROM users 
WHERE auth_user_id IS NULL
UNION ALL
SELECT 
    'RLS policies:' as metric,
    COUNT(*)::TEXT as value
FROM pg_policies 
WHERE schemaname = 'public';
