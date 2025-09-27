-- Test to see what's actually in the blocked_users table
-- and what IDs we're working with

-- Check current blocked users with all relevant IDs
SELECT 
    'Current Blocked Users Data' as info,
    bu.id as blocking_relationship_id,
    bu.blocker_id as blocker_internal_id,
    bu.blocked_id as blocked_internal_id,
    blocker.name as blocker_name,
    blocker.auth_user_id as blocker_auth_id,
    blocked.name as blocked_name,
    blocked.auth_user_id as blocked_auth_id,
    bu.created_at
FROM blocked_users bu
JOIN users blocker ON bu.blocker_id = blocker.id
JOIN users blocked ON bu.blocked_id = blocked.id
ORDER BY bu.created_at DESC;

-- Check if the specific user ID exists anywhere
SELECT 
    'User ID Search' as info,
    id as internal_id,
    auth_user_id,
    name,
    username
FROM users 
WHERE id::TEXT = '0bcb64b6-0777-444d-9b3c-5d61a1434471'
   OR auth_user_id::TEXT = '0bcb64b6-0777-444d-9b3c-5d61a1434471';

-- Check what the get_blocked_users function returns
SELECT 
    'get_blocked_users Output' as info,
    *
FROM get_blocked_users('4016845f-fb86-4f3b-be24-052855a7adec'::UUID);
