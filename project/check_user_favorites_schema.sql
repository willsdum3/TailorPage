-- =====================================================
-- CHECK USER_FAVORITES TABLE SCHEMA
-- =====================================================

-- Check the structure of user_favorites table
SELECT 'user_favorites table columns:' as info;

SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_favorites' 
ORDER BY ordinal_position;

SELECT '=== SCHEMA CHECK COMPLETE ===' as info;
