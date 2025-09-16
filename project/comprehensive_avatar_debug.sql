-- =====================================================
-- COMPREHENSIVE AVATAR DEBUG AND FIX
-- =====================================================
-- This script will definitively identify and fix the avatar issue

-- Step 1: Check what's actually in the database
DO $$
DECLARE
    sample_user RECORD;
    total_users INTEGER;
    users_with_avatars INTEGER;
BEGIN
    RAISE NOTICE '=== STEP 1: DATABASE CONTENT CHECK ===';
    
    SELECT COUNT(*) INTO total_users FROM users;
    RAISE NOTICE 'Total users in database: %', total_users;
    
    SELECT COUNT(*) INTO users_with_avatars 
    FROM users 
    WHERE avatar_url IS NOT NULL 
    AND avatar_url != '' 
    AND avatar_url != 'null'
    AND LENGTH(avatar_url) > 10; -- Ensure it's a real URL
    
    RAISE NOTICE 'Users with valid avatar URLs: %', users_with_avatars;
    
    -- Show ALL users with their avatar status
    RAISE NOTICE '=== ALL USERS AND THEIR AVATARS ===';
    FOR sample_user IN 
        SELECT 
            username, 
            name, 
            avatar_url,
            LENGTH(COALESCE(avatar_url, '')) as url_length,
            auth_user_id
        FROM users 
        ORDER BY created_at DESC
        LIMIT 10
    LOOP
        RAISE NOTICE 'User: @% (%) | Avatar: % | Length: % | Auth ID: %', 
            COALESCE(sample_user.username, 'NULL'),
            COALESCE(sample_user.name, 'NULL'),
            COALESCE(sample_user.avatar_url, 'NULL'),
            sample_user.url_length,
            sample_user.auth_user_id;
    END LOOP;
END $$;

-- Step 2: Test the search function with detailed output
DO $$
DECLARE
    search_result RECORD;
    result_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== STEP 2: SEARCH FUNCTION TEST ===';
    
    -- Test with 'kat' specifically
    RAISE NOTICE 'Testing search for "kat":';
    FOR search_result IN 
        SELECT * FROM search_users_by_username('kat', 10)
    LOOP
        result_count := result_count + 1;
        RAISE NOTICE 'Result %: @% (%)', result_count, search_result.username, search_result.name;
        RAISE NOTICE '  Avatar URL: %', COALESCE(search_result.avatar_url, 'NULL');
        RAISE NOTICE '  Avatar length: %', LENGTH(COALESCE(search_result.avatar_url, ''));
        RAISE NOTICE '  ID: %', search_result.id;
    END LOOP;
    
    RAISE NOTICE 'Total "kat" results: %', result_count;
    
    -- Test with broader search
    result_count := 0;
    RAISE NOTICE 'Testing broader search for "a":';
    FOR search_result IN 
        SELECT * FROM search_users_by_username('a', 5)
    LOOP
        result_count := result_count + 1;
        RAISE NOTICE 'Result %: @% - Avatar: %', 
            result_count, 
            search_result.username, 
            CASE 
                WHEN search_result.avatar_url IS NULL THEN 'NULL'
                WHEN search_result.avatar_url = '' THEN 'EMPTY'
                WHEN LENGTH(search_result.avatar_url) < 10 THEN 'TOO_SHORT'
                ELSE 'VALID_URL'
            END;
    END LOOP;
    
    RAISE NOTICE 'Total broader search results: %', result_count;
END $$;

-- Step 3: Create a test user with a known avatar URL for testing
DO $$
BEGIN
    RAISE NOTICE '=== STEP 3: TESTING AVATAR INSERTION ===';
    
    -- Try to insert a test user with an avatar (this will help us test if the field works)
    BEGIN
        INSERT INTO users (
            auth_user_id,
            name,
            username,
            email,
            avatar_url
        ) VALUES (
            gen_random_uuid(),
            'Test Avatar User',
            'testavatar',
            'test@avatar.com',
            'https://via.placeholder.com/150/0000FF/FFFFFF?text=TEST'
        );
        
        RAISE NOTICE 'Successfully inserted test user with avatar';
        
        -- Test if we can find this user
        PERFORM * FROM search_users_by_username('testavatar', 1);
        RAISE NOTICE 'Test user found in search function';
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Could not insert test user: %', SQLERRM;
    END;
END $$;

-- Step 4: Final diagnosis
DO $$
DECLARE
    final_avatar_count INTEGER;
BEGIN
    RAISE NOTICE '=== STEP 4: FINAL DIAGNOSIS ===';
    
    SELECT COUNT(*) INTO final_avatar_count 
    FROM users 
    WHERE avatar_url IS NOT NULL 
    AND avatar_url != '' 
    AND LENGTH(avatar_url) > 10;
    
    RAISE NOTICE 'Users with valid avatars after test: %', final_avatar_count;
    
    IF final_avatar_count = 0 THEN
        RAISE NOTICE '🚨 ISSUE IDENTIFIED: No users have valid avatar URLs';
        RAISE NOTICE 'This means either:';
        RAISE NOTICE '1. Users have not uploaded profile pictures';
        RAISE NOTICE '2. The avatar sync process is still not working';
        RAISE NOTICE '3. The auth provider does not provide avatar URLs';
    ELSE
        RAISE NOTICE '✅ Some users have avatars - search function should work';
        RAISE NOTICE 'If avatars still do not display, the issue is in the frontend';
    END IF;
END $$;

-- Clean up test user
DELETE FROM users WHERE username = 'testavatar' AND email = 'test@avatar.com';
