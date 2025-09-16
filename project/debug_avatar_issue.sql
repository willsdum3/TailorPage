-- =====================================================
-- COMPREHENSIVE AVATAR DEBUG
-- =====================================================
-- This script will help us understand exactly what's happening with avatars

-- Check the users table structure
DO $$
BEGIN
    RAISE NOTICE '=== USERS TABLE STRUCTURE ===';
END $$;

SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'public'
AND column_name ILIKE '%avatar%' OR column_name ILIKE '%image%' OR column_name ILIKE '%photo%'
ORDER BY ordinal_position;

-- Show all avatar-related fields in users table
SELECT 
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check actual user data with all possible avatar fields
DO $$
DECLARE
    sample_user RECORD;
    user_count INTEGER;
BEGIN
    RAISE NOTICE '=== SAMPLE USER DATA ===';
    
    -- Get total user count
    SELECT COUNT(*) INTO user_count FROM users;
    RAISE NOTICE 'Total users: %', user_count;
    
    -- Show sample users with all their data
    FOR sample_user IN 
        SELECT 
            id,
            username, 
            name, 
            email,
            avatar_url,
            created_at
        FROM users 
        WHERE username IS NOT NULL 
        LIMIT 5
    LOOP
        RAISE NOTICE 'User: @% (%) - Avatar: %', 
            sample_user.username, 
            sample_user.name, 
            COALESCE(sample_user.avatar_url, 'NULL');
    END LOOP;
END $$;

-- Test the search function directly and show detailed results
DO $$
DECLARE
    search_result RECORD;
    result_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== TESTING SEARCH FUNCTION DIRECTLY ===';
    
    -- Test with 'kat' since that was in your screenshot
    FOR search_result IN 
        SELECT * FROM search_users_by_username('kat', 10)
    LOOP
        result_count := result_count + 1;
        RAISE NOTICE 'Result %: ID=%, Username=@%, Name=%, Avatar=%', 
            result_count,
            search_result.id,
            search_result.username, 
            search_result.name, 
            COALESCE(search_result.avatar_url, 'NULL');
    END LOOP;
    
    RAISE NOTICE 'Total search results: %', result_count;
    
    -- Also test with a broader search
    result_count := 0;
    RAISE NOTICE '=== TESTING BROADER SEARCH ===';
    FOR search_result IN 
        SELECT * FROM search_users_by_username('a', 5)
    LOOP
        result_count := result_count + 1;
        RAISE NOTICE 'Result %: Username=@%, Avatar=%', 
            result_count,
            search_result.username, 
            COALESCE(search_result.avatar_url, 'NULL');
    END LOOP;
    
    RAISE NOTICE 'Broader search results: %', result_count;
END $$;

-- Check if there are any users with actual avatar URLs
DO $$
DECLARE
    avatar_count INTEGER;
    sample_avatar RECORD;
BEGIN
    RAISE NOTICE '=== CHECKING FOR ACTUAL AVATARS ===';
    
    SELECT COUNT(*) INTO avatar_count 
    FROM users 
    WHERE avatar_url IS NOT NULL 
    AND avatar_url != '' 
    AND avatar_url != 'null';
    
    RAISE NOTICE 'Users with non-empty avatar_url: %', avatar_count;
    
    IF avatar_count > 0 THEN
        FOR sample_avatar IN 
            SELECT username, avatar_url 
            FROM users 
            WHERE avatar_url IS NOT NULL 
            AND avatar_url != '' 
            AND avatar_url != 'null'
            LIMIT 3
        LOOP
            RAISE NOTICE 'User with avatar: @% - %', sample_avatar.username, sample_avatar.avatar_url;
        END LOOP;
    ELSE
        RAISE NOTICE 'NO USERS HAVE AVATAR URLs - This is likely the issue!';
    END IF;
END $$;

-- Final diagnosis
DO $$
BEGIN
    RAISE NOTICE '=== DIAGNOSIS COMPLETE ===';
    RAISE NOTICE 'Check the messages above to see:';
    RAISE NOTICE '1. What avatar fields exist in the users table';
    RAISE NOTICE '2. Sample user data with avatar information';
    RAISE NOTICE '3. Search function results with avatar data';
    RAISE NOTICE '4. Whether any users actually have avatar URLs';
END $$;
