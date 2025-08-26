-- =====================================================
-- MIGRATION VERIFICATION SCRIPT
-- =====================================================
-- This script verifies that the Supabase Auth migration was successful
-- Run this in your Supabase SQL editor after completing the migration

-- =====================================================
-- STEP 1: CHECK TABLE STRUCTURES
-- =====================================================

SELECT '=== TABLE STRUCTURES ===' as section;

-- Check users table
SELECT 
    'users' as table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name IN ('id', 'auth_user_id', 'name', 'username', 'email', 'image_url')
ORDER BY column_name;

-- Check user_favorites table
SELECT 
    'user_favorites' as table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_favorites' 
AND column_name IN ('id', 'auth_user_id', 'book_id', 'date_added')
ORDER BY column_name;

-- Check user_personality_profiles table
SELECT 
    'user_personality_profiles' as table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_personality_profiles' 
AND column_name IN ('id', 'auth_user_id', 'openness', 'conscientiousness')
ORDER BY column_name;

-- =====================================================
-- STEP 2: CHECK INDEXES
-- =====================================================

SELECT '=== INDEXES ===' as section;

SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename IN ('users', 'user_favorites', 'user_personality_profiles')
AND indexname LIKE '%auth_user_id%'
ORDER BY tablename, indexname;

-- =====================================================
-- STEP 3: CHECK RLS POLICIES
-- =====================================================

SELECT '=== RLS POLICIES ===' as section;

SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename IN ('users', 'user_favorites', 'user_personality_profiles')
ORDER BY tablename, policyname;

-- =====================================================
-- STEP 4: CHECK FUNCTIONS
-- =====================================================

SELECT '=== FUNCTIONS ===' as section;

SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN (
    'get_user_favorites',
    'save_book_to_favorites',
    'remove_book_from_favorites',
    'get_user_personality_profile',
    'save_user_personality_profile'
)
ORDER BY routine_name;

-- =====================================================
-- STEP 5: CHECK CONSTRAINTS
-- =====================================================

SELECT '=== CONSTRAINTS ===' as section;

SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name IN ('users', 'user_favorites', 'user_personality_profiles')
AND kcu.column_name LIKE '%auth_user_id%'
ORDER BY tc.table_name, tc.constraint_name;

-- =====================================================
-- STEP 6: TEST DATA ACCESS (If you have test users)
-- =====================================================

SELECT '=== DATA ACCESS TEST ===' as section;

-- This will only work if you have authenticated users
-- Replace 'test-user-id' with an actual Supabase Auth user ID

/*
-- Test user profile access
SELECT COUNT(*) as user_profiles
FROM users 
WHERE auth_user_id IS NOT NULL;

-- Test favorites access
SELECT COUNT(*) as user_favorites
FROM user_favorites 
WHERE auth_user_id IS NOT NULL;

-- Test personality profiles access
SELECT COUNT(*) as personality_profiles
FROM user_personality_profiles 
WHERE auth_user_id IS NOT NULL;
*/

-- =====================================================
-- STEP 7: MIGRATION STATUS SUMMARY
-- =====================================================

SELECT '=== MIGRATION STATUS ===' as section;

WITH migration_checks AS (
    -- Check if auth_user_id columns exist
    SELECT 
        'auth_user_id_columns' as check_name,
        COUNT(*) as status
    FROM information_schema.columns 
    WHERE table_name IN ('users', 'user_favorites', 'user_personality_profiles')
    AND column_name = 'auth_user_id'
    
    UNION ALL
    
    -- Check if RLS policies exist
    SELECT 
        'rls_policies' as check_name,
        COUNT(*) as status
    FROM pg_policies
    WHERE tablename IN ('users', 'user_favorites', 'user_personality_profiles')
    
    UNION ALL
    
    -- Check if functions exist
    SELECT 
        'functions' as check_name,
        COUNT(*) as status
    FROM information_schema.routines
    WHERE routine_schema = 'public'
    AND routine_name IN (
        'get_user_favorites',
        'save_book_to_favorites',
        'remove_book_from_favorites',
        'get_user_personality_profile',
        'save_user_personality_profile'
    )
    
    UNION ALL
    
    -- Check if indexes exist
    SELECT 
        'indexes' as check_name,
        COUNT(*) as status
    FROM pg_indexes
    WHERE tablename IN ('users', 'user_favorites', 'user_personality_profiles')
    AND indexname LIKE '%auth_user_id%'
)

SELECT 
    check_name,
    CASE 
        WHEN check_name = 'auth_user_id_columns' AND status = 3 THEN '✅ PASS'
        WHEN check_name = 'rls_policies' AND status >= 9 THEN '✅ PASS'
        WHEN check_name = 'functions' AND status = 5 THEN '✅ PASS'
        WHEN check_name = 'indexes' AND status >= 3 THEN '✅ PASS'
        ELSE '❌ FAIL'
    END as status,
    status as count
FROM migration_checks
ORDER BY check_name;

-- =====================================================
-- STEP 8: RECOMMENDATIONS
-- =====================================================

SELECT '=== RECOMMENDATIONS ===' as section;

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'users' AND column_name = 'clerk_id'
        ) THEN '⚠️  Consider removing clerk_id column after confirming migration success'
        ELSE '✅ clerk_id column already removed'
    END as recommendation

UNION ALL

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'user_favorites' AND column_name = 'user_id'
        ) THEN '⚠️  Consider removing user_id column after confirming migration success'
        ELSE '✅ user_id column already removed'
    END as recommendation

UNION ALL

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'user_personality_profiles' AND column_name = 'user_id'
        ) THEN '⚠️  Consider removing user_id column after confirming migration success'
        ELSE '✅ user_id column already removed'
    END as recommendation

UNION ALL

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_tables WHERE tablename = 'users_backup'
        ) THEN '⚠️  Consider removing backup tables after confirming migration success'
        ELSE '✅ Backup tables already removed'
    END as recommendation;
