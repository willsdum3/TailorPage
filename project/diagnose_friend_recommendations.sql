-- Diagnostic script to understand why no friend recommendations are being generated

-- Check 1: How many users have personality profiles?
SELECT 
    'Users with Personality Profiles' as check_type,
    COUNT(*) as count
FROM users u
INNER JOIN user_personality_profiles upp ON u.id = upp.user_id;

-- Check 2: Show all users and their personality profile status
SELECT 
    'User Profile Status' as check_type,
    u.name,
    u.username,
    CASE 
        WHEN upp.user_id IS NOT NULL THEN 'Has Profile'
        ELSE 'No Profile'
    END as profile_status,
    CASE 
        WHEN upp.user_id IS NOT NULL THEN 
            'O:' || upp.openness || 
            ' C:' || upp.conscientiousness || 
            ' E:' || upp.extraversion || 
            ' A:' || upp.agreeableness || 
            ' ES:' || upp.emotional_stability
        ELSE 'N/A'
    END as personality_scores
FROM users u
LEFT JOIN user_personality_profiles upp ON u.id = upp.user_id
ORDER BY u.name;

-- Check 3: Test compatibility between two users (if they exist)
DO $$
DECLARE
    user1_id UUID;
    user2_id UUID;
    compatibility_result JSON;
    compatibility_score DECIMAL(5,2);
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
        compatibility_score := (compatibility_result->>'compatibility_score')::DECIMAL;
        
        RAISE NOTICE 'Compatibility Test: User1 (%) vs User2 (%) = %%%', 
            user1_id, user2_id, compatibility_score;
        RAISE NOTICE 'Match Reasons: %', compatibility_result->>'match_reasons';
    ELSE
        RAISE NOTICE 'Compatibility Test: SKIPPED - Need at least 2 users with personality profiles';
    END IF;
END $$;

-- Check 4: Show existing friend relationships
SELECT 
    'Existing Friend Relationships' as check_type,
    u1.name as user1_name,
    u2.name as user2_name,
    fr.status,
    fr.created_at
FROM friend_requests fr
JOIN users u1 ON fr.requester_id = u1.id
JOIN users u2 ON fr.target_id = u2.id
ORDER BY fr.created_at DESC;

-- Check 5: Test generating recommendations for a specific user
DO $$
DECLARE
    test_user_id UUID;
    recommendation_count INTEGER;
BEGIN
    -- Find a user with a personality profile
    SELECT u.id INTO test_user_id
    FROM users u
    INNER JOIN user_personality_profiles upp ON u.id = upp.user_id
    LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        -- Test generating recommendations
        SELECT generate_friend_recommendations(
            (SELECT auth_user_id FROM users WHERE id = test_user_id)
        ) INTO recommendation_count;
        
        RAISE NOTICE 'Generated % recommendations for user %', recommendation_count, test_user_id;
        
        -- Show any generated recommendations
        IF recommendation_count > 0 THEN
            RAISE NOTICE 'Recommendations generated successfully!';
        ELSE
            RAISE NOTICE 'No recommendations generated - likely due to low compatibility scores or no eligible users';
        END IF;
    ELSE
        RAISE NOTICE 'Recommendation Test: SKIPPED - No users with personality profiles found';
    END IF;
END $$;
