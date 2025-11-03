-- Fix Personality Function
-- This script properly handles the existing get_user_personality_profile function

-- ===========================================
-- STEP 1: CHECK EXISTING FUNCTION
-- ===========================================

SELECT '=== CHECKING EXISTING FUNCTION ===' as header;

-- Check what functions exist with this name
SELECT 
    routine_name,
    specific_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_name LIKE '%personality%' 
AND routine_schema = 'public';

-- ===========================================
-- STEP 2: DROP ALL EXISTING PERSONALITY FUNCTIONS
-- ===========================================

-- Drop all possible variations of the function
DROP FUNCTION IF EXISTS get_user_personality_profile(TEXT);
DROP FUNCTION IF EXISTS get_user_personality_profile(UUID);
DROP FUNCTION IF EXISTS user_has_personality_profile(TEXT);
DROP FUNCTION IF EXISTS user_has_personality_profile(UUID);

-- ===========================================
-- STEP 3: CREATE NEW FUNCTIONS WITH CORRECT STRUCTURE
-- ===========================================

-- Function to check if user has personality profile
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

-- ===========================================
-- STEP 4: TEST THE FUNCTIONS
-- ===========================================

SELECT '=== TESTING NEW FUNCTIONS ===' as header;

-- Test user_has_personality_profile
SELECT 'Testing user_has_personality_profile...' as test;
SELECT user_has_personality_profile('00000000-0000-0000-0000-000000000001') as has_profile;

-- Test get_user_personality_profile
SELECT 'Testing get_user_personality_profile...' as test;
SELECT * FROM get_user_personality_profile('00000000-0000-0000-0000-000000000001');

SELECT '=== PERSONALITY FUNCTIONS FIXED ===' as header;
