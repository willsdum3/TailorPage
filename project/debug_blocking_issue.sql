-- Debug script to check blocking functionality
-- This will help us understand why the blocking is failing

-- Check if the user exists in the database
SELECT 
    'User Lookup' as check_type,
    id,
    auth_user_id,
    name,
    username
FROM users 
WHERE id = '309f3f29-aeea-4f26-a936-8d65047dc469'
   OR auth_user_id = '309f3f29-aeea-4f26-a936-8d65047dc469';

-- Check if the current user exists
SELECT 
    'Current User Lookup' as check_type,
    id,
    auth_user_id,
    name,
    username
FROM users 
WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9';

-- Check if there are any existing blocked relationships
SELECT 
    'Existing Blocks' as check_type,
    bu.id,
    bu.blocker_id,
    bu.blocked_id,
    blocker.name as blocker_name,
    blocked.name as blocked_name
FROM blocked_users bu
JOIN users blocker ON bu.blocker_id = blocker.id
JOIN users blocked ON bu.blocked_id = blocked.id
WHERE blocker.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'
   OR blocked.auth_user_id = '309f3f29-aeea-4f26-a936-8d65047dc469';

-- Test the blocking function directly
SELECT 
    'Direct Function Test' as check_type,
    block_friend_with_removal(
        'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,
        '309f3f29-aeea-4f26-a936-8d65047dc469'::UUID
    ) as result;

-- Check all users to see what IDs we have
SELECT 
    'All Users' as check_type,
    id,
    auth_user_id,
    name,
    username
FROM users 
ORDER BY created_at DESC
LIMIT 10;
