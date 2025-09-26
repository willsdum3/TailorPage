-- Test blocking functionality with the correct IDs from the debug output
-- William Dumbili (blocker): auth_user_id = ee11bb62-0684-4293-a77a-d385c9a070f9
-- Tracey Beaker (blocked): auth_user_id = ca692e7f-6522-4295-86cd-592d7fd754b5

-- Test the blocking function with correct auth user IDs
SELECT 
    'Test Blocking Function' as test_type,
    block_friend_with_removal(
        'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,  -- William's auth_user_id
        'ca692e7f-6522-4295-86cd-592d7fd754b5'::UUID   -- Tracey's auth_user_id
    ) as result;

-- Check if the blocking was successful
SELECT 
    'Check Blocking Result' as test_type,
    bu.id,
    bu.blocker_id,
    bu.blocked_id,
    blocker.name as blocker_name,
    blocker.auth_user_id as blocker_auth_id,
    blocked.name as blocked_name,
    blocked.auth_user_id as blocked_auth_id,
    bu.created_at
FROM blocked_users bu
JOIN users blocker ON bu.blocker_id = blocker.id
JOIN users blocked ON bu.blocked_id = blocked.id
WHERE blocker.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'
  AND blocked.auth_user_id = 'ca692e7f-6522-4295-86cd-592d7fd754b5';
