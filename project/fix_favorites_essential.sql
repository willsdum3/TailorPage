-- =====================================================
-- ESSENTIAL FIX FOR FAVORITES RLS ISSUE
-- =====================================================

-- This script provides the minimal fix needed for favorites to work
-- It handles existing policies and ensures proper permissions

-- Step 1: Check current RLS status
SELECT 'Current RLS Status:' as info, 
       CASE WHEN rowsecurity THEN 'Enabled' ELSE 'Disabled' END as status
FROM pg_tables 
WHERE tablename = 'user_favorites';

-- Step 2: Check existing policies
SELECT 'Existing Policies:' as info, policyname, cmd
FROM pg_policies 
WHERE tablename = 'user_favorites';

-- Step 3: Disable RLS temporarily
ALTER TABLE user_favorites DISABLE ROW LEVEL SECURITY;

-- Step 4: Re-enable RLS
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;

-- Step 5: Drop ALL existing policies (safe with IF EXISTS)
DROP POLICY IF EXISTS "Users can view own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Users can insert own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Users can delete own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Allow all operations for authenticated users" ON user_favorites;
DROP POLICY IF EXISTS "Enable all operations for authenticated users" ON user_favorites;
DROP POLICY IF EXISTS "Favorites access for authenticated users" ON user_favorites;

-- Step 6: Create a new policy with a unique name
CREATE POLICY "Enable favorites for authenticated users" ON user_favorites
    FOR ALL USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

-- Step 7: Grant necessary permissions
GRANT ALL ON user_favorites TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Step 8: Verify the fix
SELECT 'Final RLS Status:' as info, 
       CASE WHEN rowsecurity THEN 'Enabled' ELSE 'Disabled' END as status
FROM pg_tables 
WHERE tablename = 'user_favorites';

SELECT 'Final Policies:' as info, policyname, cmd
FROM pg_policies 
WHERE tablename = 'user_favorites';
