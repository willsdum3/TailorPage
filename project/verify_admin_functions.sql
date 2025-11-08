-- Verify that admin functions are working correctly (non-destructive tests)

-- 1. Check if all admin functions exist
SELECT 
    'Admin Functions Existence Check' as check_type,
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name IN ('promote_user_to_admin', 'invite_user_to_club', 'delete_book_club')
ORDER BY routine_name;

-- 2. Check function parameters
SELECT 
    'promote_user_to_admin Parameters' as check_type,
    parameter_name,
    data_type,
    parameter_mode,
    ordinal_position
FROM information_schema.parameters 
WHERE specific_schema = 'public'
AND specific_name IN (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_schema = 'public' 
    AND routine_name = 'promote_user_to_admin'
)
ORDER BY ordinal_position;

SELECT 
    'invite_user_to_club Parameters' as check_type,
    parameter_name,
    data_type,
    parameter_mode,
    ordinal_position
FROM information_schema.parameters 
WHERE specific_schema = 'public'
AND specific_name IN (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_schema = 'public' 
    AND routine_name = 'invite_user_to_club'
)
ORDER BY ordinal_position;

SELECT 
    'delete_book_club Parameters' as check_type,
    parameter_name,
    data_type,
    parameter_mode,
    ordinal_position
FROM information_schema.parameters 
WHERE specific_schema = 'public'
AND specific_name IN (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_schema = 'public' 
    AND routine_name = 'delete_book_club'
)
ORDER BY ordinal_position;

-- 3. Check existing book clubs
SELECT 
    'Existing Book Clubs' as check_type,
    bc.id,
    bc.name,
    bc.description,
    u.username as creator_username,
    u.name as creator_name,
    (SELECT COUNT(*) FROM book_club_members WHERE club_id = bc.id) as member_count
FROM book_clubs bc
LEFT JOIN users u ON bc.created_by = u.id
ORDER BY bc.created_at DESC;

-- 4. Check book club members and their roles
SELECT 
    'Book Club Members and Roles' as check_type,
    bc.name as club_name,
    u.username,
    u.name,
    bcm.role,
    bcm.joined_at
FROM book_club_members bcm
JOIN book_clubs bc ON bcm.club_id = bc.id
JOIN users u ON bcm.user_id = u.id
ORDER BY bc.name, bcm.role, u.username;

-- 5. Check club invitations table
SELECT 
    'Club Invitations Table Check' as check_type,
    COUNT(*) as total_invitations
FROM club_invitations;

-- 6. Check if club_invitations table has the correct structure
SELECT 
    'Club Invitations Table Structure' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'club_invitations'
ORDER BY ordinal_position;




















