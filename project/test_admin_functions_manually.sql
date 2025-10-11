-- Manual tests for admin functions with actual data
-- This will help us see what's failing

-- First, let's get some real user and club data to test with
SELECT 
    'Available Users' as check_type,
    id as internal_id,
    auth_user_id,
    username,
    name
FROM users
ORDER BY username;

SELECT 
    'Available Book Clubs' as check_type,
    bc.id as club_id,
    bc.name as club_name,
    u.username as creator_username,
    u.name as creator_name
FROM book_clubs bc
LEFT JOIN users u ON bc.created_by = u.id
ORDER BY bc.created_at DESC;

SELECT 
    'Book Club Memberships' as check_type,
    bc.name as club_name,
    u.username,
    u.name,
    bcm.role
FROM book_club_members bcm
JOIN book_clubs bc ON bcm.club_id = bc.id
JOIN users u ON bcm.user_id = u.id
ORDER BY bc.name, bcm.role, u.username;

-- Now let's test each admin function with real data
-- Replace these UUIDs with actual values from your database

-- Test 1: Promote user to admin (use a real admin and a real member)
-- This is a READ-ONLY test that will fail gracefully if the user is already admin
SELECT 
    'Test 1: Promote User (This will fail if already admin or not a member)' as test_name,
    promote_user_to_admin(
        (SELECT auth_user_id FROM users WHERE username = 'hereistand'),  -- William as admin
        (SELECT id FROM book_clubs WHERE name LIKE '%' LIMIT 1),  -- First club
        (SELECT id FROM users WHERE username = 'vaseline22')  -- Tracey to promote
    ) as result;

-- Test 2: Invite user to club (use a real admin and a user not in the club)
SELECT 
    'Test 2: Invite User (This will fail if user already invited or is member)' as test_name,
    invite_user_to_club(
        (SELECT auth_user_id FROM users WHERE username = 'hereistand'),  -- William as admin
        (SELECT id FROM book_clubs WHERE name LIKE '%' LIMIT 1),  -- First club
        'paulinedumbili6',  -- Pauline to invite
        'Welcome!'
    ) as result;

-- Test 3: Check if functions return proper error messages for non-admins
SELECT 
    'Test 3: Non-Admin Trying to Promote (Should fail with permission error)' as test_name,
    promote_user_to_admin(
        (SELECT auth_user_id FROM users WHERE username = 'paulinedumbili6'),  -- Pauline (not admin)
        (SELECT id FROM book_clubs WHERE name LIKE '%' LIMIT 1),  -- First club
        (SELECT id FROM users WHERE username = 'vaseline22')  -- Tracey
    ) as result;

-- Check the functions' return types
SELECT 
    'Function Return Types' as check_type,
    routine_name,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name IN ('promote_user_to_admin', 'invite_user_to_club', 'delete_book_club')
ORDER BY routine_name;

