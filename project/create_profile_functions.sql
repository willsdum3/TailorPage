-- Create Profile Access Functions
-- This script creates all the missing database functions for accessing user profile data

-- ===========================================
-- STEP 1: CREATE PROFILE ACCESS FUNCTIONS
-- ===========================================

-- Function to check if user has personality profile
-- Drop existing function first if it exists
DROP FUNCTION IF EXISTS user_has_personality_profile(UUID);

CREATE OR REPLACE FUNCTION user_has_personality_profile(p_auth_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_internal_id UUID;
    profile_exists BOOLEAN;
BEGIN
    -- Get user's internal ID
    SELECT id INTO user_internal_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id
    LIMIT 1;
    
    IF user_internal_id IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Check if personality profile exists
    SELECT EXISTS(
        SELECT 1 FROM personality_profiles 
        WHERE user_id = user_internal_id
    ) INTO profile_exists;
    
    RETURN profile_exists;
END;
$$;

-- Function to get user's personality profile
DROP FUNCTION IF EXISTS get_user_personality_profile(UUID);

CREATE OR REPLACE FUNCTION get_user_personality_profile(p_auth_user_id UUID)
RETURNS TABLE(
    openness DECIMAL(3,2),
    conscientiousness DECIMAL(3,2),
    extraversion DECIMAL(3,2),
    agreeableness DECIMAL(3,2),
    neuroticism DECIMAL(3,2),
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    -- Get user's internal ID
    SELECT id INTO user_internal_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id
    LIMIT 1;
    
    IF user_internal_id IS NULL THEN
        RETURN;
    END IF;
    
    -- Return personality profile
    RETURN QUERY
    SELECT 
        pp.openness,
        pp.conscientiousness,
        pp.extraversion,
        pp.agreeableness,
        pp.neuroticism,
        pp.created_at,
        pp.updated_at
    FROM personality_profiles pp
    WHERE pp.user_id = user_internal_id;
END;
$$;

-- Function to get user's favorites
DROP FUNCTION IF EXISTS get_user_favorites(UUID);

CREATE OR REPLACE FUNCTION get_user_favorites(p_auth_user_id UUID)
RETURNS TABLE(
    favorite_type TEXT,
    favorite_id TEXT,
    favorite_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_internal_id UUID;
    has_favorite_type BOOLEAN;
    has_favorite_id BOOLEAN;
    has_favorite_name BOOLEAN;
BEGIN
    -- Get user's internal ID
    SELECT id INTO user_internal_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id
    LIMIT 1;
    
    IF user_internal_id IS NULL THEN
        RETURN;
    END IF;
    
    -- Check if the required columns exist
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_favorites' AND column_name = 'favorite_type'
    ) INTO has_favorite_type;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_favorites' AND column_name = 'favorite_id'
    ) INTO has_favorite_id;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_favorites' AND column_name = 'favorite_name'
    ) INTO has_favorite_name;
    
    -- Only return data if all required columns exist
    IF has_favorite_type AND has_favorite_id AND has_favorite_name THEN
        RETURN QUERY
        SELECT 
            uf.favorite_type,
            uf.favorite_id,
            uf.favorite_name,
            uf.created_at
        FROM user_favorites uf
        WHERE uf.user_id = user_internal_id
        ORDER BY uf.created_at DESC;
    END IF;
END;
$$;

-- Function to get user's quiz results
DROP FUNCTION IF EXISTS get_user_quiz_results(UUID);

CREATE OR REPLACE FUNCTION get_user_quiz_results(p_auth_user_id UUID)
RETURNS TABLE(
    quiz_type TEXT,
    quiz_data JSONB,
    score DECIMAL(5,2),
    completed_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    -- Get user's internal ID
    SELECT id INTO user_internal_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id
    LIMIT 1;
    
    IF user_internal_id IS NULL THEN
        RETURN;
    END IF;
    
    -- Return quiz results
    RETURN QUERY
    SELECT 
        qr.quiz_type,
        qr.quiz_data,
        qr.score,
        qr.completed_at
    FROM quiz_results qr
    WHERE qr.user_id = user_internal_id
    ORDER BY qr.completed_at DESC;
END;
$$;

-- Function to get user's reading preferences
DROP FUNCTION IF EXISTS get_user_reading_preferences(UUID);

CREATE OR REPLACE FUNCTION get_user_reading_preferences(p_auth_user_id UUID)
RETURNS TABLE(
    preferred_genres TEXT[],
    preferred_authors TEXT[],
    reading_pace TEXT,
    preferred_book_length TEXT,
    reading_frequency TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    -- Get user's internal ID
    SELECT id INTO user_internal_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id
    LIMIT 1;
    
    IF user_internal_id IS NULL THEN
        RETURN;
    END IF;
    
    -- Return reading preferences
    RETURN QUERY
    SELECT 
        rp.preferred_genres,
        rp.preferred_authors,
        rp.reading_pace,
        rp.preferred_book_length,
        rp.reading_frequency,
        rp.created_at,
        rp.updated_at
    FROM reading_preferences rp
    WHERE rp.user_id = user_internal_id;
END;
$$;

-- Function to save personality profile
DROP FUNCTION IF EXISTS save_personality_profile(UUID, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL);

CREATE OR REPLACE FUNCTION save_personality_profile(
    p_auth_user_id UUID,
    p_openness DECIMAL(3,2),
    p_conscientiousness DECIMAL(3,2),
    p_extraversion DECIMAL(3,2),
    p_agreeableness DECIMAL(3,2),
    p_neuroticism DECIMAL(3,2)
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    -- Get user's internal ID
    SELECT id INTO user_internal_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id
    LIMIT 1;
    
    IF user_internal_id IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Insert or update personality profile
    INSERT INTO personality_profiles (user_id, openness, conscientiousness, extraversion, agreeableness, neuroticism)
    VALUES (user_internal_id, p_openness, p_conscientiousness, p_extraversion, p_agreeableness, p_neuroticism)
    ON CONFLICT (user_id) 
    DO UPDATE SET 
        openness = EXCLUDED.openness,
        conscientiousness = EXCLUDED.conscientiousness,
        extraversion = EXCLUDED.extraversion,
        agreeableness = EXCLUDED.agreeableness,
        neuroticism = EXCLUDED.neuroticism,
        updated_at = NOW();
    
    RETURN TRUE;
END;
$$;

-- Function to save quiz result
DROP FUNCTION IF EXISTS save_quiz_result(UUID, TEXT, JSONB, DECIMAL);

CREATE OR REPLACE FUNCTION save_quiz_result(
    p_auth_user_id UUID,
    p_quiz_type TEXT,
    p_quiz_data JSONB,
    p_score DECIMAL(5,2)
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    -- Get user's internal ID
    SELECT id INTO user_internal_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id
    LIMIT 1;
    
    IF user_internal_id IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Insert or update quiz result
    INSERT INTO quiz_results (user_id, quiz_type, quiz_data, score)
    VALUES (user_internal_id, p_quiz_type, p_quiz_data, p_score)
    ON CONFLICT (user_id, quiz_type) 
    DO UPDATE SET 
        quiz_data = EXCLUDED.quiz_data,
        score = EXCLUDED.score,
        completed_at = NOW();
    
    RETURN TRUE;
END;
$$;

-- Function to save reading preferences
DROP FUNCTION IF EXISTS save_reading_preferences(UUID, TEXT[], TEXT[], TEXT, TEXT, TEXT);

CREATE OR REPLACE FUNCTION save_reading_preferences(
    p_auth_user_id UUID,
    p_preferred_genres TEXT[],
    p_preferred_authors TEXT[],
    p_reading_pace TEXT,
    p_preferred_book_length TEXT,
    p_reading_frequency TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    -- Get user's internal ID
    SELECT id INTO user_internal_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id
    LIMIT 1;
    
    IF user_internal_id IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Insert or update reading preferences
    INSERT INTO reading_preferences (user_id, preferred_genres, preferred_authors, reading_pace, preferred_book_length, reading_frequency)
    VALUES (user_internal_id, p_preferred_genres, p_preferred_authors, p_reading_pace, p_preferred_book_length, p_reading_frequency)
    ON CONFLICT (user_id) 
    DO UPDATE SET 
        preferred_genres = EXCLUDED.preferred_genres,
        preferred_authors = EXCLUDED.preferred_authors,
        reading_pace = EXCLUDED.reading_pace,
        preferred_book_length = EXCLUDED.preferred_book_length,
        reading_frequency = EXCLUDED.reading_frequency,
        updated_at = NOW();
    
    RETURN TRUE;
END;
$$;

-- ===========================================
-- STEP 2: TEST THE FUNCTIONS
-- ===========================================

SELECT '=== TESTING PROFILE FUNCTIONS ===' as header;

-- Test user_has_personality_profile
SELECT 'Testing user_has_personality_profile...' as test;
SELECT user_has_personality_profile('00000000-0000-0000-0000-000000000001') as has_profile;

-- Test get_user_personality_profile
SELECT 'Testing get_user_personality_profile...' as test;
SELECT * FROM get_user_personality_profile('00000000-0000-0000-0000-000000000001');

-- Test get_user_favorites
SELECT 'Testing get_user_favorites...' as test;
SELECT * FROM get_user_favorites('00000000-0000-0000-0000-000000000001');

-- Test get_user_quiz_results
SELECT 'Testing get_user_quiz_results...' as test;
SELECT * FROM get_user_quiz_results('00000000-0000-0000-0000-000000000001');

-- Test get_user_reading_preferences
SELECT 'Testing get_user_reading_preferences...' as test;
SELECT * FROM get_user_reading_preferences('00000000-0000-0000-0000-000000000001');

SELECT '=== PROFILE FUNCTIONS CREATED SUCCESSFULLY ===' as header;
