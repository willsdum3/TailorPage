-- Debug script using EXACT parameters from frontend
-- This will test the same parameters the frontend is sending

-- Test with EXACT parameters from frontend console logs:
-- authUserId: "ee11bb62-0684-4293-a77a-d385c9a070f9" (William's auth_user_id)
-- friendId: "6a551bb7-3323-42ce-971d-ec4f0f4a6f69" (Kat Slater's internal_id)

-- Step 1: Verify William exists with this auth_user_id
SELECT 
    'Step 1 - William lookup' as step,
    id as william_internal_id,
    name as william_name,
    username as william_username
FROM users 
WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9';

-- Step 2: Verify Kat Slater exists with this internal_id
SELECT 
    'Step 2 - Kat Slater lookup' as step,
    id as kat_internal_id,
    auth_user_id as kat_auth_user_id,
    name as kat_name,
    username as kat_username
FROM users 
WHERE id = '6a551bb7-3323-42ce-971d-ec4f0f4a6f69';

-- Step 3: Check if friendship exists between them
SELECT 
    'Step 3 - Friendship check' as step,
    EXISTS(
        SELECT 1 FROM friend_requests 
        WHERE ((requester_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9') 
                AND target_id = '6a551bb7-3323-42ce-971d-ec4f0f4a6f69')
               OR (requester_id = '6a551bb7-3323-42ce-971d-ec4f0f4a6f69' 
                   AND target_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9')))
        AND status = 'accepted'
    ) as friendship_exists;

-- Step 4: Show ALL friend_requests for these users
SELECT 
    'Step 4 - All friend_requests' as step,
    fr.id,
    fr.requester_id,
    fr.target_id,
    CASE 
        WHEN fr.requester_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9') 
        THEN u2.name 
        ELSE u1.name 
    END as friend_name,
    fr.status,
    fr.created_at
FROM friend_requests fr
JOIN users u1 ON fr.requester_id = u1.id
JOIN users u2 ON fr.target_id = u2.id
WHERE (fr.requester_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9') 
       OR fr.target_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'))
   OR (fr.requester_id = '6a551bb7-3323-42ce-971d-ec4f0f4a6f69' 
       OR fr.target_id = '6a551bb7-3323-42ce-971d-ec4f0f4a6f69')
ORDER BY fr.created_at DESC;

-- Step 5: Test the function with EXACT frontend parameters
SELECT 
    'Step 5 - Function test with frontend params' as step,
    remove_friend_by_internal_id('ee11bb62-0684-4293-a77a-d385c9a070f9', '6a551bb7-3323-42ce-971d-ec4f0f4a6f69') as result;
