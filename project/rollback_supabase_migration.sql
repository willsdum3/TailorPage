-- =====================================================
-- ROLLBACK SCRIPT: Supabase Auth to Clerk
-- =====================================================
-- This script reverts the database from Supabase Auth back to Clerk authentication
-- WARNING: This will remove all Supabase Auth changes and restore Clerk functionality
-- Run this script in your Supabase SQL editor

-- =====================================================
-- STEP 1: RESTORE FROM BACKUP (If available)
-- =====================================================

-- If you have backup tables, restore from them
-- Uncomment these lines if you want to restore from backup:

/*
DROP TABLE IF EXISTS users;
CREATE TABLE users AS SELECT * FROM users_backup;

DROP TABLE IF EXISTS user_favorites;
CREATE TABLE user_favorites AS SELECT * FROM user_favorites_backup;

DROP TABLE IF EXISTS user_personality_profiles;
CREATE TABLE user_personality_profiles AS SELECT * FROM user_personality_profiles_backup;
*/

-- =====================================================
-- STEP 2: RESTORE ORIGINAL SCHEMA
-- =====================================================

-- Add back clerk_id column if it was removed
ALTER TABLE users ADD COLUMN IF NOT EXISTS clerk_id TEXT;

-- Remove auth_user_id column
ALTER TABLE users DROP COLUMN IF EXISTS auth_user_id;

-- Remove unique constraint on auth_user_id (handle if it doesn't exist)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'users_auth_user_id_unique'
    ) THEN
        ALTER TABLE users DROP CONSTRAINT users_auth_user_id_unique;
    END IF;
END $$;

-- Remove index on auth_user_id
DROP INDEX IF EXISTS idx_users_auth_user_id;

-- =====================================================
-- STEP 3: RESTORE USER_FAVORITES TABLE
-- =====================================================

-- Add back user_id column if it was removed
ALTER TABLE user_favorites ADD COLUMN IF NOT EXISTS user_id TEXT;

-- Remove auth_user_id column
ALTER TABLE user_favorites DROP COLUMN IF EXISTS auth_user_id;

-- Remove index on auth_user_id
DROP INDEX IF EXISTS idx_user_favorites_auth_user_id;

-- =====================================================
-- STEP 4: RESTORE USER_PERSONALITY_PROFILES TABLE
-- =====================================================

-- Add back user_id column if it was removed
ALTER TABLE user_personality_profiles ADD COLUMN IF NOT EXISTS user_id TEXT;

-- Remove auth_user_id column
ALTER TABLE user_personality_profiles DROP COLUMN IF EXISTS auth_user_id;

-- Remove index on auth_user_id
DROP INDEX IF EXISTS idx_user_personality_profiles_auth_user_id;

-- =====================================================
-- STEP 5: RESTORE ORIGINAL RLS POLICIES
-- =====================================================

-- Drop Supabase Auth policies
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;

DROP POLICY IF EXISTS "Users can view own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Users can insert own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Users can update own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Users can delete own favorites" ON user_favorites;

DROP POLICY IF EXISTS "Users can view own personality profile" ON user_personality_profiles;
DROP POLICY IF EXISTS "Users can insert own personality profile" ON user_personality_profiles;
DROP POLICY IF EXISTS "Users can update own personality profile" ON user_personality_profiles;
DROP POLICY IF EXISTS "Users can delete own personality profile" ON user_personality_profiles;

-- Restore original permissive policies (if you had them)
CREATE POLICY "Enable all access for authenticated users" ON users
    FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Enable all access for authenticated users" ON user_favorites
    FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Enable all access for authenticated users" ON user_personality_profiles
    FOR ALL USING (true) WITH CHECK (true);

-- =====================================================
-- STEP 6: RESTORE ORIGINAL STORED PROCEDURES
-- =====================================================

-- Drop Supabase Auth functions
DROP FUNCTION IF EXISTS get_user_favorites(user_auth_id UUID);
DROP FUNCTION IF EXISTS save_book_to_favorites(user_auth_id UUID, book_title TEXT, book_author TEXT, book_genre TEXT, book_description TEXT, book_amazon_link TEXT, book_cover_image_url TEXT);
DROP FUNCTION IF EXISTS remove_book_from_favorites(user_auth_id UUID, book_title TEXT, book_author TEXT);
DROP FUNCTION IF EXISTS get_user_personality_profile(user_auth_id UUID);
DROP FUNCTION IF EXISTS save_user_personality_profile(user_auth_id UUID, openness_val INTEGER, conscientiousness_val INTEGER, extraversion_val INTEGER, agreeableness_val INTEGER, emotional_stability_val INTEGER, rational_thinking_val INTEGER, core_values_val INTEGER, lifestyle_val INTEGER, social_style_val INTEGER, self_expression_val INTEGER);

-- Restore original functions with clerk_id parameter
CREATE OR REPLACE FUNCTION get_user_favorites(user_clerk_id TEXT)
RETURNS TABLE (
    id UUID,
    book_id UUID,
    title TEXT,
    author TEXT,
    genre TEXT,
    description TEXT,
    amazon_link TEXT,
    cover_image_url TEXT,
    date_added TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    rating INTEGER,
    is_read BOOLEAN,
    read_date TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        uf.id,
        uf.book_id,
        b.title,
        b.author,
        b.genre,
        b.description,
        b.amazon_link,
        b.cover_image_url,
        uf.date_added,
        uf.notes,
        uf.rating,
        uf.is_read,
        uf.read_date
    FROM user_favorites uf
    LEFT JOIN books b ON uf.book_id = b.id
    LEFT JOIN users u ON uf.user_id = u.clerk_id
    WHERE u.clerk_id = user_clerk_id
    ORDER BY uf.date_added DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

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
    book_uuid UUID;
    favorite_uuid UUID;
BEGIN
    -- First, try to find existing book
    SELECT id INTO book_uuid
    FROM books
    WHERE LOWER(title) = LOWER(book_title) AND LOWER(author) = LOWER(book_author)
    LIMIT 1;
    
    -- If book doesn't exist, create it
    IF book_uuid IS NULL THEN
        INSERT INTO books (title, author, genre, description, amazon_link, cover_image_url, language)
        VALUES (book_title, book_author, book_genre, book_description, book_amazon_link, book_cover_image_url, 'English')
        RETURNING id INTO book_uuid;
    END IF;
    
    -- Check if user already has this book in favorites
    SELECT id INTO favorite_uuid
    FROM user_favorites
    WHERE user_id = user_clerk_id AND book_id = book_uuid;
    
    -- If not in favorites, add it
    IF favorite_uuid IS NULL THEN
        INSERT INTO user_favorites (user_id, book_id, date_added)
        VALUES (user_clerk_id, book_uuid, NOW())
        RETURNING id INTO favorite_uuid;
    END IF;
    
    RETURN favorite_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION remove_book_from_favorites(
    user_clerk_id TEXT,
    book_title TEXT,
    book_author TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    book_uuid UUID;
    deleted_count INTEGER;
BEGIN
    -- Find the book
    SELECT id INTO book_uuid
    FROM books
    WHERE LOWER(title) = LOWER(book_title) AND LOWER(author) = LOWER(book_author)
    LIMIT 1;
    
    -- If book found, remove from favorites
    IF book_uuid IS NOT NULL THEN
        DELETE FROM user_favorites
        WHERE user_id = user_clerk_id AND book_id = book_uuid;
        
        GET DIAGNOSTICS deleted_count = ROW_COUNT;
        RETURN deleted_count > 0;
    END IF;
    
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_user_personality_profile(user_clerk_id TEXT)
RETURNS TABLE (
    id UUID,
    openness INTEGER,
    conscientiousness INTEGER,
    extraversion INTEGER,
    agreeableness INTEGER,
    emotional_stability INTEGER,
    rational_thinking INTEGER,
    core_values INTEGER,
    lifestyle INTEGER,
    social_style INTEGER,
    self_expression INTEGER,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        upp.id,
        upp.openness,
        upp.conscientiousness,
        upp.extraversion,
        upp.agreeableness,
        upp.emotional_stability,
        upp.rational_thinking,
        upp.core_values,
        upp.lifestyle,
        upp.social_style,
        upp.self_expression,
        upp.created_at,
        upp.updated_at
    FROM user_personality_profiles upp
    WHERE upp.user_id = user_clerk_id
    ORDER BY upp.updated_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION save_user_personality_profile(
    user_clerk_id TEXT,
    openness_val INTEGER,
    conscientiousness_val INTEGER,
    extraversion_val INTEGER,
    agreeableness_val INTEGER,
    emotional_stability_val INTEGER,
    rational_thinking_val INTEGER,
    core_values_val INTEGER,
    lifestyle_val INTEGER,
    social_style_val INTEGER,
    self_expression_val INTEGER
)
RETURNS UUID AS $$
DECLARE
    profile_uuid UUID;
BEGIN
    -- Check if profile exists
    SELECT id INTO profile_uuid
    FROM user_personality_profiles
    WHERE user_id = user_clerk_id;
    
    IF profile_uuid IS NOT NULL THEN
        -- Update existing profile
        UPDATE user_personality_profiles
        SET 
            openness = openness_val,
            conscientiousness = conscientiousness_val,
            extraversion = extraversion_val,
            agreeableness = agreeableness_val,
            emotional_stability = emotional_stability_val,
            rational_thinking = rational_thinking_val,
            core_values = core_values_val,
            lifestyle = lifestyle_val,
            social_style = social_style_val,
            self_expression = self_expression_val,
            updated_at = NOW()
        WHERE id = profile_uuid;
    ELSE
        -- Create new profile
        INSERT INTO user_personality_profiles (
            user_id,
            openness,
            conscientiousness,
            extraversion,
            agreeableness,
            emotional_stability,
            rational_thinking,
            core_values,
            lifestyle,
            social_style,
            self_expression
        )
        VALUES (
            user_clerk_id,
            openness_val,
            conscientiousness_val,
            extraversion_val,
            agreeableness_val,
            emotional_stability_val,
            rational_thinking_val,
            core_values_val,
            lifestyle_val,
            social_style_val,
            self_expression_val
        )
        RETURNING id INTO profile_uuid;
    END IF;
    
    RETURN profile_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 7: VERIFICATION
-- =====================================================

-- Verify the rollback was successful
SELECT 'Rollback completed successfully!' as status;

-- Check table structures
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name IN ('users', 'user_favorites', 'user_personality_profiles')
AND (column_name LIKE '%clerk_id%' OR column_name LIKE '%user_id%')
ORDER BY table_name, column_name;

-- Check RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename IN ('users', 'user_favorites', 'user_personality_profiles')
ORDER BY tablename, policyname;

-- Check functions
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name LIKE '%favorites%' OR routine_name LIKE '%personality%'
ORDER BY routine_name;
