-- =====================================================
-- SECURITY STATUS CHECK SCRIPT
-- =====================================================
-- Run this script to check the current security status
-- before and after applying the security fixes

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
-- CHECK 2: RLS STATUS ON MAIN TABLES
-- =====================================================
SELECT 
    'RLS Status' as check_name,
    CASE 
        WHEN (SELECT relrowsecurity FROM pg_class WHERE relname = 'users' AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')) = true
             AND (SELECT relrowsecurity FROM pg_class WHERE relname = 'user_favorites' AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')) = true
             AND (SELECT relrowsecurity FROM pg_class WHERE relname = 'user_personality_profiles' AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')) = true
        THEN '✅ ENABLED - Secure'
        ELSE '❌ DISABLED - Security Risk'
    END as status,
    CASE 
        WHEN (SELECT relrowsecurity FROM pg_class WHERE relname = 'users' AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')) = true
             AND (SELECT relrowsecurity FROM pg_class WHERE relname = 'user_favorites' AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')) = true
             AND (SELECT relrowsecurity FROM pg_class WHERE relname = 'user_personality_profiles' AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')) = true
        THEN 'All main tables have RLS enabled'
        ELSE 'Some tables missing RLS'
    END as details;

-- =====================================================
-- CHECK 3: RLS POLICIES COUNT
-- =====================================================
SELECT 
    'RLS Policies' as check_name,
    CASE 
        WHEN (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'users') >= 3
             AND (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'user_favorites') >= 4
             AND (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'user_personality_profiles') >= 3
        THEN '✅ ADEQUATE - Secure'
        ELSE '⚠️ INSUFFICIENT - May have security gaps'
    END as status,
    'Users: ' || (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'users') ||
    ', Favorites: ' || (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'user_favorites') ||
    ', Profiles: ' || (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'user_personality_profiles') as details;

-- =====================================================
-- CHECK 4: OVERALL SECURITY SCORE
-- =====================================================
WITH security_checks AS (
    SELECT 
        -- Backup tables check
        CASE 
            WHEN NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name LIKE '%backup%') THEN 1
            ELSE 0
        END as backup_secure,
        
        -- RLS enabled check
        CASE 
            WHEN (SELECT relrowsecurity FROM pg_class WHERE relname = 'users' AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')) = true
                 AND (SELECT relrowsecurity FROM pg_class WHERE relname = 'user_favorites' AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')) = true
                 AND (SELECT relrowsecurity FROM pg_class WHERE relname = 'user_personality_profiles' AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')) = true
            THEN 1
            ELSE 0
        END as rls_enabled,
        
        -- RLS policies check
        CASE 
            WHEN (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'users') >= 3
                 AND (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'user_favorites') >= 4
                 AND (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'user_personality_profiles') >= 3
            THEN 1
            ELSE 0
        END as policies_adequate
)
SELECT 
    'Overall Security' as check_name,
    CASE 
        WHEN (backup_secure + rls_enabled + policies_adequate) = 3 THEN '🟢 EXCELLENT - Fully Secure'
        WHEN (backup_secure + rls_enabled + policies_adequate) = 2 THEN '🟡 GOOD - Minor Issues'
        WHEN (backup_secure + rls_enabled + policies_adequate) = 1 THEN '🟠 POOR - Significant Issues'
        ELSE '🔴 CRITICAL - Major Security Problems'
    END as status,
    'Score: ' || (backup_secure + rls_enabled + policies_adequate) || '/3' as details;

-- =====================================================
-- SUMMARY
-- =====================================================
SELECT '=====================================================' as message
UNION ALL
SELECT 'SECURITY STATUS SUMMARY' as message
UNION ALL
SELECT '=====================================================' as message
UNION ALL
SELECT 'Run fix_security_issues.sql to resolve any issues' as message
UNION ALL
SELECT '=====================================================' as message;
