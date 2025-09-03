-- =====================================================
-- CHECK EXISTING TABLES SCRIPT
-- =====================================================
-- This script checks what tables actually exist in your database
-- Run this first to see what we're working with

-- =====================================================
-- CHECK 1: LIST ALL TABLES IN PUBLIC SCHEMA
-- =====================================================
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- =====================================================
-- CHECK 2: CHECK WHICH TABLES HAVE RLS ENABLED
-- =====================================================
SELECT 
    c.relname as table_name,
    CASE 
        WHEN c.relrowsecurity THEN '✅ ENABLED'
        ELSE '❌ DISABLED'
    END as rls_status
FROM pg_class c
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public' 
    AND c.relkind = 'r'  -- Only regular tables
ORDER BY c.relname;

-- =====================================================
-- CHECK 3: COUNT RLS POLICIES PER TABLE
-- =====================================================
SELECT 
    tablename,
    COUNT(*) as policy_count,
    CASE 
        WHEN COUNT(*) >= 3 THEN '✅ ADEQUATE'
        WHEN COUNT(*) >= 1 THEN '⚠️ MINIMAL'
        ELSE '❌ NONE'
    END as policy_status
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;
