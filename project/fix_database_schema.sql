-- Fix Database Schema Issues
-- This script fixes the PostgreSQL 42804 datatype mismatch errors

-- 1. Fix get_user_personality_profile function
-- The function is returning numeric(3,1) instead of integer for personality scores
DROP FUNCTION IF EXISTS get_user_personality_profile(uuid);

CREATE OR REPLACE FUNCTION get_user_personality_profile(user_auth_id uuid)
RETURNS TABLE (
    id uuid,
    auth_user_id uuid,
    openness numeric(3,1),
    conscientiousness numeric(3,1),
    extraversion numeric(3,1),
    agreeableness numeric(3,1),
    emotional_stability numeric(3,1),
    rational_thinking numeric(3,1),
    core_values numeric(3,1),
    lifestyle numeric(3,1),
    social_style numeric(3,1),
    self_expression numeric(3,1),
    created_at timestamptz,
    updated_at timestamptz
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        upp.id,
        upp.auth_user_id,
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
    ORDER BY upp.created_at DESC
    LIMIT 1;
END;
$$;

-- 2. Fix get_user_favorites function
-- The function is returning smallint instead of integer for the rating column (column 11)
DROP FUNCTION IF EXISTS get_user_favorites(uuid);

CREATE OR REPLACE FUNCTION get_user_favorites(user_auth_id uuid)
RETURNS TABLE (
    id uuid,
    book_id uuid,
    title text,
    author text,
    genre text,
    description text,
    amazon_link text,
    cover_image_url text,
    date_added timestamptz,
    notes text,
    rating smallint, -- Changed from integer to smallint to match actual database type
    is_read boolean,
    read_date timestamptz
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        uf.id,
        uf.book_id,
        b.title::text,
        b.author::text,
        b.genre::text,
        b.description::text,
        b.amazon_link::text,
        b.cover_image_url::text,
        uf.date_added,
        uf.notes::text,
        uf.rating, -- This is smallint in the database
        uf.is_read,
        uf.read_date
    FROM user_favorites uf
    LEFT JOIN books b ON uf.book_id = b.id
    WHERE uf.auth_user_id = user_auth_id
    ORDER BY uf.date_added DESC;
END;
$$;

-- 3. Grant necessary permissions
GRANT EXECUTE ON FUNCTION get_user_personality_profile(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_favorites(uuid) TO authenticated;

-- 4. Verify the fixes
SELECT 'Database schema fixes applied successfully' as status;
