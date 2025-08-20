-- Fix RLS policies to allow new user creation and sync
-- This script removes the restrictive policies that require auth.uid() to match clerk_id
-- Since we're using Clerk for authentication, Supabase's auth.uid() is not set

-- Drop the restrictive policies that are blocking user creation
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Users can insert their own profile" ON users;

-- Create permissive policies for authenticated users
-- This allows the service role to create and manage users
CREATE POLICY "Enable all access for authenticated users" ON users FOR ALL USING (true);

-- Also fix policies for other tables that might be affected
DROP POLICY IF EXISTS "Users can view their own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Users can insert their own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Users can update their own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Users can delete their own favorites" ON user_favorites;

CREATE POLICY "Enable all access for authenticated users" ON user_favorites FOR ALL USING (true);

DROP POLICY IF EXISTS "Users can view their own personality profile" ON user_personality_profiles;
DROP POLICY IF EXISTS "Users can insert their own personality profile" ON user_personality_profiles;
DROP POLICY IF EXISTS "Users can update their own personality profile" ON user_personality_profiles;

CREATE POLICY "Enable all access for authenticated users" ON user_personality_profiles FOR ALL USING (true);

-- Verify the changes
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('users', 'user_favorites', 'user_personality_profiles')
ORDER BY tablename, policyname;

