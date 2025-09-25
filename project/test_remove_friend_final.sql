-- Final test for the remove_friend_by_internal_id function
-- This will test with the exact parameters being sent from the frontend

-- Test the function with William's auth_user_id and Tailor Page's internal_id
-- (df1ec11e-9b78-4fb5-8218-c6fb03320100 is Tailor Page's internal ID based on console logs)
SELECT 
    'Final Remove Friend Test' as test_type,
    remove_friend_by_internal_id(
        'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,  -- William's auth_user_id
        'df1ec11e-9b78-4fb5-8218-c6fb03320100'::UUID   -- Tailor Page's internal_id
    ) as result;

-- Check William's current friends after the test
SELECT 
    'William Friends After Test' as test_type,
    fr.id,
    fr.requester_id,
    fr.target_id,
    fr.status,
    u1.name as requester_name,
    u2.name as target_name
FROM friend_requests fr
JOIN users u1 ON fr.requester_id = u1.id
JOIN users u2 ON fr.target_id = u2.id
WHERE fr.requester_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9')
   OR fr.target_id = (SELECT id FROM users WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9');
