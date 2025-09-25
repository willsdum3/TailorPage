-- Direct check of the database to see what's actually there

-- Check all users
SELECT 
    'All Users' as check_type,
    id,
    auth_user_id,
    name,
    username
FROM users
ORDER BY name;

-- Check all friend_requests with user names
SELECT 
    'All Friend Requests' as check_type,
    fr.id,
    fr.requester_id,
    fr.target_id,
    fr.status,
    fr.created_at,
    u1.name as requester_name,
    u2.name as target_name
FROM friend_requests fr
LEFT JOIN users u1 ON fr.requester_id = u1.id
LEFT JOIN users u2 ON fr.target_id = u2.id
ORDER BY fr.created_at DESC;

-- Check specifically for William
SELECT 
    'William Check' as check_type,
    id,
    auth_user_id,
    name,
    username
FROM users 
WHERE auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'
   OR name ILIKE '%william%'
   OR username ILIKE '%william%';
