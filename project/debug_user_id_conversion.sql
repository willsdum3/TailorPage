-- Debug the user ID conversion issue
-- Check if the internal ID exists and what its auth_user_id is

-- Check if the internal ID exists in the users table
SELECT 
    'Internal ID Check' as test_type,
    id,
    auth_user_id,
    name,
    username
FROM users 
WHERE id = 'df1ec11e-9b78-4fb5-8218-c6fb03320100';

-- Check if the auth_user_id exists in the users table
SELECT 
    'Auth User ID Check' as test_type,
    id,
    auth_user_id,
    name,
    username
FROM users 
WHERE auth_user_id = 'df1ec11e-9b78-4fb5-8218-c6fb03320100';

-- Check all users to see what IDs we have
SELECT 
    'All Users' as test_type,
    id,
    auth_user_id,
    name,
    username
FROM users 
ORDER BY name;
