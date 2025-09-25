-- Debug script specifically for Tracey Beaker removal
-- This will help us understand why removing Tracey fails

-- Step 1: Get current user's internal ID (William)
SELECT 
    'Step 1 - William internal ID' as step,
    id as william_internal_id
FROM users 
WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9';

-- Step 2: Get Tracey's auth_user_id
SELECT 
    'Step 2 - Tracey auth_user_id' as step,
    auth_user_id as tracey_auth_user_id
FROM users 
WHERE id = '309f3f29-aeea-4f26-a936-8d65047dc469';

-- Step 3: Check if William-Tracey friendship exists
SELECT 
    'Step 3 - William-Tracey friendship exists' as step,
    EXISTS(
        SELECT 1 FROM friend_requests 
        WHERE ((requester_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9') 
                AND target_id = '309f3f29-aeea-4f26-a936-8d65047dc469')
               OR (requester_id = '309f3f29-aeea-4f26-a936-8d65047dc469' 
                   AND target_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9')))
        AND status = 'accepted'
    ) as friendship_exists;

-- Step 4: Show ALL William's current friends
SELECT 
    'Step 4 - All William friends' as step,
    fr.id,
    fr.requester_id,
    fr.target_id,
    CASE 
        WHEN fr.requester_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9') 
        THEN u2.name 
        ELSE u1.name 
    END as friend_name,
    CASE 
        WHEN fr.requester_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9') 
        THEN u2.username 
        ELSE u1.username 
    END as friend_username,
    fr.status,
    fr.created_at
FROM friend_requests fr
JOIN users u1 ON fr.requester_id = u1.id
JOIN users u2 ON fr.target_id = u2.id
WHERE (fr.requester_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9') 
       OR fr.target_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'))
AND fr.status = 'accepted'
ORDER BY fr.created_at DESC;

-- Step 5: Test removing Tracey specifically
SELECT 
    'Step 5 - Remove Tracey result' as step,
    remove_friend_by_internal_id('ee11bb62-0684-4293-a77a-d385c9a070f9', '309f3f29-aeea-4f26-a936-8d65047dc469') as result;
