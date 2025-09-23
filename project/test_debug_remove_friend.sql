-- Test the debug remove_friend function
-- First, let's see what friends exist for William Dumbili
SELECT 
    fr.id,
    fr.requester_id,
    fr.target_id,
    u1.name as requester_name,
    u2.name as target_name,
    fr.status
FROM friend_requests fr
JOIN users u1 ON fr.requester_id = u1.id
JOIN users u2 ON fr.target_id = u2.id
WHERE (u1.name = 'William Dumbili' OR u2.name = 'William Dumbili')
AND fr.status = 'accepted'
ORDER BY fr.created_at DESC;

-- Test the debug function with William Dumbili's auth_user_id and Kat Slater's friend_id
-- Replace these UUIDs with actual values from the query above
SELECT debug_remove_friend(
    'ee11bb62-0684-4293-a77a-d385c9a070f9'::uuid,  -- William Dumbili's auth_user_id
    '6a551bb7-3323-42ce-971d-ec4f0f4a6f69'::uuid   -- Kat Slater's friend_id
) as debug_result;
