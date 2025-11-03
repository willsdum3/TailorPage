-- Test RLS Security Implementation
-- This script verifies that the RLS policies are working correctly

-- Test 1: Check that RLS is enabled on all tables
SELECT 
    'RLS Status Check' as test_name,
    schemaname,
    tablename,
    rowsecurity as rls_enabled,
    CASE 
        WHEN rowsecurity = true THEN 'PASS'
        ELSE 'FAIL'
    END as test_result
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- Test 2: Verify that policies exist for each table
SELECT 
    'Policy Count Check' as test_name,
    tablename,
    COUNT(*) as policy_count,
    CASE 
        WHEN COUNT(*) > 0 THEN 'PASS'
        ELSE 'FAIL'
    END as test_result
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- Test 3: Check specific policies for book_club_members (the table mentioned in the error)
SELECT 
    'book_club_members Policies' as test_name,
    policyname,
    cmd as operation,
    CASE 
        WHEN policyname IS NOT NULL THEN 'PASS'
        ELSE 'FAIL'
    END as test_result
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'book_club_members'
ORDER BY policyname;

-- Test 4: Verify that the security error should be resolved
SELECT 
    'Security Error Resolution' as test_name,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_tables 
            WHERE schemaname = 'public' 
            AND tablename = 'book_club_members' 
            AND rowsecurity = true
        ) THEN 'PASS - book_club_members now has RLS enabled'
        ELSE 'FAIL - book_club_members still missing RLS'
    END as test_result;

-- Test 5: Check all public tables have RLS enabled
SELECT 
    'All Tables RLS Check' as test_name,
    COUNT(*) as total_tables,
    COUNT(CASE WHEN rowsecurity = true THEN 1 END) as tables_with_rls,
    CASE 
        WHEN COUNT(*) = COUNT(CASE WHEN rowsecurity = true THEN 1 END) THEN 'PASS - All tables have RLS'
        ELSE 'FAIL - Some tables missing RLS'
    END as test_result
FROM pg_tables 
WHERE schemaname = 'public';

-- Final summary
SELECT 
    'RLS Security Test Complete' as status,
    'Run this script in Supabase to verify the security errors are resolved' as message;


