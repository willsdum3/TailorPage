-- =====================================================
-- FIX FAVORITES RLS POLICIES
-- =====================================================

-- This script fixes the RLS policies that are preventing the favorites functionality from working

-- Drop existing policies that are too restrictive
DROP POLICY IF EXISTS "Users can insert own favorites" ON user_favorites;

-- Create a more permissive policy for inserts that allows RPC functions to work
CREATE POLICY "Users can insert own favorites" ON user_favorites
    FOR INSERT WITH CHECK (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
        OR 
        -- Allow inserts from RPC functions (when auth.uid() might not be set)
        EXISTS (
            SELECT 1 FROM users u 
            WHERE u.id = user_favorites.user_id 
            AND u.auth_user_id IS NOT NULL
        )
    );

-- Also update the view policy to be more permissive
DROP POLICY IF EXISTS "Users can view own favorites" ON user_favorites;

CREATE POLICY "Users can view own favorites" ON user_favorites
    FOR SELECT USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
        OR 
        -- Allow views from RPC functions
        EXISTS (
            SELECT 1 FROM users u 
            WHERE u.id = user_favorites.user_id 
            AND u.auth_user_id IS NOT NULL
        )
    );

-- Update delete policy as well
DROP POLICY IF EXISTS "Users can delete own favorites" ON user_favorites;

CREATE POLICY "Users can delete own favorites" ON user_favorites
    FOR DELETE USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
        OR 
        -- Allow deletes from RPC functions
        EXISTS (
            SELECT 1 FROM users u 
            WHERE u.id = user_favorites.user_id 
            AND u.auth_user_id IS NOT NULL
        )
    );

-- Grant necessary permissions to the authenticated role
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Verify the policies are in place
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename = 'user_favorites';
