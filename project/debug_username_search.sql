-- =====================================================
-- DEBUG USERNAME SEARCH ISSUE
-- =====================================================
-- This script helps debug why no usernames are found

-- First, let's check what's actually in the users table
SELECT 
    'Total users in table:' as info,
    COUNT(*) as count
FROM users;

SELECT 
    'Users with usernames:' as info,
    COUNT(*) as count
FROM users 
WHERE username IS NOT NULL AND username != '';

SELECT 
    'Sample usernames:' as info,
    username,
    name,
    auth_user_id
FROM users 
WHERE username IS NOT NULL AND username != ''
LIMIT 10;

-- Test the search function directly
SELECT 'Testing search function:' as info;

-- Test with a broad search
SELECT * FROM search_users_by_username('a', 10);

-- Let's also create an improved search function that's more flexible
CREATE OR REPLACE FUNCTION search_users_by_username(
    p_search_term TEXT, 
    p_limit_count INTEGER DEFAULT 10
)
RETURNS TABLE (
    id UUID,
    username TEXT,
    name TEXT,
    avatar_url TEXT
) AS $$
BEGIN
    -- Debug: Log what we're searching for
    RAISE NOTICE 'Searching for username containing: %', p_search_term;
    
    -- First, let's see what users exist
    RAISE NOTICE 'Total users with usernames: %', (
        SELECT COUNT(*) FROM users 
        WHERE username IS NOT NULL AND username != ''
    );
    
    RETURN QUERY
    SELECT 
        u.id,
        u.username,
        u.name,
        u.avatar_url
    FROM users u
    WHERE 
        u.username IS NOT NULL
        AND u.username != ''
        AND (
            u.username ILIKE '%' || p_search_term || '%'
            OR u.name ILIKE '%' || p_search_term || '%'
        )
    ORDER BY 
        CASE 
            WHEN u.username ILIKE p_search_term THEN 1  -- Exact match first
            WHEN u.username ILIKE p_search_term || '%' THEN 2  -- Starts with
            WHEN u.name ILIKE p_search_term || '%' THEN 3  -- Name starts with
            ELSE 4  -- Contains
        END,
        u.username
    LIMIT p_limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION search_users_by_username TO authenticated;

-- Test the improved function
SELECT 'Testing improved search:' as info;
SELECT * FROM search_users_by_username('', 5); -- Get any 5 users

DO $$
BEGIN
    RAISE NOTICE '✅ Username search debugging complete';
    RAISE NOTICE 'Check the results above to see what users exist';
    RAISE NOTICE 'The improved search function now also searches by name';
END $$;
