-- =====================================================
-- MIGRATION SCRIPT: Clerk to Supabase Auth
-- =====================================================
-- This script migrates the database from Clerk authentication to Supabase Auth
-- Run this script in your Supabase SQL editor

-- =====================================================
-- STEP 1: BACKUP EXISTING DATA (Optional but Recommended)
-- =====================================================

-- Create backup tables before making changes
CREATE TABLE IF NOT EXISTS users_backup AS SELECT * FROM users;
CREATE TABLE IF NOT EXISTS user_favorites_backup AS SELECT * FROM user_favorites;
CREATE TABLE IF NOT EXISTS user_personality_profiles_backup AS SELECT * FROM user_personality_profiles;

-- =====================================================
-- STEP 2: UPDATE USERS TABLE SCHEMA
-- =====================================================

-- Add the new auth_user_id column
ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_user_id UUID;

-- Create a unique constraint on auth_user_id (handle if it already exists)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'users_auth_user_id_unique'
    ) THEN
        ALTER TABLE users ADD CONSTRAINT users_auth_user_id_unique UNIQUE (auth_user_id);
    END IF;
END $$;

-- Create an index on auth_user_id for better performance
CREATE INDEX IF NOT EXISTS idx_users_auth_user_id ON users(auth_user_id);

-- =====================================================
-- STEP 3: UPDATE RLS POLICIES FOR USERS TABLE
-- =====================================================

-- Drop existing RLS policies
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON users;
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;

-- Enable RLS on users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create new RLS policies for Supabase Auth
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = auth_user_id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = auth_user_id);

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = auth_user_id);

-- =====================================================
-- STEP 4: UPDATE USER_FAVORITES TABLE
-- =====================================================

-- Add auth_user_id column to user_favorites
ALTER TABLE user_favorites ADD COLUMN IF NOT EXISTS auth_user_id UUID;

-- Create index on auth_user_id
CREATE INDEX IF NOT EXISTS idx_user_favorites_auth_user_id ON user_favorites(auth_user_id);

-- Update RLS policies for user_favorites
DROP POLICY IF EXISTS "Users can view own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Users can insert own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Users can update own favorites" ON user_favorites;
DROP POLICY IF EXISTS "Users can delete own favorites" ON user_favorites;

-- Enable RLS on user_favorites table
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;

-- Create new RLS policies
CREATE POLICY "Users can view own favorites" ON user_favorites
    FOR SELECT USING (auth.uid() = auth_user_id);

CREATE POLICY "Users can insert own favorites" ON user_favorites
    FOR INSERT WITH CHECK (auth.uid() = auth_user_id);

CREATE POLICY "Users can update own favorites" ON user_favorites
    FOR UPDATE USING (auth.uid() = auth_user_id);

CREATE POLICY "Users can delete own favorites" ON user_favorites
    FOR DELETE USING (auth.uid() = auth_user_id);

-- =====================================================
-- STEP 5: UPDATE USER_PERSONALITY_PROFILES TABLE
-- =====================================================

-- Add auth_user_id column to user_personality_profiles
ALTER TABLE user_personality_profiles ADD COLUMN IF NOT EXISTS auth_user_id UUID;

-- Create index on auth_user_id
CREATE INDEX IF NOT EXISTS idx_user_personality_profiles_auth_user_id ON user_personality_profiles(auth_user_id);

-- Update RLS policies for user_personality_profiles
DROP POLICY IF EXISTS "Users can view own personality profile" ON user_personality_profiles;
DROP POLICY IF EXISTS "Users can insert own personality profile" ON user_personality_profiles;
DROP POLICY IF EXISTS "Users can update own personality profile" ON user_personality_profiles;
DROP POLICY IF EXISTS "Users can delete own personality profile" ON user_personality_profiles;

-- Enable RLS on user_personality_profiles table
ALTER TABLE user_personality_profiles ENABLE ROW LEVEL SECURITY;

-- Create new RLS policies
CREATE POLICY "Users can view own personality profile" ON user_personality_profiles
    FOR SELECT USING (auth.uid() = auth_user_id);

CREATE POLICY "Users can insert own personality profile" ON user_personality_profiles
    FOR INSERT WITH CHECK (auth.uid() = auth_user_id);

CREATE POLICY "Users can update own personality profile" ON user_personality_profiles
    FOR UPDATE USING (auth.uid() = auth_user_id);

CREATE POLICY "Users can delete own personality profile" ON user_personality_profiles
    FOR DELETE USING (auth.uid() = auth_user_id);

-- =====================================================
-- STEP 6: UPDATE STORED PROCEDURES
-- =====================================================

-- Drop existing functions
DROP FUNCTION IF EXISTS get_user_favorites(user_clerk_id UUID);
DROP FUNCTION IF EXISTS save_book_to_favorites(user_clerk_id UUID, book_title TEXT, book_author TEXT, book_genre TEXT, book_description TEXT, book_amazon_link TEXT, book_cover_image_url TEXT);
DROP FUNCTION IF EXISTS remove_book_from_favorites(user_clerk_id UUID, book_title TEXT, book_author TEXT);
DROP FUNCTION IF EXISTS get_user_personality_profile(user_clerk_id UUID);
DROP FUNCTION IF EXISTS save_user_personality_profile(user_clerk_id UUID, openness_val INTEGER, conscientiousness_val INTEGER, extraversion_val INTEGER, agreeableness_val INTEGER, emotional_stability_val INTEGER, rational_thinking_val INTEGER, core_values_val INTEGER, lifestyle_val INTEGER, social_style_val INTEGER, self_expression_val INTEGER);

-- Create new functions with auth_user_id parameter
CREATE OR REPLACE FUNCTION get_user_favorites(user_auth_id UUID)
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
    WHERE uf.auth_user_id = user_auth_id
    ORDER BY uf.date_added DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION save_book_to_favorites(
    user_auth_id UUID,
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
    WHERE auth_user_id = user_auth_id AND book_id = book_uuid;
    
    -- If not in favorites, add it
    IF favorite_uuid IS NULL THEN
        INSERT INTO user_favorites (auth_user_id, book_id, date_added)
        VALUES (user_auth_id, book_uuid, NOW())
        RETURNING id INTO favorite_uuid;
    END IF;
    
    RETURN favorite_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION remove_book_from_favorites(
    user_auth_id UUID,
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
        WHERE auth_user_id = user_auth_id AND book_id = book_uuid;
        
        GET DIAGNOSTICS deleted_count = ROW_COUNT;
        RETURN deleted_count > 0;
    END IF;
    
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_user_personality_profile(user_auth_id UUID)
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
    WHERE upp.auth_user_id = user_auth_id
    ORDER BY upp.updated_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION save_user_personality_profile(
    user_auth_id UUID,
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
    WHERE auth_user_id = user_auth_id;
    
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
            auth_user_id,
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
            user_auth_id,
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
-- STEP 7: DATA MIGRATION (If you have existing Clerk users)
-- =====================================================

-- Note: This section is for migrating existing Clerk users to Supabase Auth
-- You'll need to manually map Clerk user IDs to Supabase Auth user IDs
-- This is typically done during the user's first login with Supabase Auth

-- Example migration query (uncomment and modify as needed):
/*
UPDATE users 
SET auth_user_id = 'supabase-auth-user-id-here'
WHERE clerk_id = 'clerk-user-id-here';
*/

-- =====================================================
-- STEP 8: CLEANUP (Optional - Remove old columns after migration)
-- =====================================================

-- After confirming the migration is successful, you can remove old columns
-- Uncomment these lines when you're ready to clean up:

-- ALTER TABLE users DROP COLUMN IF EXISTS clerk_id;
-- ALTER TABLE user_favorites DROP COLUMN IF EXISTS user_id;
-- ALTER TABLE user_personality_profiles DROP COLUMN IF EXISTS user_id;

-- =====================================================
-- STEP 9: VERIFICATION QUERIES
-- =====================================================

-- Verify the migration was successful
SELECT 'Migration completed successfully!' as status;

-- Check table structures
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name IN ('users', 'user_favorites', 'user_personality_profiles')
AND column_name LIKE '%auth_user_id%'
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
