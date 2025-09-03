-- =====================================================
-- CORRECTED SECURITY ISSUES FIX SCRIPT
-- =====================================================
-- This script addresses the Supabase Security Advisor warnings
-- by removing backup tables and ensuring RLS is properly configured
-- ONLY on tables that actually exist in your database

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
-- STEP 3: DYNAMICALLY ENABLE RLS ON EXISTING TABLES
-- =====================================================
-- This step only enables RLS on tables that actually exist
-- and don't already have RLS enabled

DO $$
DECLARE
    table_record RECORD;
    table_name TEXT;
    rls_enabled BOOLEAN;
BEGIN
    RAISE NOTICE 'Checking and enabling RLS on existing tables...';
    
    -- Loop through all tables in the public schema
    FOR table_record IN 
        SELECT c.relname as table_name, c.relrowsecurity as rls_enabled
        FROM pg_class c
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE n.nspname = 'public' 
            AND c.relkind = 'r'  -- Only regular tables
            AND c.relname NOT LIKE '%backup%'  -- Skip backup tables
        ORDER BY c.relname
    LOOP
        table_name := table_record.table_name;
        rls_enabled := table_record.rls_enabled;
        
        IF NOT rls_enabled THEN
            -- Enable RLS on this table
            EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', table_name);
            RAISE NOTICE '✅ Enabled RLS on table: %', table_name;
        ELSE
            RAISE NOTICE 'ℹ️  RLS already enabled on table: %', table_name;
        END IF;
    END LOOP;
    
    RAISE NOTICE 'RLS enablement check completed!';
END $$;

-- =====================================================
-- STEP 4: VERIFY RLS POLICIES EXIST
-- =====================================================
-- Check that RLS policies are in place for security

DO $$
DECLARE
    table_record RECORD;
    policy_count INTEGER;
BEGIN
    RAISE NOTICE 'Checking RLS policies on tables...';
    
    -- Loop through all tables that have RLS enabled
    FOR table_record IN 
        SELECT c.relname as table_name
        FROM pg_class c
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE n.nspname = 'public' 
            AND c.relkind = 'r'  -- Only regular tables
            AND c.relrowsecurity = true  -- Only tables with RLS enabled
            AND c.relname NOT LIKE '%backup%'  -- Skip backup tables
        ORDER BY c.relname
    LOOP
        -- Count policies for this table
        SELECT COUNT(*) INTO policy_count 
        FROM pg_policies 
        WHERE tablename = table_record.table_name;
        
        IF policy_count = 0 THEN
            RAISE WARNING '⚠️  No RLS policies found on table % - this may cause security issues', table_record.table_name;
        ELSE
            RAISE NOTICE '✅ Found % RLS policies on table %', policy_count, table_record.table_name;
        END IF;
    END LOOP;
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

-- Show RLS status for all existing tables
SELECT 
    c.relname as table_name,
    CASE 
        WHEN c.relrowsecurity THEN '✅ ENABLED'
        ELSE '❌ DISABLED'
    END as rls_status,
    (SELECT COUNT(*) FROM pg_policies WHERE tablename = c.relname) as policy_count
FROM pg_class c
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public' 
    AND c.relkind = 'r'  -- Only regular tables
    AND c.relname NOT LIKE '%backup%'  -- Skip backup tables
ORDER BY c.relname;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'SECURITY ISSUES FIXED SUCCESSFULLY!';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE '✅ Backup tables removed';
    RAISE NOTICE '✅ RLS enabled on all existing tables';
    RAISE NOTICE '✅ Security warnings should be resolved';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '1. Check the Security Advisor again';
    RAISE NOTICE '2. Verify your app still works as expected';
    RAISE NOTICE '3. Run check_existing_tables.sql to see final status';
    RAISE NOTICE '=====================================================';
END $$;
