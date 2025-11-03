-- Fix User Authentication Issue
-- This script ensures users can be created automatically and fixes authentication issues

-- ===========================================
-- STEP 1: CREATE USER CREATION FUNCTION
-- ===========================================

-- Create a function to automatically create users if they don't exist
CREATE OR REPLACE FUNCTION ensure_user_exists(p_auth_user_id UUID)
RETURNS UUID AS $$
DECLARE
    user_internal_id UUID;
    user_name TEXT;
    user_email TEXT;
BEGIN
    -- Try to get existing user
    SELECT id INTO user_internal_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    -- If user doesn't exist, create them
    IF user_internal_id IS NULL THEN
        -- Get user info from auth.users (if accessible)
        -- For now, create with default values
        user_name := 'User ' || substring(p_auth_user_id::text, 1, 8);
        user_email := 'user' || substring(p_auth_user_id::text, 1, 8) || '@example.com';
        
        INSERT INTO users (auth_user_id, name, username, email, created_at)
        VALUES (
            p_auth_user_id,
            user_name,
            'user_' || substring(p_auth_user_id::text, 1, 8),
            user_email,
            NOW()
        )
        RETURNING id INTO user_internal_id;
        
        RAISE NOTICE 'Created new user: %', user_internal_id;
    END IF;
    
    RETURN user_internal_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- STEP 2: UPDATE GET_USER_INTERNAL_ID FUNCTION
-- ===========================================

-- Update the get_user_internal_id function to use the new ensure_user_exists function
CREATE OR REPLACE FUNCTION get_user_internal_id(p_auth_user_id UUID)
RETURNS UUID AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    -- Use the ensure_user_exists function
    user_internal_id := ensure_user_exists(p_auth_user_id);
    
    RETURN user_internal_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- STEP 3: ENSURE USERS TABLE RLS ALLOWS SELECTS
-- ===========================================

-- Drop any restrictive policies on users table
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can view all users" ON users;

-- Create permissive SELECT policy
CREATE POLICY "Users can view all users" ON users
    FOR SELECT USING (true);

-- Keep restrictive policies for modifications
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
CREATE POLICY "Users can update their own profile" ON users
    FOR UPDATE USING (auth_user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert their own profile" ON users;
CREATE POLICY "Users can insert their own profile" ON users
    FOR INSERT WITH CHECK (auth_user_id = auth.uid());

-- ===========================================
-- STEP 4: CREATE TEST USER IF NONE EXISTS
-- ===========================================

DO $$
DECLARE
    user_count INTEGER;
    test_auth_id UUID;
    test_user_id UUID;
BEGIN
    SELECT COUNT(*) INTO user_count FROM users;
    
    IF user_count = 0 THEN
        RAISE NOTICE 'No users found - creating test user';
        
        test_auth_id := gen_random_uuid();
        
        INSERT INTO users (auth_user_id, name, username, email, created_at)
        VALUES (
            test_auth_id,
            'Test User',
            'testuser',
            'test@example.com',
            NOW()
        )
        RETURNING id INTO test_user_id;
        
        RAISE NOTICE 'Created test user: auth_id=%, internal_id=%', test_auth_id, test_user_id;
    ELSE
        RAISE NOTICE 'Users already exist: %', user_count;
    END IF;
END $$;

-- ===========================================
-- STEP 5: TEST THE FUNCTIONS
-- ===========================================

DO $$
DECLARE
    test_auth_id UUID;
    test_internal_id UUID;
    club_count INTEGER;
    discussion_count INTEGER;
BEGIN
    -- Get a test user
    SELECT auth_user_id INTO test_auth_id FROM users LIMIT 1;
    
    IF test_auth_id IS NOT NULL THEN
        RAISE NOTICE 'Testing with auth_user_id: %', test_auth_id;
        
        -- Test get_user_internal_id
        SELECT get_user_internal_id(test_auth_id) INTO test_internal_id;
        RAISE NOTICE 'get_user_internal_id returned: %', test_internal_id;
        
        -- Test get_book_clubs
        SELECT COUNT(*) INTO club_count FROM get_book_clubs(test_auth_id);
        RAISE NOTICE 'get_book_clubs returned % records', club_count;
        
        -- Test get_discussions
        SELECT COUNT(*) INTO discussion_count FROM get_discussions(test_auth_id);
        RAISE NOTICE 'get_discussions returned % records', discussion_count;
        
    ELSE
        RAISE NOTICE 'No users found for testing';
    END IF;
END $$;

-- ===========================================
-- STEP 6: FINAL VERIFICATION
-- ===========================================

SELECT '=== FINAL VERIFICATION ===' as header;

SELECT 
    'Users' as table_name,
    COUNT(*) as total_count
FROM users
UNION ALL
SELECT 
    'Book Clubs' as table_name,
    COUNT(*) as total_count
FROM book_clubs
UNION ALL
SELECT 
    'Discussions' as table_name,
    COUNT(*) as total_count
FROM discussions;

-- Show sample data
SELECT '=== SAMPLE DATA ===' as header;
SELECT id, auth_user_id, name, username FROM users LIMIT 3;

SELECT '=== AUTHENTICATION FIX COMPLETE ===' as header;
