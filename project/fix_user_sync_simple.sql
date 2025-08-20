-- Simple fix for user sync issues - Run this step by step
-- This script fixes RLS policies without conflicts

-- Step 1: Drop restrictive policies for users table
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Users can insert their own profile" ON users;

-- Step 2: Create permissive policy for users table
CREATE POLICY "Enable all access for authenticated users" ON users FOR ALL USING (true);

-- Step 3: Drop restrictive policies for user_favorites table
DROP POLICY IF EXISTS "Users can view their own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Users can insert their own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Users can update their own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Users can delete their own favorites" ON user_favorites;

-- Step 4: Create permissive policy for user_favorites table
CREATE POLICY "Enable all access for authenticated users" ON user_favorites FOR ALL USING (true);

-- Step 5: Drop restrictive policies for user_personality_profiles table
DROP POLICY IF EXISTS "Users can view their own personality profile" ON user_personality_profiles;
DROP POLICY IF EXISTS "Users can insert their own personality profile" ON user_personality_profiles;
DROP POLICY IF EXISTS "Users can update their own personality profile" ON user_personality_profiles;

-- Step 6: Create permissive policy for user_personality_profiles table
CREATE POLICY "Enable all access for authenticated users" ON user_personality_profiles FOR ALL USING (true);

-- Step 7: Drop restrictive policies for book_recommendations table
DROP POLICY IF EXISTS "Users can view their own recommendations" ON book_recommendations;
DROP POLICY IF EXISTS "Users can insert their own recommendations" ON book_recommendations;
DROP POLICY IF EXISTS "Users can delete their own recommendations" ON book_recommendations;

-- Step 8: Create permissive policy for book_recommendations table
CREATE POLICY "Enable all access for authenticated users" ON book_recommendations FOR ALL USING (true);

-- Step 9: Verify the changes
SELECT 'RLS policies updated successfully' as status;

-- Step 10: Check current policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies 
WHERE tablename IN ('users', 'user_favorites', 'user_personality_profiles', 'book_recommendations')
ORDER BY tablename, policyname;
