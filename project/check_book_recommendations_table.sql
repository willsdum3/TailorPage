-- =====================================================
-- CHECK BOOK_RECOMMENDATIONS TABLE STRUCTURE
-- =====================================================

-- Step 1: Check the structure of book_recommendations table
SELECT 'book_recommendations table columns:' as info;

SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'book_recommendations' 
ORDER BY ordinal_position;

-- Step 2: Check how many books are in the table
SELECT 'Book count in book_recommendations:' as info;

SELECT COUNT(*) as total_books FROM book_recommendations;

-- Step 3: Check what genres are available
SELECT 'Available genres:' as info;

SELECT DISTINCT genre, COUNT(*) as count
FROM book_recommendations 
WHERE genre IS NOT NULL 
GROUP BY genre 
ORDER BY count DESC;

-- Step 4: Sample some books to see the data quality
SELECT 'Sample books from book_recommendations:' as info;

SELECT id, title, author, genre, description
FROM book_recommendations 
WHERE title IS NOT NULL 
AND author IS NOT NULL 
LIMIT 10;

-- Step 5: Check if there are any books with missing data
SELECT 'Books with missing data:' as info;

SELECT 
    COUNT(*) as total_books,
    COUNT(CASE WHEN title IS NULL THEN 1 END) as missing_titles,
    COUNT(CASE WHEN author IS NULL THEN 1 END) as missing_authors,
    COUNT(CASE WHEN genre IS NULL THEN 1 END) as missing_genres,
    COUNT(CASE WHEN description IS NULL THEN 1 END) as missing_descriptions
FROM book_recommendations;

SELECT '=== BOOK_RECOMMENDATIONS ANALYSIS COMPLETE ===' as info;
