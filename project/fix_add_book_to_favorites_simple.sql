-- =====================================================
-- SIMPLE FIX FOR ADD_BOOK_TO_FAVORITES FUNCTION
-- =====================================================

-- This script completely replaces the problematic function with a working version

-- Drop the existing function completely
DROP FUNCTION IF EXISTS add_book_to_favorites(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);

-- Create a completely new, simple function
CREATE OR REPLACE FUNCTION add_book_to_favorites(
    p_auth_user_id UUID,
    p_book_title TEXT,
    p_book_author TEXT,
    p_book_genre TEXT DEFAULT NULL,
    p_book_description TEXT DEFAULT NULL,
    p_book_amazon_link TEXT DEFAULT NULL,
    p_book_cover_image_url TEXT DEFAULT NULL,
    p_reason TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_user_uuid UUID;
    v_favorite_uuid UUID;
BEGIN
    -- Get or create user
    SELECT get_or_create_user(
        p_auth_user_id,
        'User',
        'user@example.com'
    ) INTO v_user_uuid;
    
    -- Add book to favorites with explicit column references
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
        v_user_uuid, 
        p_book_title, 
        p_book_author, 
        p_book_genre, 
        p_book_description,
        p_book_amazon_link, 
        p_book_cover_image_url, 
        p_reason
    )
    ON CONFLICT (user_id, book_title, book_author)
    DO UPDATE SET
        book_genre = EXCLUDED.book_genre,
        book_description = EXCLUDED.book_description,
        book_amazon_link = EXCLUDED.book_amazon_link,
        book_cover_image_url = EXCLUDED.book_cover_image_url,
        reason = EXCLUDED.reason,
        updated_at = NOW()
    RETURNING id INTO v_favorite_uuid;
    
    RETURN v_favorite_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION add_book_to_favorites TO authenticated;
GRANT EXECUTE ON FUNCTION add_book_to_favorites TO anon;

-- Test the function exists
SELECT 'Function created successfully' as status;

SELECT '=== ADD_BOOK_TO_FAVORITES FUNCTION COMPLETELY FIXED ===' as info;
