-- Test script for the intelligent friend recommendations system
-- This will help verify that the new system works correctly

-- Test 1: Check if the friend_recommendations table was created
SELECT 
    'Table Creation Test' as test_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'friend_recommendations') 
        THEN 'PASS - friend_recommendations table exists'
        ELSE 'FAIL - friend_recommendations table missing'
    END as result;

-- Test 2: Check if the functions were created
SELECT 
    'Function Creation Test' as test_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'calculate_personality_compatibility') 
        THEN 'PASS - calculate_personality_compatibility function exists'
        ELSE 'FAIL - calculate_personality_compatibility function missing'
    END as result;

SELECT 
    'Function Creation Test' as test_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'generate_friend_recommendations') 
        THEN 'PASS - generate_friend_recommendations function exists'
        ELSE 'FAIL - generate_friend_recommendations function missing'
    END as result;

SELECT 
    'Function Creation Test' as test_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'get_friend_recommendations') 
        THEN 'PASS - get_friend_recommendations function exists'
        ELSE 'FAIL - get_friend_recommendations function missing'
    END as result;

-- Test 3: Check users with personality profiles
SELECT 
    'Personality Profiles Test' as test_name,
    COUNT(*) as users_with_profiles
FROM users u
INNER JOIN user_personality_profiles upp ON u.id = upp.user_id;

-- Test 4: Test personality compatibility calculation (if we have at least 2 users with profiles)
DO $$
DECLARE
    user1_id UUID;
    user2_id UUID;
    compatibility_result JSON;
BEGIN
    -- Get two different users with personality profiles
    SELECT u1.id, u2.id INTO user1_id, user2_id
    FROM users u1
    INNER JOIN user_personality_profiles upp1 ON u1.id = upp1.user_id
    CROSS JOIN users u2
    INNER JOIN user_personality_profiles upp2 ON u2.id = upp2.user_id
    WHERE u1.id != u2.id
    LIMIT 1;
    
    IF user1_id IS NOT NULL AND user2_id IS NOT NULL THEN
        -- Test compatibility calculation
        SELECT calculate_personality_compatibility(user1_id, user2_id) INTO compatibility_result;
        
        RAISE NOTICE 'Compatibility Test Result: %', compatibility_result;
    ELSE
        RAISE NOTICE 'Compatibility Test: SKIPPED - Need at least 2 users with personality profiles';
    END IF;
END $$;

-- Test 5: Test generating recommendations for William (if he has a personality profile)
DO $$
DECLARE
    william_auth_id UUID := 'ee11bb62-0684-4293-a77a-d385c9a070f9';
    recommendation_count INTEGER;
    rec RECORD;
BEGIN
    -- Check if William has a personality profile
    IF EXISTS (
        SELECT 1 FROM users u
        INNER JOIN user_personality_profiles upp ON u.id = upp.user_id
        WHERE u.auth_user_id = william_auth_id
    ) THEN
        -- Test generating recommendations
        SELECT generate_friend_recommendations(william_auth_id) INTO recommendation_count;
        RAISE NOTICE 'Generated % recommendations for William', recommendation_count;
        
        -- Show the recommendations
        RAISE NOTICE 'Recommendations for William:';
        FOR rec IN 
            SELECT 
                u.name as recommended_name,
                u.username as recommended_username,
                fr.match_score,
                fr.match_reasons
            FROM friend_recommendations fr
            JOIN users u ON fr.recommended_user_id = u.id
            JOIN users cu ON fr.user_id = cu.id
            WHERE cu.auth_user_id = william_auth_id
            ORDER BY fr.match_score DESC
        LOOP
            RAISE NOTICE '  - % (@%) - %%% - Reasons: %', 
                rec.recommended_name, 
                rec.recommended_username, 
                rec.match_score,
                array_to_string(rec.match_reasons, ', ');
        END LOOP;
    ELSE
        RAISE NOTICE 'Recommendation Test: SKIPPED - William does not have a personality profile';
    END IF;
END $$;

-- Test 6: Show table structure
SELECT 
    'Table Structure' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'friend_recommendations'
ORDER BY ordinal_position;
