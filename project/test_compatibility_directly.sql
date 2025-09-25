-- Test compatibility calculation directly
-- This will help us understand why no recommendations are being generated

-- Test 1: Calculate compatibility between William and Kat
SELECT 
    'William vs Kat' as test_pair,
    calculate_personality_compatibility(
        '3bd64865-45b6-4b2b-81d2-4940a8bf3200', -- William
        '6a551bb7-3323-42ce-971d-ec4f0f4a6f69'  -- Kat
    ) as compatibility_result;

-- Test 2: Calculate compatibility between William and Pauline
SELECT 
    'William vs Pauline' as test_pair,
    calculate_personality_compatibility(
        '3bd64865-45b6-4b2b-81d2-4940a8bf3200', -- William
        'baf44ea3-ca65-43a7-8b16-18d16370b697'  -- Pauline
    ) as compatibility_result;

-- Test 3: Calculate compatibility between William and Tracey
SELECT 
    'William vs Tracey' as test_pair,
    calculate_personality_compatibility(
        '3bd64865-45b6-4b2b-81d2-4940a8bf3200', -- William
        '309f3f29-aeea-4f26-a936-8d65047dc469'  -- Tracey
    ) as compatibility_result;

-- Test 4: Calculate compatibility between William and Tailor Page
SELECT 
    'William vs Tailor Page' as test_pair,
    calculate_personality_compatibility(
        '3bd64865-45b6-4b2b-81d2-4940a8bf3200', -- William
        'df1ec11e-9b78-4fb5-8218-c6fb03320100'  -- Tailor Page
    ) as compatibility_result;

-- Test 5: Test the recommendation generation function directly
DO $$
DECLARE
    william_auth_id UUID := 'ee11bb62-0684-4293-a77a-d385c9a070f9';
    recommendation_count INTEGER;
BEGIN
    SELECT generate_friend_recommendations(william_auth_id) INTO recommendation_count;
    RAISE NOTICE 'Generated % recommendations for William', recommendation_count;
END $$;

-- Test 6: Check what recommendations were actually generated
SELECT 
    'Generated Recommendations' as check_type,
    u.name as recommended_name,
    u.username as recommended_username,
    fr.match_score,
    fr.match_reasons
FROM friend_recommendations fr
JOIN users u ON fr.recommended_user_id = u.id
JOIN users cu ON fr.user_id = cu.id
WHERE cu.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'
ORDER BY fr.match_score DESC;
