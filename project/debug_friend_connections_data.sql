-- Debug the friend connections data structure to understand what friend_id contains
-- This will help us fix the ID conversion issues

-- Test the get_friend_connections function and see what it returns
SELECT 
    'Friend Connections Data' as test_type,
    fc.id,
    fc.friend_id,
    fc.friend_name,
    fc.friend_username,
    fc.status
FROM get_friend_connections('ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID) fc;

-- Check if friend_id from the function matches internal IDs or auth_user_ids
SELECT 
    'ID Type Check' as test_type,
    fc.friend_id,
    u.id as internal_id,
    u.auth_user_id,
    CASE 
        WHEN fc.friend_id = u.id THEN 'friend_id is INTERNAL ID'
        WHEN fc.friend_id = u.auth_user_id THEN 'friend_id is AUTH USER ID'
        ELSE 'friend_id is NEITHER'
    END as id_type
FROM get_friend_connections('ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID) fc
LEFT JOIN users u ON (fc.friend_id = u.id OR fc.friend_id = u.auth_user_id)
WHERE fc.status = 'accepted';
