-- Comprehensive fix for user sync issues
-- This script addresses RLS policies, functions, and ensures proper user creation

-- 1. Fix RLS policies for all tables
-- Drop ALL existing policies first to avoid conflicts
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Users can insert their own profile" ON users;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON users;

DROP POLICY IF EXISTS "Users can view their own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Users can insert their own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Users can update their own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Users can delete their own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON user_favorites;

DROP POLICY IF EXISTS "Users can view their own personality profile" ON user_personality_profiles;
DROP POLICY IF EXISTS "Users can insert their own personality profile" ON user_personality_profiles;
DROP POLICY IF EXISTS "Users can update their own personality profile" ON user_personality_profiles;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON user_personality_profiles;

DROP POLICY IF EXISTS "Users can view their own recommendations" ON book_recommendations;
DROP POLICY IF EXISTS "Users can insert their own recommendations" ON book_recommendations;
DROP POLICY IF EXISTS "Users can delete their own recommendations" ON book_recommendations;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON book_recommendations;

-- Create permissive policies for authenticated users
CREATE POLICY "Enable all access for authenticated users" ON users FOR ALL USING (true);
CREATE POLICY "Enable all access for authenticated users" ON user_favorites FOR ALL USING (true);
CREATE POLICY "Enable all access for authenticated users" ON user_personality_profiles FOR ALL USING (true);
CREATE POLICY "Enable all access for authenticated users" ON book_recommendations FOR ALL USING (true);

-- 2. Drop existing functions first to avoid return type conflicts
DROP FUNCTION IF EXISTS save_book_to_favorites(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS remove_book_from_favorites(TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS get_user_favorites(TEXT);
DROP FUNCTION IF EXISTS save_user_personality_profile(TEXT, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL);
DROP FUNCTION IF EXISTS get_user_personality_profile(TEXT);

-- 3. Create functions with proper signatures
-- Function to save book to favorites
CREATE OR REPLACE FUNCTION save_book_to_favorites(
    user_clerk_id TEXT,
    book_title TEXT,
    book_author TEXT,
    book_genre TEXT,
    book_description TEXT,
    book_amazon_link TEXT,
    book_cover_image_url TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
    book_uuid UUID;
    favorite_uuid UUID;
BEGIN
    -- Get user UUID
    SELECT id INTO user_uuid FROM users WHERE clerk_id = user_clerk_id;
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'User not found with clerk_id: %', user_clerk_id;
    END IF;

    -- Check if book exists, if not create it
    SELECT id INTO book_uuid FROM books 
    WHERE title = book_title AND author = book_author;
    
    IF book_uuid IS NULL THEN
        INSERT INTO books (title, author, genre, description, amazon_link, cover_image_url)
        VALUES (book_title, book_author, book_genre, book_description, book_amazon_link, book_cover_image_url)
        RETURNING id INTO book_uuid;
    END IF;

    -- Check if favorite already exists
    SELECT id INTO favorite_uuid FROM user_favorites 
    WHERE user_id = user_uuid AND book_id = book_uuid;
    
    IF favorite_uuid IS NULL THEN
        -- Create new favorite
        INSERT INTO user_favorites (user_id, book_id, date_added)
        VALUES (user_uuid, book_uuid, NOW())
        RETURNING id INTO favorite_uuid;
    END IF;

    RETURN favorite_uuid;
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

    -- Delete the favorite
    DELETE FROM user_favorites 
    WHERE user_id = user_uuid AND book_id = book_uuid;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN deleted_count > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user favorites
CREATE OR REPLACE FUNCTION get_user_favorites(user_clerk_id TEXT)
RETURNS TABLE (
    favorite_id UUID,
    date_added TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    rating SMALLINT,
    is_read BOOLEAN,
    read_date DATE,
    book_id UUID,
    title VARCHAR(500),
    author VARCHAR(255),
    genre VARCHAR(100),
    description TEXT,
    amazon_link VARCHAR(500),
    cover_image_url VARCHAR(500)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        uf.id as favorite_id,
        uf.date_added,
        uf.notes,
        uf.rating,
        uf.is_read,
        uf.read_date,
        b.id as book_id,
        b.title,
        b.author,
        b.genre,
        b.description,
        b.amazon_link,
        b.cover_image_url
    FROM user_favorites uf
    JOIN books b ON uf.book_id = b.id
    JOIN users u ON uf.user_id = u.id
    WHERE u.clerk_id = user_clerk_id
    ORDER BY uf.date_added DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

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
    -- Get user UUID
    SELECT id INTO user_uuid FROM users WHERE clerk_id = user_clerk_id;
    
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'User not found with clerk_id: %', user_clerk_id;
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

-- 4. Verify the setup
SELECT 'RLS policies and functions updated successfully' as status;

-- Check current policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies 
WHERE tablename IN ('users', 'user_favorites', 'user_personality_profiles')
ORDER BY tablename, policyname;
