-- =====================================================
-- FIX ADD_BOOK_TO_FAVORITES FUNCTION
-- =====================================================

-- This script fixes the ambiguous column reference error in add_book_to_favorites

-- Drop the existing function
DROP FUNCTION IF EXISTS add_book_to_favorites(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);

-- Create the fixed function
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
        user_id, book_title, book_author, book_genre, book_description, 
        book_amazon_link, book_cover_image_url, reason
    )
    VALUES (
        user_uuid, book_title, book_author, book_genre, book_description,
        book_amazon_link, book_cover_image_url, reason
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

-- Grant execute permission
GRANT EXECUTE ON FUNCTION add_book_to_favorites TO authenticated;
GRANT EXECUTE ON FUNCTION add_book_to_favorites TO anon;

SELECT '=== ADD_BOOK_TO_FAVORITES FUNCTION FIXED ===' as info;
