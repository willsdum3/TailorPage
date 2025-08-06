-- Supabase Functions for Tailor Page App with Clerk Integration
-- Run this in your Supabase SQL Editor

-- Drop existing functions first
DROP FUNCTION IF EXISTS get_user_favorites(TEXT);
DROP FUNCTION IF EXISTS save_book_to_favorites(TEXT, JSONB);
DROP FUNCTION IF EXISTS remove_book_from_favorites(TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS save_user_personality_profile(TEXT, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL);
DROP FUNCTION IF EXISTS get_user_personality_profile(TEXT);
DROP FUNCTION IF EXISTS add_book_to_favorites(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);

-- Drop existing RLS policies that use auth.uid() (Supabase Auth)
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Users can insert their own profile" ON users;
DROP POLICY IF EXISTS "Users can view their own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Users can insert their own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Users can update their own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Users can delete their own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Users can view their own personality profile" ON user_personality_profiles;
DROP POLICY IF EXISTS "Users can insert their own personality profile" ON user_personality_profiles;
DROP POLICY IF EXISTS "Users can update their own personality profile" ON user_personality_profiles;
DROP POLICY IF EXISTS "Users can view their own recommendations" ON book_recommendations;
DROP POLICY IF EXISTS "Users can insert their own recommendations" ON book_recommendations;
DROP POLICY IF EXISTS "Users can delete their own recommendations" ON book_recommendations;
DROP POLICY IF EXISTS "Users can view their own reading lists" ON reading_lists;
DROP POLICY IF EXISTS "Users can view public reading lists" ON reading_lists;
DROP POLICY IF EXISTS "Users can insert their own reading lists" ON reading_lists;
DROP POLICY IF EXISTS "Users can update their own reading lists" ON reading_lists;
DROP POLICY IF EXISTS "Users can delete their own reading lists" ON reading_lists;
DROP POLICY IF EXISTS "Users can view items in their own reading lists" ON reading_list_items;
DROP POLICY IF EXISTS "Users can view items in public reading lists" ON reading_list_items;
DROP POLICY IF EXISTS "Users can insert items in their own reading lists" ON reading_list_items;
DROP POLICY IF EXISTS "Users can update items in their own reading lists" ON reading_list_items;
DROP POLICY IF EXISTS "Users can delete items in their own reading lists" ON reading_list_items;
DROP POLICY IF EXISTS "Users can view their own activity" ON user_activity_log;
DROP POLICY IF EXISTS "Users can insert their own activity" ON user_activity_log;

-- Create new RLS policies that enable all access for authenticated users
-- (We'll use service role for all operations since Clerk handles authentication)
CREATE POLICY "Enable all access for authenticated users" ON users FOR ALL USING (true);
CREATE POLICY "Enable all access for authenticated users" ON books FOR ALL USING (true);
CREATE POLICY "Enable all access for authenticated users" ON user_favorites FOR ALL USING (true);
CREATE POLICY "Enable all access for authenticated users" ON user_personality_profiles FOR ALL USING (true);
CREATE POLICY "Enable all access for authenticated users" ON book_recommendations FOR ALL USING (true);
CREATE POLICY "Enable all access for authenticated users" ON reading_lists FOR ALL USING (true);
CREATE POLICY "Enable all access for authenticated users" ON reading_list_items FOR ALL USING (true);
CREATE POLICY "Enable all access for authenticated users" ON user_activity_log FOR ALL USING (true);

-- Function to save user personality profile
CREATE OR REPLACE FUNCTION save_user_personality_profile(
    user_clerk_id TEXT,
    openness DECIMAL,
    conscientiousness DECIMAL,
    extraversion DECIMAL,
    agreeableness DECIMAL,
    emotional_stability DECIMAL,
    rational_thinking DECIMAL,
    core_values DECIMAL,
    lifestyle DECIMAL,
    social_style DECIMAL,
    self_expression DECIMAL
)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
BEGIN
    -- Get or create user
    SELECT id INTO user_uuid FROM users WHERE clerk_id = user_clerk_id;
    
    IF user_uuid IS NULL THEN
        -- Create user if doesn't exist (you'll need to pass user details)
        RETURN FALSE;
    END IF;

    -- Insert or update personality profile
    INSERT INTO user_personality_profiles (
        user_id, openness, conscientiousness, extraversion, agreeableness, 
        emotional_stability, rational_thinking, core_values, lifestyle, 
        social_style, self_expression
    ) VALUES (
        user_uuid, openness, conscientiousness, extraversion, agreeableness,
        emotional_stability, rational_thinking, core_values, lifestyle,
        social_style, self_expression
    ) ON CONFLICT (user_id) DO UPDATE SET
        openness = EXCLUDED.openness,
        conscientiousness = EXCLUDED.conscientiousness,
        extraversion = EXCLUDED.extraversion,
        agreeableness = EXCLUDED.agreeableness,
        emotional_stability = EXCLUDED.emotional_stability,
        rational_thinking = EXCLUDED.rational_thinking,
        core_values = EXCLUDED.core_values,
        lifestyle = EXCLUDED.lifestyle,
        social_style = EXCLUDED.social_style,
        self_expression = EXCLUDED.self_expression,
        updated_at = NOW();

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user personality profile
CREATE OR REPLACE FUNCTION get_user_personality_profile(user_clerk_id TEXT)
RETURNS TABLE (
    openness DECIMAL,
    conscientiousness DECIMAL,
    extraversion DECIMAL,
    agreeableness DECIMAL,
    emotional_stability DECIMAL,
    rational_thinking DECIMAL,
    core_values DECIMAL,
    lifestyle DECIMAL,
    social_style DECIMAL,
    self_expression DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        upp.openness,
        upp.conscientiousness,
        upp.extraversion,
        upp.agreeableness,
        upp.emotional_stability,
        upp.rational_thinking,
        upp.core_values,
        upp.lifestyle,
        upp.social_style,
        upp.self_expression
    FROM user_personality_profiles upp
    JOIN users u ON upp.user_id = u.id
    WHERE u.clerk_id = user_clerk_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to save book to favorites (matches the function name used in the code)
CREATE OR REPLACE FUNCTION save_book_to_favorites(
    user_clerk_id TEXT,
    book_data JSONB
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
    WHERE title = book_data->>'title' AND author = book_data->>'author';
    
    IF book_uuid IS NULL THEN
        INSERT INTO books (
            title, author, genre, description, amazon_link, cover_image_url
        ) VALUES (
            book_data->>'title',
            book_data->>'author',
            book_data->>'genre',
            book_data->>'description',
            book_data->>'amazon_link',
            book_data->>'cover_image_url'
        ) RETURNING id INTO book_uuid;
    END IF;

    -- Add to favorites
    INSERT INTO user_favorites (user_id, book_id)
    VALUES (user_uuid, book_uuid)
    ON CONFLICT (user_id, book_id) DO NOTHING
    RETURNING id INTO favorite_uuid;

    -- Log activity
    INSERT INTO user_activity_log (user_id, activity_type, book_id, metadata)
    VALUES (user_uuid, 'favorite_added', book_uuid, book_data);

    RETURN favorite_uuid IS NOT NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to remove book from favorites
CREATE OR REPLACE FUNCTION remove_book_from_favorites(
    user_clerk_id TEXT,
    book_title TEXT,
    book_author TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
    book_uuid UUID;
    deleted_count INTEGER;
BEGIN
    -- Get user UUID
    SELECT id INTO user_uuid FROM users WHERE clerk_id = user_clerk_id;
    IF user_uuid IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Get book UUID
    SELECT id INTO book_uuid FROM books 
    WHERE title = book_title AND author = book_author;
    
    IF book_uuid IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Remove from favorites
    DELETE FROM user_favorites 
    WHERE user_id = user_uuid AND book_id = book_uuid;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;

    -- Log activity if book was removed
    IF deleted_count > 0 THEN
        INSERT INTO user_activity_log (user_id, activity_type, book_id, metadata)
        VALUES (user_uuid, 'favorite_removed', book_uuid, 
                jsonb_build_object('book_title', book_title, 'book_author', book_author));
    END IF;

    RETURN deleted_count > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user favorites (matches the function name used in the code)
CREATE OR REPLACE FUNCTION get_user_favorites(user_clerk_id TEXT)
RETURNS TABLE (
    id UUID,
    title VARCHAR(500),
    author VARCHAR(255),
    genre VARCHAR(100),
    description TEXT,
    amazon_link VARCHAR(500),
    cover_image_url VARCHAR(500),
    date_added TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.id,
        b.title,
        b.author,
        b.genre,
        b.description,
        b.amazon_link,
        b.cover_image_url,
        uf.date_added
    FROM user_favorites uf
    JOIN books b ON uf.book_id = b.id
    JOIN users u ON uf.user_id = u.id
    WHERE u.clerk_id = user_clerk_id
    ORDER BY uf.date_added DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; 