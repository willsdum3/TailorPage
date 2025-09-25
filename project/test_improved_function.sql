-- Test the improved remove_friend_by_internal_id function with Tracey Beaker

-- Test the function with Tracey Beaker
SELECT 
    'Improved Function Test' as test_type,
    remove_friend_by_internal_id(
        'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,
        '309f3f29-aeea-4f26-a936-8d65047dc469'::UUID
    ) as result;

-- Check if the friendship still exists after the test
SELECT 
    'Friendship After Test' as test_type,
    fr.id,
    fr.requester_id,
    fr.target_id,
    fr.status,
    u1.name as requester_name,
    u2.name as target_name
FROM friend_requests fr
JOIN users u1 ON fr.requester_id = u1.id
JOIN users u2 ON fr.target_id = u2.id
WHERE ((fr.requester_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9') 
        AND fr.target_id = '309f3f29-aeea-4f26-a936-8d65047dc469') OR 
       (fr.requester_id = '309f3f29-aeea-4f26-a936-8d65047dc469' 
        AND fr.target_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9')))
AND fr.status = 'accepted';
