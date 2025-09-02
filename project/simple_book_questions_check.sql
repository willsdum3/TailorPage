-- =====================================================
-- SIMPLE BOOK_QUESTIONS TABLE CHECK
-- =====================================================

-- Step 1: Check what columns actually exist in book_questions table
SELECT 'book_questions table columns:' as info;

SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'book_questions' 
ORDER BY ordinal_position;

-- Step 2: Check how many records are in book_questions
SELECT 'Record count in book_questions:' as info;

SELECT COUNT(*) as total_records FROM book_questions;

-- Step 3: Look at the actual data (first few rows)
SELECT 'First 5 rows from book_questions:' as info;

SELECT * FROM book_questions 
LIMIT 5;

SELECT '=== SIMPLE BOOK_QUESTIONS CHECK COMPLETE ===' as info;
