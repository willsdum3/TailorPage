-- Fix the save_book_to_favorites function to match the code
DROP FUNCTION IF EXISTS save_book_to_favorites(TEXT, JSONB);

CREATE OR REPLACE FUNCTION save_book_to_favorites(
    user_clerk_id TEXT,
    book_title TEXT,
    book_author TEXT,
    book_genre TEXT,
    book_description TEXT,
    book_amazon_link TEXT,
    book_cover_image_url TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
    book_uuid UUID;
    favorite_uuid UUID;
BEGIN
    -- Get user UUID
    SELECT id INTO user_uuid FROM users WHERE clerk_id = user_clerk_id;
    IF user_uuid IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Check if book exists, if not create it
    SELECT id INTO book_uuid FROM books 
    WHERE title = book_title AND author = book_author;
    
    IF book_uuid IS NULL THEN
        INSERT INTO books (
            title, author, genre, description, amazon_link, cover_image_url
        ) VALUES (
            book_title,
            book_author,
            book_genre,
            book_description,
            book_amazon_link,
            book_cover_image_url
        ) RETURNING id INTO book_uuid;
    END IF;

    -- Add to favorites
    INSERT INTO user_favorites (user_id, book_id)
    VALUES (user_uuid, book_uuid)
    ON CONFLICT (user_id, book_id) DO NOTHING
    RETURNING id INTO favorite_uuid;

    -- Log activity
    INSERT INTO user_activity_log (user_id, activity_type, book_id, metadata)
    VALUES (user_uuid, 'favorite_added', book_uuid, 
            jsonb_build_object('book_title', book_title, 'book_author', book_author));

    RETURN favorite_uuid IS NOT NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; 