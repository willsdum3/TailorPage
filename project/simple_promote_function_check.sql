-- Simple check of promote_user_to_admin function

-- 1. Check if function exists
SELECT 
    'Function Exists' as check_type,
    routine_name,
    specific_name,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name = 'promote_user_to_admin';

-- 2. Check function parameters
SELECT 
    'Function Parameters' as check_type,
    parameter_name,
    data_type,
    ordinal_position
FROM information_schema.parameters 
WHERE specific_schema = 'public'
AND specific_name = 'promote_user_to_admin_94474'
ORDER BY ordinal_position;

-- 3. Get some test users
SELECT 
    'Test Users' as check_type,
    id as user_id,
    auth_user_id,
    name
FROM users 
LIMIT 2;

-- 4. Get some test clubs
SELECT 
    'Test Clubs' as check_type,
    id as club_id,
    name
FROM book_clubs 
LIMIT 2;

-- 5. Check function permissions
SELECT 
    'Function Security' as check_type,
    routine_name,
    security_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name = 'promote_user_to_admin';


















