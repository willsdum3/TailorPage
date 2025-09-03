-- =====================================================
-- SIMPLE SECURITY STATUS CHECK SCRIPT
-- =====================================================
-- This is a simpler, more reliable version that avoids complex subqueries
-- Run this script to check the current security status

-- =====================================================
-- CHECK 1: BACKUP TABLES STATUS
-- =====================================================
SELECT 
    'Backup Tables' as check_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users_backup') THEN '❌ EXISTS - Security Risk'
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_favorites_backup') THEN '❌ EXISTS - Security Risk'
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_personality_profiles_backup') THEN '❌ EXISTS - Security Risk'
        ELSE '✅ REMOVED - Secure'
    END as status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users_backup') THEN 'Found users_backup'
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_favorites_backup') THEN 'Found user_favorites_backup'
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_personality_profiles_backup') THEN 'Found user_personality_profiles_backup'
        ELSE 'All backup tables removed'
    END as details;

-- =====================================================
-- CHECK 2: RLS STATUS ON MAIN TABLES (SIMPLE VERSION)
-- =====================================================
-- Check each table individually to avoid subquery issues
SELECT 'RLS Status - Users' as check_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_class c 
                    JOIN pg_namespace n ON c.relnamespace = n.oid 
                    WHERE c.relname = 'users' AND n.nspname = 'public' AND c.relrowsecurity = true)
        THEN '✅ ENABLED - Secure'
        ELSE '❌ DISABLED - Security Risk'
    END as status,
    'users table RLS status' as details;

SELECT 'RLS Status - User Favorites' as check_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_class c 
                    JOIN pg_namespace n ON c.relnamespace = n.oid 
                    WHERE c.relname = 'user_favorites' AND n.nspname = 'public' AND c.relrowsecurity = true)
        THEN '✅ ENABLED - Secure'
        ELSE '❌ DISABLED - Security Risk'
    END as status,
    'user_favorites table RLS status' as details;

SELECT 'RLS Status - User Profiles' as check_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_class c 
                    JOIN pg_namespace n ON c.relnamespace = n.oid 
                    WHERE c.relname = 'user_personality_profiles' AND n.nspname = 'public' AND c.relrowsecurity = true)
        THEN '✅ ENABLED - Secure'
        ELSE '❌ DISABLED - Security Risk'
    END as status,
    'user_personality_profiles table RLS status' as details;

-- =====================================================
-- CHECK 3: RLS POLICIES COUNT (SIMPLE VERSION)
-- =====================================================
SELECT 'RLS Policies - Users' as check_name,
    CASE 
        WHEN (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'users') >= 3 THEN '✅ ADEQUATE - Secure'
        ELSE '⚠️ INSUFFICIENT - May have security gaps'
    END as status,
    'Found ' || (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'users') || ' policies' as details;

SELECT 'RLS Policies - User Favorites' as check_name,
    CASE 
        WHEN (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'user_favorites') >= 4 THEN '✅ ADEQUATE - Secure'
        ELSE '⚠️ INSUFFICIENT - May have security gaps'
    END as status,
    'Found ' || (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'user_favorites') || ' policies' as details;

SELECT 'RLS Policies - User Profiles' as check_name,
    CASE 
        WHEN (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'user_personality_profiles') >= 3 THEN '✅ ADEQUATE - Secure'
        ELSE '⚠️ INSUFFICIENT - May have security gaps'
    END as status,
    'Found ' || (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'user_personality_profiles') || ' policies' as details;

-- =====================================================
-- CHECK 4: OVERALL SECURITY ASSESSMENT
-- =====================================================
SELECT '=====================================================' as message
UNION ALL
SELECT 'SECURITY STATUS SUMMARY' as message
UNION ALL
SELECT '=====================================================' as message
UNION ALL
SELECT '✅ Green = Secure' as message
UNION ALL
SELECT '⚠️ Yellow = Minor Issues' as message
UNION ALL
SELECT '❌ Red = Security Risk' as message
UNION ALL
SELECT '=====================================================' as message
UNION ALL
SELECT 'Run fix_security_issues.sql to resolve any issues' as message
UNION ALL
SELECT '=====================================================' as message;
