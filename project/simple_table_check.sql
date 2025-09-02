-- =====================================================
-- SIMPLE TABLE STRUCTURE CHECK
-- =====================================================

-- Step 1: Check what columns actually exist in book_recommendations table
SELECT 'book_recommendations table columns:' as info;

SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'book_recommendations' 
ORDER BY ordinal_position;

-- Step 2: Check how many books are in the table
SELECT 'Book count in book_recommendations:' as info;

SELECT COUNT(*) as total_books FROM book_recommendations;

-- Step 3: Look at the actual data (first few rows)
SELECT 'First 5 rows from book_recommendations:' as info;

SELECT * FROM book_recommendations 
LIMIT 5;

SELECT '=== SIMPLE TABLE CHECK COMPLETE ===' as info;
