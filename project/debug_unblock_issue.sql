-- Debug unblock issue
-- Check the current blocked users and their IDs

-- First, let's see what blocked users exist
SELECT 
    'Current Blocked Users' as info,
    bu.id as blocking_id,
    bu.blocker_id,
    bu.blocked_id,
    blocker.name as blocker_name,
    blocker.username as blocker_username,
    blocker.auth_user_id as blocker_auth_id,
    blocked.name as blocked_name,
    blocked.username as blocked_username,
    blocked.auth_user_id as blocked_auth_id,
    bu.created_at
FROM blocked_users bu
JOIN users blocker ON bu.blocker_id = blocker.id
JOIN users blocked ON bu.blocked_id = blocked.id
ORDER BY bu.created_at DESC;

-- Check if the specific user ID exists in blocked_users
SELECT 
    'Check Specific Blocked User' as info,
    bu.id as blocking_id,
    bu.blocker_id,
    bu.blocked_id,
    blocker.name as blocker_name,
    blocked.name as blocked_name
FROM blocked_users bu
JOIN users blocker ON bu.blocker_id = blocker.id
JOIN users blocked ON bu.blocked_id = blocked.id
WHERE bu.blocked_id = '0bcb64b6-0777-444d-9b3c-5d61a1434471'::UUID;

-- Check if this user exists in the users table at all
SELECT 
    'User Exists Check' as info,
    id,
    auth_user_id,
    name,
    username
FROM users 
WHERE id = '0bcb64b6-0777-444d-9b3c-5d61a1434471'::UUID
   OR auth_user_id = '0bcb64b6-0777-444d-9b3c-5d61a1434471'::UUID;

-- Test the unblock function directly
SELECT 
    'Direct Unblock Test' as info,
    unblock_friend(
        '4016845f-fb86-4f3b-be24-052855a7adec'::UUID,  -- Current user's auth_user_id
        '0bcb64b6-0777-444d-9b3c-5d61a1434471'         -- The ID being passed
    ) as result;
