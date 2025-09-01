-- =====================================================
-- CREATE COMPLETELY NEW FAVORITES FUNCTIONS
-- =====================================================

-- This script creates brand new functions with different names to avoid all conflicts

-- Step 1: Create new add_book_to_favorites function with a different name
CREATE OR REPLACE FUNCTION add_book_to_user_favorites(
    user_auth_id UUID,
    title TEXT,
    author TEXT,
    genre TEXT DEFAULT NULL,
    description TEXT DEFAULT NULL,
    amazon_link TEXT DEFAULT NULL,
    cover_image_url TEXT DEFAULT NULL,
    reason_text TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
    favorite_uuid UUID;
BEGIN
    -- Get or create user
    SELECT get_or_create_user(
        user_auth_id,
        'User',
        'user@example.com'
    ) INTO user_uuid;
    
    -- Add book to favorites - no ambiguity possible
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
        title, 
        author, 
        genre, 
        description,
        amazon_link, 
        cover_image_url, 
        reason_text
    )
         ON CONFLICT (user_id, book_title, book_author)
     DO UPDATE SET
         book_genre = EXCLUDED.book_genre,
         book_description = EXCLUDED.book_description,
         book_amazon_link = EXCLUDED.book_amazon_link,
         book_cover_image_url = EXCLUDED.book_cover_image_url,
         reason = EXCLUDED.reason
    RETURNING id INTO favorite_uuid;
    
    RETURN favorite_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 2: Create new remove_book_from_favorites function with a different name
CREATE OR REPLACE FUNCTION remove_book_from_user_favorites(
    user_auth_id UUID,
    title TEXT,
    author TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
    deleted_count INTEGER;
BEGIN
    -- Get user
    SELECT id INTO user_uuid
    FROM users
    WHERE auth_user_id = user_auth_id;
    
    IF user_uuid IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Remove book from favorites
    DELETE FROM user_favorites
    WHERE user_id = user_uuid 
    AND LOWER(book_title) = LOWER(title)
    AND LOWER(book_author) = LOWER(author);
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Grant execute permissions
GRANT EXECUTE ON FUNCTION add_book_to_user_favorites TO authenticated;
GRANT EXECUTE ON FUNCTION add_book_to_user_favorites TO anon;
GRANT EXECUTE ON FUNCTION remove_book_from_user_favorites TO authenticated;
GRANT EXECUTE ON FUNCTION remove_book_from_user_favorites TO anon;

-- Step 4: Verify functions exist
SELECT 'New functions created:' as info;
SELECT proname, pronargs 
FROM pg_proc 
WHERE proname IN ('add_book_to_user_favorites', 'remove_book_from_user_favorites');

SELECT '=== NEW FAVORITES FUNCTIONS CREATED ===' as info;
