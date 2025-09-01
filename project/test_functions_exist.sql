-- =====================================================
-- TEST IF FUNCTIONS EXIST
-- =====================================================

-- Check if the new functions exist
SELECT 'Checking for new functions:' as info;

SELECT proname, pronargs, proargnames
FROM pg_proc 
WHERE proname IN ('add_book_to_user_favorites', 'remove_book_from_user_favorites');

-- Check if old functions still exist
SELECT 'Checking for old functions:' as info;

SELECT proname, pronargs, proargnames
FROM pg_proc 
WHERE proname IN ('add_book_to_favorites', 'remove_book_from_favorites');

SELECT '=== FUNCTION CHECK COMPLETE ===' as info;
