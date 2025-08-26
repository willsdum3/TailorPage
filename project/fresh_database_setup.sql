-- =====================================================
-- FRESH DATABASE SETUP FOR TAILOR PAGE APP
-- =====================================================
-- This script creates a clean database structure for Supabase Auth
-- Run this in your Supabase SQL editor to start fresh

-- =====================================================
-- STEP 1: DROP EXISTING TABLES (if they exist)
-- =====================================================

DROP TABLE IF EXISTS user_favorites CASCADE;
DROP TABLE IF EXISTS user_personality_profiles CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS books CASCADE;

-- =====================================================
-- STEP 2: CREATE USERS TABLE
-- =====================================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_user_id UUID UNIQUE NOT NULL,
    name TEXT NOT NULL,
    username TEXT UNIQUE,
    email TEXT UNIQUE NOT NULL,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- STEP 3: CREATE PERSONALITY PROFILES TABLE
-- =====================================================

CREATE TABLE user_personality_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    openness INTEGER NOT NULL CHECK (openness >= 1 AND openness <= 25),
    conscientiousness INTEGER NOT NULL CHECK (conscientiousness >= 1 AND conscientiousness <= 25),
    extraversion INTEGER NOT NULL CHECK (extraversion >= 1 AND extraversion <= 25),
    agreeableness INTEGER NOT NULL CHECK (agreeableness >= 1 AND agreeableness <= 25),
    emotional_stability INTEGER NOT NULL CHECK (emotional_stability >= 1 AND emotional_stability <= 25),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- =====================================================
-- STEP 4: CREATE FAVORITES TABLE
-- =====================================================

CREATE TABLE user_favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    book_title TEXT NOT NULL,
    book_author TEXT NOT NULL,
    book_genre TEXT,
    book_description TEXT,
    book_amazon_link TEXT,
    book_cover_image_url TEXT,
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, book_title, book_author)
);

-- =====================================================
-- STEP 5: CREATE INDEXES FOR PERFORMANCE
-- =====================================================

CREATE INDEX idx_users_auth_user_id ON users(auth_user_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);

CREATE INDEX idx_personality_profiles_user_id ON user_personality_profiles(user_id);
CREATE INDEX idx_personality_profiles_created_at ON user_personality_profiles(created_at);

CREATE INDEX idx_favorites_user_id ON user_favorites(user_id);
CREATE INDEX idx_favorites_created_at ON user_favorites(created_at);
CREATE INDEX idx_favorites_book_title_author ON user_favorites(book_title, book_author);

-- =====================================================
-- STEP 6: ENABLE ROW LEVEL SECURITY (RLS)
-- =====================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_personality_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- STEP 7: CREATE RLS POLICIES
-- =====================================================

-- Users table policies
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = auth_user_id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = auth_user_id);

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = auth_user_id);

-- Personality profiles policies
CREATE POLICY "Users can view own personality profile" ON user_personality_profiles
    FOR SELECT USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert own personality profile" ON user_personality_profiles
    FOR INSERT WITH CHECK (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update own personality profile" ON user_personality_profiles
    FOR UPDATE USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

-- Favorites policies
CREATE POLICY "Users can view own favorites" ON user_favorites
    FOR SELECT USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert own favorites" ON user_favorites
    FOR INSERT WITH CHECK (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete own favorites" ON user_favorites
    FOR DELETE USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

-- =====================================================
-- STEP 8: DROP EXISTING FUNCTIONS (if they exist)
-- =====================================================

-- Drop any existing functions that might conflict
DROP FUNCTION IF EXISTS get_or_create_user(UUID, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS save_personality_profile(UUID, INTEGER, INTEGER, INTEGER, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS get_personality_profile(UUID);
DROP FUNCTION IF EXISTS add_book_to_favorites(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS remove_book_from_favorites(UUID, TEXT, TEXT);
DROP FUNCTION IF EXISTS get_user_favorites(UUID);

-- =====================================================
-- STEP 9: CREATE HELPER FUNCTIONS
-- =====================================================

-- Function to get or create user profile
CREATE OR REPLACE FUNCTION get_or_create_user(
    auth_user_id UUID,
    user_name TEXT,
    user_email TEXT,
    user_username TEXT DEFAULT NULL,
    user_avatar_url TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
BEGIN
    -- Try to find existing user
    SELECT id INTO user_uuid
    FROM users
    WHERE users.auth_user_id = get_or_create_user.auth_user_id;
    
    -- If user doesn't exist, create them
    IF user_uuid IS NULL THEN
        INSERT INTO users (auth_user_id, name, email, username, avatar_url)
        VALUES (get_or_create_user.auth_user_id, user_name, user_email, user_username, user_avatar_url)
        RETURNING id INTO user_uuid;
    END IF;
    
    RETURN user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to save personality profile
CREATE OR REPLACE FUNCTION save_personality_profile(
    auth_user_id UUID,
    openness_val INTEGER,
    conscientiousness_val INTEGER,
    extraversion_val INTEGER,
    agreeableness_val INTEGER,
    emotional_stability_val INTEGER
)
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
    profile_uuid UUID;
BEGIN
    -- Get or create user
    SELECT get_or_create_user(
        auth_user_id,
        'User', -- Default name, can be updated later
        'user@example.com' -- Default email, can be updated later
    ) INTO user_uuid;
    
    -- Insert or update personality profile
    INSERT INTO user_personality_profiles (
        user_id, openness, conscientiousness, extraversion, agreeableness, emotional_stability
    )
    VALUES (
        user_uuid, openness_val, conscientiousness_val, extraversion_val, agreeableness_val, emotional_stability_val
    )
    ON CONFLICT (user_id)
    DO UPDATE SET
        openness = EXCLUDED.openness,
        conscientiousness = EXCLUDED.conscientiousness,
        extraversion = EXCLUDED.extraversion,
        agreeableness = EXCLUDED.agreeableness,
        emotional_stability = EXCLUDED.emotional_stability,
        updated_at = NOW()
    RETURNING id INTO profile_uuid;
    
    RETURN profile_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get personality profile
CREATE OR REPLACE FUNCTION get_personality_profile(auth_user_id UUID)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    openness INTEGER,
    conscientiousness INTEGER,
    extraversion INTEGER,
    agreeableness INTEGER,
    emotional_stability INTEGER,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pp.id,
        pp.user_id,
        pp.openness,
        pp.conscientiousness,
        pp.extraversion,
        pp.agreeableness,
        pp.emotional_stability,
        pp.created_at,
        pp.updated_at
    FROM user_personality_profiles pp
    JOIN users u ON pp.user_id = u.id
    WHERE u.auth_user_id = get_personality_profile.auth_user_id
    ORDER BY pp.updated_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to add book to favorites
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
    DO NOTHING
    RETURNING id INTO favorite_uuid;
    
    RETURN favorite_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to remove book from favorites
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

-- Function to get user favorites
CREATE OR REPLACE FUNCTION get_user_favorites(auth_user_id UUID)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    book_title TEXT,
    book_author TEXT,
    book_genre TEXT,
    book_description TEXT,
    book_amazon_link TEXT,
    book_cover_image_url TEXT,
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        uf.id,
        uf.user_id,
        uf.book_title,
        uf.book_author,
        uf.book_genre,
        uf.book_description,
        uf.book_amazon_link,
        uf.book_cover_image_url,
        uf.reason,
        uf.created_at
    FROM user_favorites uf
    JOIN users u ON uf.user_id = u.id
    WHERE u.auth_user_id = get_user_favorites.auth_user_id
    ORDER BY uf.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 10: GRANT PERMISSIONS
-- =====================================================

GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- =====================================================
-- STEP 11: VERIFICATION
-- =====================================================

SELECT 'Fresh database setup completed successfully!' as status;
SELECT 'Tables created:' as info;
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
SELECT 'Functions created:' as info;
SELECT routine_name FROM information_schema.routines WHERE routine_schema = 'public' AND routine_type = 'FUNCTION';
