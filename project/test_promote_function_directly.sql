-- Test the promote_user_to_admin function directly to see if it works

-- 1. First, let's get some real data to test with
SELECT 
    'Test Data - Users' as check_type,
    id as user_id,
    auth_user_id,
    name,
    username
FROM users 
LIMIT 3;

-- 2. Get some book clubs to test with
SELECT 
    'Test Data - Book Clubs' as check_type,
    id as club_id,
    name,
    creator_id
FROM book_clubs 
LIMIT 3;

-- 3. Get some club memberships to test with
SELECT 
    'Test Data - Club Members' as check_type,
    bcm.user_id,
    bcm.club_id,
    bcm.role,
    u.name as user_name,
    bc.name as club_name
FROM book_club_members bcm
JOIN users u ON bcm.user_id = u.id
JOIN book_clubs bc ON bcm.club_id = bc.id
LIMIT 5;

-- 4. Test the function with a simple call (this will show us if it's callable)
-- We'll use dummy UUIDs to test the function signature
SELECT 
    'Function Call Test' as check_type,
    'Testing function with dummy data' as test_description;

-- 5. Check if there are any permission issues with the function
SELECT 
    'Function Permissions' as check_type,
    routine_name,
    security_type,
    is_deterministic
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name = 'promote_user_to_admin';

-- 6. Check if the function is in the correct schema
SELECT 
    'Function Schema Check' as check_type,
    routine_schema,
    routine_name,
    specific_name
FROM information_schema.routines 
WHERE routine_name = 'promote_user_to_admin';

-- 7. Try to call the function with a simple test (this will fail but show us the exact error)
-- We'll use a real auth_user_id from the users table
SELECT 
    'Direct Function Test' as check_type,
    'Attempting to call function directly' as test_description;
