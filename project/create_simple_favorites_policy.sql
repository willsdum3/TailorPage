-- =====================================================
-- CREATE SIMPLE FAVORITES POLICY
-- =====================================================

-- This script creates a simple policy for favorites

-- Step 1: Ensure RLS is enabled
SELECT '=== ENSURING RLS ENABLED ===' as info;
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;

-- Step 2: Create a new, simple policy with unique name
SELECT '=== CREATING NEW POLICY ===' as info;
CREATE POLICY "Favorites policy 2024" ON user_favorites
    FOR ALL 
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

-- Step 3: Grant permissions
SELECT '=== GRANTING PERMISSIONS ===' as info;
GRANT ALL ON user_favorites TO authenticated;
GRANT ALL ON user_favorites TO anon;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon;

-- Step 4: Verify the fix
SELECT '=== VERIFICATION ===' as info;

SELECT 'Final RLS Status:' as info, 
       CASE WHEN rowsecurity THEN 'Enabled' ELSE 'Disabled' END as status
FROM pg_tables 
WHERE tablename = 'user_favorites';

SELECT 'Final Policies:' as info, policyname, cmd
FROM pg_policies 
WHERE tablename = 'user_favorites';

SELECT '=== POLICY CREATION COMPLETE ===' as info;
