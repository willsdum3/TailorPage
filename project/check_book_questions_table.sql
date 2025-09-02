-- =====================================================
-- CHECK BOOK_QUESTIONS TABLE FOR BOOK DATA
-- =====================================================

-- Step 1: Check the structure of book_questions table
SELECT 'book_questions table columns:' as info;

SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'book_questions' 
ORDER BY ordinal_position;

-- Step 2: Check how many records are in book_questions
SELECT 'Record count in book_questions:' as info;

SELECT COUNT(*) as total_records FROM book_questions;

-- Step 3: Look at sample data from book_questions
SELECT 'Sample data from book_questions:' as info;

SELECT * FROM book_questions 
LIMIT 5;

-- Step 4: Check if there are any books with missing data
SELECT 'Data quality check for book_questions:' as info;

SELECT 
    COUNT(*) as total_records,
    COUNT(CASE WHEN title IS NULL THEN 1 END) as missing_titles,
    COUNT(CASE WHEN author IS NULL THEN 1 END) as missing_authors,
    COUNT(CASE WHEN genre IS NULL THEN 1 END) as missing_genres,
    COUNT(CASE WHEN description IS NULL THEN 1 END) as missing_descriptions
FROM book_questions;

SELECT '=== BOOK_QUESTIONS ANALYSIS COMPLETE ===' as info;
