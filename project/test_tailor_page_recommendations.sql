-- Test friend recommendations for Tailor Page
-- Since he's only friends with William, he should get recommendations for Kat, Pauline, and Tracey

-- Test 1: Calculate compatibility between Tailor Page and Kat
SELECT 
    'Tailor Page vs Kat' as test_pair,
    calculate_personality_compatibility(
        'df1ec11e-9b78-4fb5-8218-c6fb03320100', -- Tailor Page
        '6a551bb7-3323-42ce-971d-ec4f0f4a6f69'  -- Kat
    ) as compatibility_result;

-- Test 2: Calculate compatibility between Tailor Page and Pauline
SELECT 
    'Tailor Page vs Pauline' as test_pair,
    calculate_personality_compatibility(
        'df1ec11e-9b78-4fb5-8218-c6fb03320100', -- Tailor Page
        'baf44ea3-ca65-43a7-8b16-18d16370b697'  -- Pauline
    ) as compatibility_result;

-- Test 3: Calculate compatibility between Tailor Page and Tracey
SELECT 
    'Tailor Page vs Tracey' as test_pair,
    calculate_personality_compatibility(
        'df1ec11e-9b78-4fb5-8218-c6fb03320100', -- Tailor Page
        '309f3f29-aeea-4f26-a936-8d65047dc469'  -- Tracey
    ) as compatibility_result;

-- Test 4: Check Tailor Page's current friend relationships
SELECT 
    'Tailor Page Friends' as check_type,
    u1.name as user1_name,
    u2.name as user2_name,
    fr.status,
    fr.created_at
FROM friend_requests fr
JOIN users u1 ON fr.requester_id = u1.id
JOIN users u2 ON fr.target_id = u2.id
WHERE (fr.requester_id = 'df1ec11e-9b78-4fb5-8218-c6fb03320100' OR fr.target_id = 'df1ec11e-9b78-4fb5-8218-c6fb03320100')
AND fr.status = 'accepted'
ORDER BY fr.created_at DESC;

-- Test 5: Generate recommendations for Tailor Page
DO $$
DECLARE
    tailor_page_auth_id UUID := '973ae2dc-d76f-455a-9f3c-87ab04c20120'; -- Tailor Page's auth_user_id
    recommendation_count INTEGER;
BEGIN
    SELECT generate_friend_recommendations(tailor_page_auth_id) INTO recommendation_count;
    RAISE NOTICE 'Generated % recommendations for Tailor Page', recommendation_count;
END $$;

-- Test 6: Show generated recommendations for Tailor Page
SELECT 
    'Tailor Page Recommendations' as check_type,
    u.name as recommended_name,
    u.username as recommended_username,
    fr.match_score,
    fr.match_reasons,
    fr.created_at
FROM friend_recommendations fr
JOIN users u ON fr.recommended_user_id = u.id
JOIN users cu ON fr.user_id = cu.id
WHERE cu.auth_user_id = '973ae2dc-d76f-455a-9f3c-87ab04c20120'
ORDER BY fr.match_score DESC;

-- Test 7: Show all recommendations in the system
SELECT 
    'All Recommendations' as check_type,
    cu.name as user_name,
    u.name as recommended_name,
    u.username as recommended_username,
    fr.match_score,
    fr.match_reasons
FROM friend_recommendations fr
JOIN users u ON fr.recommended_user_id = u.id
JOIN users cu ON fr.user_id = cu.id
ORDER BY cu.name, fr.match_score DESC;
