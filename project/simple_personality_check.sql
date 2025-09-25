-- Simple check for personality profiles
-- This will give us the exact information we need

-- Check 1: Count all users
SELECT COUNT(*) as total_users FROM users;

-- Check 2: Count personality profiles
SELECT COUNT(*) as total_personality_profiles FROM user_personality_profiles;

-- Check 3: Show all personality profiles with user names
SELECT 
    u.name,
    u.username,
    upp.openness,
    upp.conscientiousness,
    upp.extraversion,
    upp.agreeableness,
    upp.emotional_stability
FROM user_personality_profiles upp
JOIN users u ON upp.user_id = u.id
ORDER BY u.name;

-- Check 4: Test the join that the recommendation function uses
SELECT 
    u.id,
    u.name,
    u.username,
    upp.openness,
    upp.conscientiousness,
    upp.extraversion,
    upp.agreeableness,
    upp.emotional_stability
FROM users u
INNER JOIN user_personality_profiles upp ON u.id = upp.user_id
ORDER BY u.name;
