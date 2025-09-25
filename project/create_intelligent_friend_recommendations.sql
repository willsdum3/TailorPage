-- Create intelligent friend recommendations system
-- This script creates a comprehensive friend matching system based on personality compatibility

-- =====================================================
-- STEP 1: CREATE FRIEND RECOMMENDATIONS TABLE
-- =====================================================

-- Create table to store generated friend recommendations
CREATE TABLE IF NOT EXISTS friend_recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recommended_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    match_score DECIMAL(5,2) NOT NULL CHECK (match_score >= 0 AND match_score <= 100),
    match_reasons TEXT[] NOT NULL,
    personality_analysis JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),
    
    -- Ensure no duplicate recommendations
    CONSTRAINT unique_recommendation UNIQUE(user_id, recommended_user_id),
    -- Ensure users can't recommend themselves
    CONSTRAINT no_self_recommendation CHECK (user_id != recommended_user_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_friend_recommendations_user ON friend_recommendations(user_id);
CREATE INDEX IF NOT EXISTS idx_friend_recommendations_score ON friend_recommendations(match_score DESC);
CREATE INDEX IF NOT EXISTS idx_friend_recommendations_expires ON friend_recommendations(expires_at);
CREATE INDEX IF NOT EXISTS idx_friend_recommendations_created ON friend_recommendations(created_at DESC);

-- =====================================================
-- STEP 2: CREATE PERSONALITY MATCHING FUNCTIONS
-- =====================================================

-- Drop existing function first to change return type
DROP FUNCTION IF EXISTS calculate_personality_compatibility(UUID, UUID);

-- Function to calculate personality compatibility between two users
CREATE OR REPLACE FUNCTION calculate_personality_compatibility(
    p_user1_id UUID,
    p_user2_id UUID
) RETURNS JSONB AS $$
DECLARE
    user1_profile RECORD;
    user2_profile RECORD;
    total_score DECIMAL(5,2) := 0;
    trait_count INTEGER := 0;
    trait_scores JSONB := '{}';
    match_reasons TEXT[] := '{}';
    personality_analysis JSONB := '{}';
    trait_name TEXT;
    trait_score DECIMAL(5,2);
    compatibility_score DECIMAL(5,2);
BEGIN
    -- Get personality profiles for both users
    SELECT * INTO user1_profile
    FROM user_personality_profiles
    WHERE user_id = p_user1_id;
    
    SELECT * INTO user2_profile
    FROM user_personality_profiles
    WHERE user_id = p_user2_id;
    
    -- Check if both users have personality profiles
    IF user1_profile IS NULL OR user2_profile IS NULL THEN
        RETURN json_build_object(
            'compatibility_score', 0,
            'match_reasons', ARRAY['Personality profiles not available'],
            'personality_analysis', '{}'
        );
    END IF;
    
    -- Calculate compatibility for each trait
    -- Openness
    trait_score := 100 - ABS(user1_profile.openness - user2_profile.openness) * 4; -- Max difference is 25, so *4 gives 0-100 scale
    trait_scores := jsonb_set(trait_scores, '{openness}', to_jsonb(trait_score));
    total_score := total_score + trait_score;
    trait_count := trait_count + 1;
    
    -- Conscientiousness
    trait_score := 100 - ABS(user1_profile.conscientiousness - user2_profile.conscientiousness) * 4;
    trait_scores := jsonb_set(trait_scores, '{conscientiousness}', to_jsonb(trait_score));
    total_score := total_score + trait_score;
    trait_count := trait_count + 1;
    
    -- Extraversion
    trait_score := 100 - ABS(user1_profile.extraversion - user2_profile.extraversion) * 4;
    trait_scores := jsonb_set(trait_scores, '{extraversion}', to_jsonb(trait_score));
    total_score := total_score + trait_score;
    trait_count := trait_count + 1;
    
    -- Agreeableness
    trait_score := 100 - ABS(user1_profile.agreeableness - user2_profile.agreeableness) * 4;
    trait_scores := jsonb_set(trait_scores, '{agreeableness}', to_jsonb(trait_score));
    total_score := total_score + trait_score;
    trait_count := trait_count + 1;
    
    -- Emotional Stability
    trait_score := 100 - ABS(user1_profile.emotional_stability - user2_profile.emotional_stability) * 4;
    trait_scores := jsonb_set(trait_scores, '{emotional_stability}', to_jsonb(trait_score));
    total_score := total_score + trait_score;
    trait_count := trait_count + 1;
    
    -- Calculate overall compatibility score
    compatibility_score := total_score / trait_count;
    
    -- Generate match reasons based on high-scoring traits
    IF (trait_scores->>'openness')::DECIMAL > 70 THEN
        match_reasons := array_append(match_reasons, 'Similar openness to new experiences');
    END IF;
    
    IF (trait_scores->>'conscientiousness')::DECIMAL > 70 THEN
        match_reasons := array_append(match_reasons, 'Both value organization and planning');
    END IF;
    
    IF (trait_scores->>'extraversion')::DECIMAL > 70 THEN
        match_reasons := array_append(match_reasons, 'Compatible social energy levels');
    END IF;
    
    IF (trait_scores->>'agreeableness')::DECIMAL > 70 THEN
        match_reasons := array_append(match_reasons, 'Similar values on cooperation and trust');
    END IF;
    
    IF (trait_scores->>'emotional_stability')::DECIMAL > 70 THEN
        match_reasons := array_append(match_reasons, 'Similar emotional resilience');
    END IF;
    
    -- Add general compatibility reason if overall score is high
    IF compatibility_score > 75 THEN
        match_reasons := array_append(match_reasons, 'High overall personality compatibility');
    ELSIF compatibility_score > 60 THEN
        match_reasons := array_append(match_reasons, 'Good personality compatibility');
    END IF;
    
    -- If no specific reasons, add a general one
    IF array_length(match_reasons, 1) IS NULL THEN
        match_reasons := ARRAY['Potential personality compatibility'];
    END IF;
    
    -- Build personality analysis
    personality_analysis := jsonb_build_object(
        'user1_traits', jsonb_build_object(
            'openness', user1_profile.openness,
            'conscientiousness', user1_profile.conscientiousness,
            'extraversion', user1_profile.extraversion,
            'agreeableness', user1_profile.agreeableness,
            'emotional_stability', user1_profile.emotional_stability
        ),
        'user2_traits', jsonb_build_object(
            'openness', user2_profile.openness,
            'conscientiousness', user2_profile.conscientiousness,
            'extraversion', user2_profile.extraversion,
            'agreeableness', user2_profile.agreeableness,
            'emotional_stability', user2_profile.emotional_stability
        ),
        'trait_compatibility_scores', trait_scores,
        'overall_compatibility', compatibility_score
    );
    
    RETURN json_build_object(
        'compatibility_score', compatibility_score,
        'match_reasons', match_reasons,
        'personality_analysis', personality_analysis
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 3: UPDATE FRIEND RECOMMENDATION FUNCTIONS
-- =====================================================

-- Drop existing functions
DROP FUNCTION IF EXISTS generate_friend_recommendations(UUID);
DROP FUNCTION IF EXISTS get_friend_recommendations(UUID);

-- Create new generate_friend_recommendations function
CREATE OR REPLACE FUNCTION generate_friend_recommendations(p_auth_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_user_id UUID;
    recommendation_count INTEGER := 0;
    potential_friend RECORD;
    compatibility_result JSONB;
    compatibility_score DECIMAL(5,2);
    match_reasons TEXT[];
    personality_analysis JSONB;
BEGIN
    -- Get current user's internal ID
    SELECT id INTO current_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Clear existing recommendations for this user
    DELETE FROM friend_recommendations 
    WHERE user_id = current_user_id;
    
    -- Find potential friends (users with personality profiles who aren't already friends)
    FOR potential_friend IN (
        SELECT u.id, u.name, u.username, u.avatar_url
        FROM users u
        INNER JOIN user_personality_profiles upp ON u.id = upp.user_id
        WHERE u.id != current_user_id
        AND u.id NOT IN (
            -- Exclude existing friends
            SELECT CASE 
                WHEN requester_id = current_user_id THEN target_id
                ELSE requester_id
            END
            FROM friend_requests 
            WHERE (requester_id = current_user_id OR target_id = current_user_id)
            AND status = 'accepted'
        )
        AND u.id NOT IN (
            -- Exclude blocked users
            SELECT CASE 
                WHEN blocker_id = current_user_id THEN blocked_id
                ELSE blocker_id
            END
            FROM blocked_users 
            WHERE (blocker_id = current_user_id OR blocked_id = current_user_id)
        )
        AND u.id NOT IN (
            -- Exclude pending friend requests
            SELECT CASE 
                WHEN requester_id = current_user_id THEN target_id
                ELSE requester_id
            END
            FROM friend_requests 
            WHERE (requester_id = current_user_id OR target_id = current_user_id)
            AND status = 'pending'
        )
        ORDER BY u.created_at DESC
        LIMIT 50 -- Limit to 50 potential friends for performance
    ) LOOP
        -- Calculate compatibility
        SELECT calculate_personality_compatibility(current_user_id, potential_friend.id) INTO compatibility_result;
        
        compatibility_score := (compatibility_result->>'compatibility_score')::DECIMAL;
        match_reasons := ARRAY(SELECT jsonb_array_elements_text(compatibility_result->'match_reasons'));
        personality_analysis := compatibility_result->'personality_analysis';
        
        -- Only recommend if compatibility score is 50% or higher
        IF compatibility_score >= 50 THEN
            INSERT INTO friend_recommendations (
                user_id,
                recommended_user_id,
                match_score,
                match_reasons
            ) VALUES (
                current_user_id,
                potential_friend.id,
                compatibility_score,
                match_reasons
            );
            
            recommendation_count := recommendation_count + 1;
        END IF;
        
        -- Limit to 10 recommendations
        IF recommendation_count >= 10 THEN
            EXIT;
        END IF;
    END LOOP;
    
    RETURN recommendation_count;
END;
$$;

-- Create new get_friend_recommendations function
CREATE OR REPLACE FUNCTION get_friend_recommendations(p_auth_user_id UUID)
RETURNS TABLE(
    id UUID,
    recommended_user_id UUID,
    recommended_user_name TEXT,
    recommended_user_username TEXT,
    recommended_user_image_url TEXT,
    match_score DECIMAL(5,2),
    match_reasons TEXT[],
    created_at TIMESTAMP WITH TIME ZONE
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_user_id UUID;
BEGIN
    -- Get current user's internal ID
    SELECT users.id INTO current_user_id
    FROM users 
    WHERE users.auth_user_id = p_auth_user_id;
    
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    RETURN QUERY
    SELECT 
        fr.id,
        fr.recommended_user_id,
        u.name as recommended_user_name,
        u.username as recommended_user_username,
        u.avatar_url as recommended_user_image_url,
        fr.match_score,
        fr.match_reasons,
        fr.created_at
    FROM friend_recommendations fr
    JOIN users u ON fr.recommended_user_id = u.id
    WHERE fr.user_id = current_user_id
    AND fr.expires_at > NOW()
    ORDER BY fr.match_score DESC, fr.created_at DESC;
END;
$$;

-- =====================================================
-- STEP 4: CREATE CLEANUP FUNCTION
-- =====================================================

-- Function to clean up expired recommendations
CREATE OR REPLACE FUNCTION cleanup_expired_recommendations()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM friend_recommendations 
    WHERE expires_at < NOW();
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$;
