-- =====================================================
-- CHECK ACTUAL BOOK_RECOMMENDATIONS TABLE STRUCTURE
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

-- Step 3: Sample some books to see what data is available
SELECT 'Sample books from book_recommendations:' as info;

SELECT * FROM book_recommendations 
LIMIT 5;

-- Step 4: Check if there are any books with missing data
SELECT 'Books with missing data:' as info;

SELECT 
    COUNT(*) as total_books,
    COUNT(CASE WHEN title IS NULL THEN 1 END) as missing_titles,
    COUNT(CASE WHEN author IS NULL THEN 1 END) as missing_authors,
    COUNT(CASE WHEN description IS NULL THEN 1 END) as missing_descriptions
FROM book_recommendations;

SELECT '=== ACTUAL TABLE STRUCTURE ANALYSIS COMPLETE ===' as info;
