-- =====================================================
-- FIX USER SEARCH TO RETURN PROPER AVATARS
-- =====================================================
-- This script ensures the search_users_by_username function returns proper avatar URLs

-- First, let's check what avatar fields exist in the users table
DO $$
DECLARE
    sample_user RECORD;
    user_count INTEGER;
BEGIN
    RAISE NOTICE '=== CHECKING USER AVATAR FIELDS ===';
    
    -- Count users with avatars
    SELECT COUNT(*) INTO user_count 
    FROM users 
    WHERE avatar_url IS NOT NULL AND avatar_url != '';
    RAISE NOTICE 'Users with avatar_url: %', user_count;
    
    -- Show sample user data
    FOR sample_user IN 
        SELECT username, name, avatar_url
        FROM users 
        WHERE username IS NOT NULL AND username != ''
        LIMIT 3
    LOOP
        RAISE NOTICE 'Sample user: @% (%) - Avatar: %', 
            sample_user.username, 
            sample_user.name, 
            COALESCE(sample_user.avatar_url, 'NULL');
    END LOOP;
END $$;

-- Recreate the search function with better avatar handling
DROP FUNCTION IF EXISTS search_users_by_username(TEXT, INTEGER);

CREATE OR REPLACE FUNCTION search_users_by_username(
    search_term TEXT, 
    limit_count INTEGER DEFAULT 10
)
RETURNS TABLE (
    id UUID,
    username TEXT,
    name TEXT,
    avatar_url TEXT
) AS $$
BEGIN
    RAISE NOTICE 'Searching for: %, limit: %', search_term, limit_count;
    
    RETURN QUERY
    SELECT 
        u.id,
        u.username,
        u.name,
        -- Make sure we return the avatar_url field properly
        u.avatar_url
    FROM users u
    WHERE 
        u.username IS NOT NULL
        AND u.username != ''
        AND (
            u.username ILIKE '%' || search_term || '%'
            OR u.name ILIKE '%' || search_term || '%'
        )
    ORDER BY 
        CASE 
            WHEN u.username ILIKE search_term THEN 1  -- Exact match first
            WHEN u.username ILIKE search_term || '%' THEN 2  -- Starts with
            WHEN u.name ILIKE search_term || '%' THEN 3  -- Name starts with
            ELSE 4  -- Contains
        END,
        u.username
    LIMIT limit_count;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in search_users_by_username: %', SQLERRM;
        RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION search_users_by_username TO authenticated;

-- Test the function and show results with avatar info
DO $$
DECLARE
    test_user RECORD;
    result_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== TESTING SEARCH FUNCTION ===';
    
    -- Test with a common search term
    FOR test_user IN 
        SELECT * FROM search_users_by_username('a', 5)
    LOOP
        result_count := result_count + 1;
        RAISE NOTICE 'Search result: @% (%) - Avatar: %', 
            test_user.username, 
            test_user.name, 
            COALESCE(test_user.avatar_url, 'NULL');
    END LOOP;
    
    RAISE NOTICE 'Search returned % users', result_count;
    
    IF result_count = 0 THEN
        RAISE NOTICE 'WARNING: No users returned by search function';
    END IF;
END $$;

-- Final status
DO $$
BEGIN
    RAISE NOTICE '=== AVATAR SEARCH FIX COMPLETE ===';
    RAISE NOTICE '✅ Updated search_users_by_username function';
    RAISE NOTICE '✅ Added avatar field verification';
    RAISE NOTICE '✅ Added comprehensive logging';
    RAISE NOTICE 'Check the NOTICE messages above to see if avatars are being returned';
END $$;
