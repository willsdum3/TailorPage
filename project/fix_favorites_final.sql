-- =====================================================
-- FINAL FIX FOR FAVORITES FUNCTIONS
-- =====================================================

-- This script completely recreates the favorites functions with the correct parameter names

-- Step 1: Drop ALL existing functions
DROP FUNCTION IF EXISTS add_book_to_favorites(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS add_book_to_favorites(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS remove_book_from_favorites(UUID, TEXT, TEXT);

-- Step 2: Create add_book_to_favorites function with original parameter names
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
    
    -- Add book to favorites
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
        book_title, 
        book_author, 
        book_genre, 
        book_description,
        book_amazon_link, 
        book_cover_image_url, 
        reason
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

-- Step 3: Create remove_book_from_favorites function with original parameter names
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
    -- Get user
    SELECT id INTO user_uuid
    FROM users
    WHERE auth_user_id = remove_book_from_favorites.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Remove book from favorites
    DELETE FROM user_favorites
    WHERE user_id = user_uuid 
    AND LOWER(book_title) = LOWER(remove_book_from_favorites.book_title)
    AND LOWER(book_author) = LOWER(remove_book_from_favorites.book_author);
    
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

SELECT '=== FAVORITES FUNCTIONS COMPLETELY RECREATED ===' as info;
