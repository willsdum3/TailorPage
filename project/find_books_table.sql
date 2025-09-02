-- =====================================================
-- FIND THE ACTUAL BOOKS TABLE
-- =====================================================

-- Step 1: Check if there's a 'books' table
SELECT 'Checking for books table:' as info;

SELECT table_name FROM information_schema.tables 
WHERE table_name = 'books' 
AND table_schema = 'public';

-- Step 2: Check if there's a 'book' table (singular)
SELECT 'Checking for book table (singular):' as info;

SELECT table_name FROM information_schema.tables 
WHERE table_name = 'book' 
AND table_schema = 'public';

-- Step 3: Look for any table with 'book' in the name
SELECT 'All tables with "book" in the name:' as info;

SELECT table_name FROM information_schema.tables 
WHERE table_name LIKE '%book%' 
AND table_schema = 'public'
ORDER BY table_name;

-- Step 4: Check if there's a 'literature' or 'reading' table
SELECT 'Checking for literature/reading tables:' as info;

SELECT table_name FROM information_schema.tables 
WHERE table_name LIKE '%literature%' 
OR table_name LIKE '%reading%'
OR table_name LIKE '%novel%'
OR table_name LIKE '%fiction%'
AND table_schema = 'public'
ORDER BY table_name;

-- Step 5: Look at all tables to see what might contain books
SELECT 'All tables in public schema:' as info;

SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

SELECT '=== BOOKS TABLE SEARCH COMPLETE ===' as info;
