-- =====================================================
-- CREATE get_user_favorites FUNCTION
-- =====================================================

-- This function retrieves all favorites for a specific user

-- Step 1: Create the get_user_favorites function
CREATE OR REPLACE FUNCTION get_user_favorites(
    auth_user_id UUID
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    book_title TEXT,
    book_author TEXT,
    book_genre TEXT,
    book_description TEXT,
    book_amazon_link TEXT,
    book_cover_image_url TEXT,
    reason TEXT,
    date_added TIMESTAMPTZ
) AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Get the user's internal ID
    SELECT id INTO v_user_id
    FROM users
    WHERE auth_user_id = get_user_favorites.auth_user_id;
    
    IF v_user_id IS NULL THEN
        -- Return empty result if user not found
        RETURN;
    END IF;
    
    -- Return all favorites for this user
    RETURN QUERY
    SELECT 
        uf.id,
        uf.user_id,
        uf.book_title,
        uf.book_author,
        uf.book_genre,
        uf.book_description,
        uf.book_amazon_link,
        uf.book_cover_image_url,
        uf.reason,
        uf.date_added
    FROM user_favorites uf
    WHERE uf.user_id = v_user_id
    ORDER BY uf.date_added DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 2: Grant execute permissions
GRANT EXECUTE ON FUNCTION get_user_favorites(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_favorites(UUID) TO anon;

-- Step 3: Verify function exists
SELECT 'get_user_favorites function created:' as info;

SELECT proname, pronargs, proargnames
FROM pg_proc 
WHERE proname = 'get_user_favorites';

SELECT '=== get_user_favorites FUNCTION CREATED ===' as info;
