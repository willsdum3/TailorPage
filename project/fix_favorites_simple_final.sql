-- =====================================================
-- SIMPLE FINAL FIX FOR FAVORITES RLS ISSUE
-- =====================================================

-- This script provides a simple, robust fix for the favorites functionality
-- It handles existing policies gracefully and ensures favorites work

-- Step 1: Check current state
SELECT '=== CURRENT STATE ===' as info;

SELECT 'RLS Status:' as info, 
       CASE WHEN rowsecurity THEN 'Enabled' ELSE 'Disabled' END as status
FROM pg_tables 
WHERE tablename = 'user_favorites';

SELECT 'Current Policies:' as info, policyname, cmd
FROM pg_policies 
WHERE tablename = 'user_favorites';

-- Step 2: Drop ALL existing policies (with IF EXISTS)
SELECT '=== DROPPING EXISTING POLICIES ===' as info;
DROP POLICY IF EXISTS "Users can view own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Users can insert own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Users can delete own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Allow all operations for authenticated users" ON user_favorites;
DROP POLICY IF EXISTS "Enable all operations for authenticated users" ON user_favorites;
DROP POLICY IF EXISTS "Favorites access for authenticated users" ON user_favorites;
DROP POLICY IF EXISTS "Enable favorites for authenticated users" ON user_favorites;
DROP POLICY IF EXISTS "Comprehensive favorites policy" ON user_favorites;

-- Step 3: Ensure RLS is enabled
SELECT '=== ENSURING RLS ENABLED ===' as info;
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;

-- Step 4: Create a simple, working policy
SELECT '=== CREATING NEW POLICY ===' as info;
CREATE POLICY "Simple favorites policy v2" ON user_favorites
    FOR ALL 
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

-- Step 5: Grant permissions
SELECT '=== GRANTING PERMISSIONS ===' as info;
GRANT ALL ON user_favorites TO authenticated;
GRANT ALL ON user_favorites TO anon;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon;

-- Step 6: Verify the fix
SELECT '=== VERIFICATION ===' as info;

SELECT 'Final RLS Status:' as info, 
       CASE WHEN rowsecurity THEN 'Enabled' ELSE 'Disabled' END as status
FROM pg_tables 
WHERE tablename = 'user_favorites';

SELECT 'Final Policies:' as info, policyname, cmd
FROM pg_policies 
WHERE tablename = 'user_favorites';

-- Step 7: Test function existence
SELECT '=== FUNCTION TESTING ===' as info;
SELECT 'add_book_to_favorites function exists:' as test, 
       CASE WHEN EXISTS (
         SELECT 1 FROM pg_proc 
         WHERE proname = 'add_book_to_favorites'
       ) THEN 'YES' ELSE 'NO' END as result;

SELECT 'remove_book_from_favorites function exists:' as test,
       CASE WHEN EXISTS (
         SELECT 1 FROM pg_proc 
         WHERE proname = 'remove_book_from_favorites'
       ) THEN 'YES' ELSE 'NO' END as result;

SELECT 'get_user_favorites function exists:' as test,
       CASE WHEN EXISTS (
         SELECT 1 FROM pg_proc 
         WHERE proname = 'get_user_favorites'
       ) THEN 'YES' ELSE 'NO' END as result;

SELECT '=== FIX COMPLETE ===' as info;
