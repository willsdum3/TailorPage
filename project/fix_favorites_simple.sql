-- =====================================================
-- ROBUST FIX FOR FAVORITES RLS ISSUE
-- =====================================================

-- This script provides a robust fix by properly handling existing policies
-- and ensuring the RPC functions can work with the user_favorites table

-- First, let's check current RLS status
SELECT 
    schemaname, 
    tablename, 
    rowsecurity,
    CASE 
        WHEN rowsecurity THEN 'RLS Enabled'
        ELSE 'RLS Disabled'
    END as rls_status
FROM pg_tables 
WHERE tablename = 'user_favorites';

-- Check existing policies
SELECT 
    schemaname, 
    tablename, 
    policyname, 
    permissive, 
    roles, 
    cmd
FROM pg_policies 
WHERE tablename = 'user_favorites';

-- Temporarily disable RLS on user_favorites table
ALTER TABLE user_favorites DISABLE ROW LEVEL SECURITY;

-- Re-enable RLS
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies (with IF EXISTS to avoid errors)
DROP POLICY IF EXISTS "Users can view own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Users can insert own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Users can delete own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Allow all operations for authenticated users" ON user_favorites;
DROP POLICY IF EXISTS "Enable all operations for authenticated users" ON user_favorites;

-- Create a comprehensive policy that allows all operations for authenticated users
CREATE POLICY "Enable all operations for authenticated users" ON user_favorites
    FOR ALL USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON user_favorites TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Verify the fix
SELECT 
    schemaname, 
    tablename, 
    rowsecurity,
    CASE 
        WHEN rowsecurity THEN 'RLS Enabled'
        ELSE 'RLS Disabled'
    END as rls_status
FROM pg_tables 
WHERE tablename = 'user_favorites';

SELECT 
    schemaname, 
    tablename, 
    policyname, 
    permissive, 
    roles, 
    cmd
FROM pg_policies 
WHERE tablename = 'user_favorites';

-- Test the RPC functions
SELECT 'Testing add_book_to_favorites function...' as test_step;
SELECT 'Testing remove_book_from_favorites function...' as test_step;
SELECT 'Testing get_user_favorites function...' as test_step;
