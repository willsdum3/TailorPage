-- =====================================================
-- ULTRA SIMPLE FIX FOR FAVORITES FUNCTIONS
-- =====================================================

-- This script creates completely new functions with different names to avoid any conflicts

-- Step 1: Drop ALL existing functions with explicit signatures
DROP FUNCTION IF EXISTS add_book_to_favorites(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS add_book_to_favorites(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS remove_book_from_favorites(UUID, TEXT, TEXT) CASCADE;

-- Step 2: Create add_book_to_favorites function with completely unambiguous code
CREATE OR REPLACE FUNCTION add_book_to_favorites(
    auth_user_id UUID,
    book_title TEXT,
    book_author TEXT,
    book_genre TEXT DEFAULT NULL,
    book_description TEXT DEFAULT NULL,
    book_amazon_link TEXT DEFAULT NULL,
    book_cover_image_url TEXT DEFAULT NULL,
    reason TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
    favorite_uuid UUID;
BEGIN
    -- Get or create user
    SELECT get_or_create_user(
        auth_user_id,
        'User',
        'user@example.com'
    ) INTO user_uuid;
    
    -- Add book to favorites - use completely unambiguous column references
    INSERT INTO user_favorites (
        user_id, 
        book_title, 
        book_author, 
        book_genre, 
        book_description, 
        book_amazon_link, 
        book_cover_image_url, 
        reason
    )
    VALUES (
        user_uuid, 
        $2,  -- book_title parameter
        $3,  -- book_author parameter
        $4,  -- book_genre parameter
        $5,  -- book_description parameter
        $6,  -- book_amazon_link parameter
        $7,  -- book_cover_image_url parameter
        $8   -- reason parameter
    )
    ON CONFLICT (user_id, book_title, book_author)
    DO UPDATE SET
        book_genre = EXCLUDED.book_genre,
        book_description = EXCLUDED.book_description,
        book_amazon_link = EXCLUDED.book_amazon_link,
        book_cover_image_url = EXCLUDED.book_cover_image_url,
        reason = EXCLUDED.reason,
        updated_at = NOW()
    RETURNING id INTO favorite_uuid;
    
    RETURN favorite_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Create remove_book_from_favorites function with unambiguous code
CREATE OR REPLACE FUNCTION remove_book_from_favorites(
    auth_user_id UUID,
    book_title TEXT,
    book_author TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
    deleted_count INTEGER;
BEGIN
    -- Get user using parameter position
    SELECT id INTO user_uuid
    FROM users
    WHERE users.auth_user_id = $1;  -- auth_user_id parameter
    
    IF user_uuid IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Remove book from favorites using parameter positions
    DELETE FROM user_favorites
    WHERE user_favorites.user_id = user_uuid 
    AND LOWER(user_favorites.book_title) = LOWER($2)  -- book_title parameter
    AND LOWER(user_favorites.book_author) = LOWER($3); -- book_author parameter
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 4: Grant execute permissions with explicit function signatures
GRANT EXECUTE ON FUNCTION add_book_to_favorites(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION add_book_to_favorites(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION remove_book_from_favorites(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION remove_book_from_favorites(UUID, TEXT, TEXT) TO anon;

-- Step 5: Verify functions exist
SELECT 'Function verification:' as info;
SELECT proname, pronargs 
FROM pg_proc 
WHERE proname IN ('add_book_to_favorites', 'remove_book_from_favorites');

SELECT '=== FAVORITES FUNCTIONS COMPLETELY RECREATED WITH PARAMETER POSITIONS ===' as info;
