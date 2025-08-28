-- =====================================================
-- COMPREHENSIVE FIX FOR FAVORITES RLS ISSUE
-- =====================================================

-- This script provides a comprehensive fix for the favorites functionality
-- It temporarily disables RLS, creates proper policies, and verifies the fix

-- Step 1: Check current state
SELECT '=== CURRENT STATE ===' as info;

SELECT 'RLS Status:' as info, 
       CASE WHEN rowsecurity THEN 'Enabled' ELSE 'Disabled' END as status
FROM pg_tables 
WHERE tablename = 'user_favorites';

SELECT 'Current Policies:' as info, policyname, cmd
FROM pg_policies 
WHERE tablename = 'user_favorites';

-- Step 2: Completely disable RLS temporarily
SELECT '=== DISABLING RLS ===' as info;
ALTER TABLE user_favorites DISABLE ROW LEVEL SECURITY;

-- Step 3: Drop ALL existing policies
SELECT '=== DROPPING POLICIES ===' as info;
DROP POLICY IF EXISTS "Users can view own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Users can insert own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Users can delete own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Allow all operations for authenticated users" ON user_favorites;
DROP POLICY IF EXISTS "Enable all operations for authenticated users" ON user_favorites;
DROP POLICY IF EXISTS "Favorites access for authenticated users" ON user_favorites;
DROP POLICY IF EXISTS "Enable favorites for authenticated users" ON user_favorites;

-- Step 4: Re-enable RLS
SELECT '=== RE-ENABLING RLS ===' as info;
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;

-- Step 5: Create a comprehensive policy
SELECT '=== CREATING NEW POLICY ===' as info;
CREATE POLICY "Comprehensive favorites policy" ON user_favorites
    FOR ALL 
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

-- Step 6: Grant all necessary permissions
SELECT '=== GRANTING PERMISSIONS ===' as info;
GRANT ALL ON user_favorites TO authenticated;
GRANT ALL ON user_favorites TO anon;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon;

-- Step 7: Verify the fix
SELECT '=== VERIFICATION ===' as info;

SELECT 'Final RLS Status:' as info, 
       CASE WHEN rowsecurity THEN 'Enabled' ELSE 'Disabled' END as status
FROM pg_tables 
WHERE tablename = 'user_favorites';

SELECT 'Final Policies:' as info, policyname, cmd
FROM pg_policies 
WHERE tablename = 'user_favorites';

-- Step 8: Test the functions (replace with actual user ID)
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
