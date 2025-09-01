-- =====================================================
-- FINAL CLEAN FIX FOR FAVORITES RLS ISSUE
-- =====================================================

-- This script provides a clean, robust fix for the favorites functionality
-- It will work regardless of existing policies

-- Step 1: Drop ALL existing policies on user_favorites table
SELECT '=== DROPPING ALL EXISTING POLICIES ===' as info;

DO $$ 
DECLARE
    policy_record RECORD;
BEGIN
    -- Get all policies on user_favorites table
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'user_favorites'
    LOOP
        -- Drop each policy
        EXECUTE format('DROP POLICY IF EXISTS %I ON user_favorites', policy_record.policyname);
        RAISE NOTICE 'Dropped policy: %', policy_record.policyname;
    END LOOP;
END $$;

-- Step 2: Ensure RLS is enabled
SELECT '=== ENSURING RLS ENABLED ===' as info;
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;

-- Step 3: Create a new, simple policy
SELECT '=== CREATING NEW POLICY ===' as info;
CREATE POLICY "Favorites access policy" ON user_favorites
    FOR ALL 
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

-- Step 4: Grant permissions
SELECT '=== GRANTING PERMISSIONS ===' as info;
GRANT ALL ON user_favorites TO authenticated;
GRANT ALL ON user_favorites TO anon;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon;

-- Step 5: Verify the fix
SELECT '=== VERIFICATION ===' as info;

SELECT 'Final RLS Status:' as info, 
       CASE WHEN rowsecurity THEN 'Enabled' ELSE 'Disabled' END as status
FROM pg_tables 
WHERE tablename = 'user_favorites';

SELECT 'Final Policies:' as info, policyname, cmd
FROM pg_policies 
WHERE tablename = 'user_favorites';

-- Step 6: Test function existence
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
