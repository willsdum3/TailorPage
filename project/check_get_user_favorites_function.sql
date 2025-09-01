-- =====================================================
-- CHECK IF get_user_favorites FUNCTION EXISTS
-- =====================================================

-- Check if the get_user_favorites function exists
SELECT 'Checking for get_user_favorites function:' as info;

SELECT proname, pronargs, proargnames
FROM pg_proc 
WHERE proname = 'get_user_favorites';

SELECT '=== FUNCTION CHECK COMPLETE ===' as info;
