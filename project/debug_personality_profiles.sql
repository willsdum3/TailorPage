-- Debug script to investigate personality profiles issue
-- This will help us understand why the diagnostic script isn't finding personality profiles

-- Check 1: Count all users
SELECT 
    'Total Users' as check_type,
    COUNT(*) as count
FROM users;

-- Check 2: Count users with personality profiles
SELECT 
    'Users with Personality Profiles' as check_type,
    COUNT(*) as count
FROM users u
INNER JOIN user_personality_profiles upp ON u.id = upp.user_id;

-- Check 3: Show all users and their personality profile status
SELECT 
    'User Profile Status' as check_type,
    u.id as user_id,
    u.name,
    u.username,
    u.auth_user_id,
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

-- Check 4: Show all personality profiles directly
SELECT 
    'All Personality Profiles' as check_type,
    upp.id as profile_id,
    upp.user_id,
    u.name as user_name,
    u.username,
    upp.openness,
    upp.conscientiousness,
    upp.extraversion,
    upp.agreeableness,
    upp.emotional_stability,
    upp.created_at
FROM user_personality_profiles upp
JOIN users u ON upp.user_id = u.id
ORDER BY upp.created_at DESC;

-- Check 5: Check if there are any personality profiles at all
SELECT 
    'Personality Profiles Table' as check_type,
    COUNT(*) as total_profiles
FROM user_personality_profiles;

-- Check 6: Show table structure
SELECT 
    'Table Structure' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_personality_profiles'
ORDER BY ordinal_position;
