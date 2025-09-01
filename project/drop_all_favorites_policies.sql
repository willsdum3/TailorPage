-- =====================================================
-- DROP ALL FAVORITES POLICIES
-- =====================================================

-- This script will drop ALL existing policies on user_favorites table

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

-- Show remaining policies
SELECT '=== REMAINING POLICIES ===' as info;
SELECT policyname, cmd
FROM pg_policies 
WHERE tablename = 'user_favorites';

SELECT '=== DROP COMPLETE ===' as info;
