-- Check Existing Profile Tables
-- This script identifies what profile-related tables already exist in your database

SELECT '=== EXISTING PROFILE TABLES ===' as header;

-- Check for all tables that might contain user profile data
SELECT 
    table_name,
    table_type,
    CASE 
        WHEN table_name LIKE '%profile%' THEN 'PROFILE'
        WHEN table_name LIKE '%favorite%' THEN 'FAVORITES'
        WHEN table_name LIKE '%quiz%' THEN 'QUIZ'
        WHEN table_name LIKE '%personality%' THEN 'PERSONALITY'
        WHEN table_name LIKE '%preference%' THEN 'PREFERENCES'
        WHEN table_name LIKE '%score%' THEN 'SCORES'
        WHEN table_name LIKE '%result%' THEN 'RESULTS'
        ELSE 'OTHER'
    END as category
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND (
    table_name LIKE '%profile%' OR
    table_name LIKE '%favorite%' OR
    table_name LIKE '%quiz%' OR
    table_name LIKE '%personality%' OR
    table_name LIKE '%preference%' OR
    table_name LIKE '%score%' OR
    table_name LIKE '%result%' OR
    table_name LIKE '%user%'
)
ORDER BY category, table_name;

-- Check for any existing data in potential profile tables
SELECT '=== EXISTING PROFILE DATA ===' as header;

-- Check if any tables have data
DO $$
DECLARE
    table_name TEXT;
    record_count INTEGER;
BEGIN
    FOR table_name IN 
        SELECT t.table_name 
        FROM information_schema.tables t
        WHERE t.table_schema = 'public' 
        AND (
            t.table_name LIKE '%profile%' OR
            t.table_name LIKE '%favorite%' OR
            t.table_name LIKE '%quiz%' OR
            t.table_name LIKE '%personality%' OR
            t.table_name LIKE '%preference%' OR
            t.table_name LIKE '%score%' OR
            t.table_name LIKE '%result%'
        )
    LOOP
        BEGIN
            EXECUTE 'SELECT COUNT(*) FROM ' || table_name INTO record_count;
            RAISE NOTICE 'Table %: % records', table_name, record_count;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Table %: Error checking data - %', table_name, SQLERRM;
        END;
    END LOOP;
END $$;

-- Check for any existing user-related data
SELECT '=== USER DATA SUMMARY ===' as header;
SELECT 
    'users' as table_name,
    COUNT(*) as total_users,
    COUNT(CASE WHEN created_at > NOW() - INTERVAL '1 day' THEN 1 END) as recent_users
FROM users;

-- Check for any existing book club data
SELECT 
    'book_clubs' as table_name,
    COUNT(*) as total_clubs
FROM book_clubs;

-- Check for any existing discussion data
SELECT 
    'discussions' as table_name,
    COUNT(*) as total_discussions
FROM discussions;

SELECT '=== PROFILE TABLE CHECK COMPLETE ===' as header;
