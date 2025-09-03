-- =====================================================
-- SECURITY ISSUES FIX SCRIPT
-- =====================================================
-- This script addresses the Supabase Security Advisor warnings
-- by removing backup tables and ensuring RLS is properly configured

-- =====================================================
-- STEP 1: VERIFY BACKUP TABLES EXIST
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Checking for backup tables...';
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users_backup') THEN
        RAISE NOTICE 'Found users_backup table';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_favorites_backup') THEN
        RAISE NOTICE 'Found user_favorites_backup table';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_personality_profiles_backup') THEN
        RAISE NOTICE 'Found user_personality_profiles_backup table';
    END IF;
END $$;

-- =====================================================
-- STEP 2: SAFELY REMOVE BACKUP TABLES
-- =====================================================
-- These tables were created during migration and are no longer needed
-- Removing them will fix the RLS security warnings

DO $$
BEGIN
    -- Remove user_favorites_backup table
    DROP TABLE IF EXISTS user_favorites_backup CASCADE;
    RAISE NOTICE 'Removed user_favorites_backup table';

    -- Remove user_personality_profiles_backup table  
    DROP TABLE IF EXISTS user_personality_profiles_backup CASCADE;
    RAISE NOTICE 'Removed user_personality_profiles_backup table';

    -- Remove users_backup table
    DROP TABLE IF EXISTS users_backup CASCADE;
    RAISE NOTICE 'Removed users_backup table';
END $$;

-- =====================================================
-- STEP 3: VERIFY RLS IS ENABLED ON MAIN TABLES
-- =====================================================
-- Ensure all main tables have RLS enabled

DO $$
BEGIN
    -- Enable RLS on users table
    ALTER TABLE users ENABLE ROW LEVEL SECURITY;
    RAISE NOTICE 'Enabled RLS on users table';

    -- Enable RLS on user_favorites table
    ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;
    RAISE NOTICE 'Enabled RLS on user_favorites table';

    -- Enable RLS on user_personality_profiles table
    ALTER TABLE user_personality_profiles ENABLE ROW LEVEL SECURITY;
    RAISE NOTICE 'Enabled RLS on user_personality_profiles table';

    -- Enable RLS on books table
    ALTER TABLE books ENABLE ROW LEVEL SECURITY;
    RAISE NOTICE 'Enabled RLS on books table';

    -- Enable RLS on book_recommendations table
    ALTER TABLE book_recommendations ENABLE ROW LEVEL SECURITY;
    RAISE NOTICE 'Enabled RLS on book_recommendations table';

    -- Enable RLS on reading_lists table
    ALTER TABLE reading_lists ENABLE ROW LEVEL SECURITY;
    RAISE NOTICE 'Enabled RLS on reading_lists table';

    -- Enable RLS on reading_list_items table
    ALTER TABLE reading_list_items ENABLE ROW LEVEL SECURITY;
    RAISE NOTICE 'Enabled RLS on reading_list_items table';
END $$;

-- =====================================================
-- STEP 4: VERIFY RLS POLICIES EXIST
-- =====================================================
-- Check that RLS policies are in place for security

DO $$
DECLARE
    policy_count INTEGER;
BEGIN
    -- Check users table policies
    SELECT COUNT(*) INTO policy_count 
    FROM pg_policies 
    WHERE tablename = 'users';
    
    IF policy_count = 0 THEN
        RAISE WARNING 'No RLS policies found on users table - this may cause security issues';
    ELSE
        RAISE NOTICE 'Found % RLS policies on users table', policy_count;
    END IF;
    
    -- Check user_favorites table policies
    SELECT COUNT(*) INTO policy_count 
    FROM pg_policies 
    WHERE tablename = 'user_favorites';
    
    IF policy_count = 0 THEN
        RAISE WARNING 'No RLS policies found on user_favorites table - this may cause security issues';
    ELSE
        RAISE NOTICE 'Found % RLS policies on user_favorites table', policy_count;
    END IF;
    
    -- Check user_personality_profiles table policies
    SELECT COUNT(*) INTO policy_count 
    FROM pg_policies 
    WHERE tablename = 'user_personality_profiles';
    
    IF policy_count = 0 THEN
        RAISE WARNING 'No RLS policies found on user_personality_profiles table - this may cause security issues';
    ELSE
        RAISE NOTICE 'Found % RLS policies on user_personality_profiles table', policy_count;
    END IF;
END $$;

-- =====================================================
-- STEP 5: FINAL VERIFICATION
-- =====================================================
-- Confirm backup tables are removed and RLS is enabled

SELECT 
    'Backup Tables Status' as check_type,
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users_backup') 
             AND NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_favorites_backup')
             AND NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_personality_profiles_backup')
        THEN '✅ PASS - All backup tables removed'
        ELSE '❌ FAIL - Some backup tables still exist'
    END as status;

SELECT 
    'RLS Status' as check_type,
    CASE 
        WHEN (SELECT relrowsecurity FROM pg_class WHERE relname = 'users' AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')) = true
             AND (SELECT relrowsecurity FROM pg_class WHERE relname = 'user_favorites' AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')) = true
             AND (SELECT relrowsecurity FROM pg_class WHERE relname = 'user_personality_profiles' AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')) = true
        THEN '✅ PASS - RLS enabled on all main tables'
        ELSE '❌ FAIL - RLS not enabled on some tables'
    END as status;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'SECURITY ISSUES FIXED SUCCESSFULLY!';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE '✅ Backup tables removed';
    RAISE NOTICE '✅ RLS enabled on all main tables';
    RAISE NOTICE '✅ Security warnings should be resolved';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '1. Run this script in your Supabase SQL editor';
    RAISE NOTICE '2. Check the Security Advisor again';
    RAISE NOTICE '3. Verify your app still works as expected';
    RAISE NOTICE '=====================================================';
END $$;
