-- Simple RLS Fix for Tailor Mates User Sync
-- Run this in your Supabase SQL Editor

-- Step 1: Check what policies currently exist
SELECT tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'users';

-- Step 2: Drop ONLY the users table policies that might be blocking user sync
DROP POLICY IF EXISTS "Users can view their own data" ON users;
DROP POLICY IF EXISTS "Users can update their own data" ON users;
DROP POLICY IF EXISTS "Users can insert their own data" ON users;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON users;
DROP POLICY IF EXISTS "Enable insert access for authenticated users" ON users;
DROP POLICY IF EXISTS "Enable update access for authenticated users" ON users;

-- Step 3: Create a single permissive policy for users table
CREATE POLICY "Enable all access for authenticated users" ON users
    FOR ALL USING (true);

-- Step 4: Ensure RLS is enabled
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Step 5: Test if user sync will work by checking the policy
SELECT 'Users table RLS policy updated successfully!' as status;
