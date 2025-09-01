-- =====================================================
-- SIMPLE FIX FOR FAVORITES FUNCTIONS
-- =====================================================

-- This script fixes the ambiguous column issues while keeping original parameter names

-- Fix add_book_to_favorites function
DROP FUNCTION IF EXISTS add_book_to_favorites(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);

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
    
    -- Add book to favorites - use explicit table references to avoid ambiguity
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
        add_book_to_favorites.book_title, 
        add_book_to_favorites.book_author, 
        add_book_to_favorites.book_genre, 
        add_book_to_favorites.book_description,
        add_book_to_favorites.book_amazon_link, 
        add_book_to_favorites.book_cover_image_url, 
        add_book_to_favorites.reason
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

-- Fix remove_book_from_favorites function
DROP FUNCTION IF EXISTS remove_book_from_favorites(UUID, TEXT, TEXT);

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
    WHERE users.auth_user_id = remove_book_from_favorites.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Remove book from favorites - use explicit table references
    DELETE FROM user_favorites
    WHERE user_favorites.user_id = user_uuid 
    AND LOWER(user_favorites.book_title) = LOWER(remove_book_from_favorites.book_title)
    AND LOWER(user_favorites.book_author) = LOWER(remove_book_from_favorites.book_author);
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION add_book_to_favorites TO authenticated;
GRANT EXECUTE ON FUNCTION add_book_to_favorites TO anon;
GRANT EXECUTE ON FUNCTION remove_book_from_favorites TO authenticated;
GRANT EXECUTE ON FUNCTION remove_book_from_favorites TO anon;

SELECT '=== FAVORITES FUNCTIONS FIXED ===' as info;
