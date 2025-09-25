-- Debug script to find out why "User not found" error occurs
-- This will help us understand what's happening with user lookup

-- Check 1: Show all users and their auth_user_ids
SELECT 
    'All Users' as check_type,
    id as internal_id,
    auth_user_id,
    name,
    username
FROM users
ORDER BY name;

-- Check 2: Test the user lookup that the function uses
-- Let's test with a specific auth_user_id to see what happens
DO $$
DECLARE
    test_auth_user_id UUID;
    found_user_id UUID;
    user_count INTEGER;
BEGIN
    -- Get the first user's auth_user_id for testing
    SELECT auth_user_id INTO test_auth_user_id
    FROM users
    LIMIT 1;
    
    IF test_auth_user_id IS NOT NULL THEN
        RAISE NOTICE 'Testing with auth_user_id: %', test_auth_user_id;
        
        -- Test the exact query the function uses
        SELECT users.id INTO found_user_id
        FROM users 
        WHERE users.auth_user_id = test_auth_user_id;
        
        IF found_user_id IS NOT NULL THEN
            RAISE NOTICE 'User found with internal ID: %', found_user_id;
        ELSE
            RAISE NOTICE 'User NOT found with auth_user_id: %', test_auth_user_id;
        END IF;
        
        -- Count total users
        SELECT COUNT(*) INTO user_count FROM users;
        RAISE NOTICE 'Total users in database: %', user_count;
        
    ELSE
        RAISE NOTICE 'No users found in database';
    END IF;
END $$;

-- Check 3: Test the get_friend_recommendations function directly
DO $$
DECLARE
    test_auth_user_id UUID;
    result_count INTEGER;
BEGIN
    -- Get the first user's auth_user_id for testing
    SELECT auth_user_id INTO test_auth_user_id
    FROM users
    LIMIT 1;
    
    IF test_auth_user_id IS NOT NULL THEN
        RAISE NOTICE 'Testing get_friend_recommendations with auth_user_id: %', test_auth_user_id;
        
        BEGIN
            SELECT COUNT(*) INTO result_count
            FROM get_friend_recommendations(test_auth_user_id);
            
            RAISE NOTICE 'get_friend_recommendations returned % recommendations', result_count;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Error calling get_friend_recommendations: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE 'No users available for testing';
    END IF;
END $$;

-- Check 4: Show any existing recommendations
SELECT 
    'Existing Recommendations' as check_type,
    COUNT(*) as recommendation_count
FROM friend_recommendations;

-- Check 5: Show recommendations with user details
SELECT 
    'Recommendation Details' as check_type,
    cu.name as user_name,
    cu.auth_user_id as user_auth_id,
    u.name as recommended_name,
    u.username as recommended_username,
    fr.match_score,
    fr.match_reasons,
    fr.created_at
FROM friend_recommendations fr
JOIN users cu ON fr.user_id = cu.id
JOIN users u ON fr.recommended_user_id = u.id
ORDER BY fr.created_at DESC;
