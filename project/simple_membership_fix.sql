-- Simple membership fix without complex PL/pgSQL blocks
-- This script addresses the core membership creation problems

-- First, let's check the current state of memberships
SELECT 
    'Current Membership State' as check_type,
    (SELECT COUNT(*) FROM users) as user_count,
    (SELECT COUNT(*) FROM book_clubs) as club_count,
    (SELECT COUNT(*) FROM book_club_members) as member_count,
    (SELECT COUNT(*) FROM discussions) as discussion_count,
    (SELECT COUNT(*) FROM discussion_members) as discussion_member_count;

-- Check if users are actually being added as members when they join
SELECT 
    'Club Membership Check' as check_type,
    bc.id as club_id,
    bc.name as club_name,
    bc.creator_id,
    COUNT(bcm.user_id) as member_count,
    string_agg(u.name, ', ') as member_names
FROM book_clubs bc
LEFT JOIN book_club_members bcm ON bc.id = bcm.club_id
LEFT JOIN users u ON bcm.user_id = u.id
GROUP BY bc.id, bc.name, bc.creator_id
ORDER BY bc.name;

-- Check if club creators are admin members
SELECT 
    'Creator Admin Status' as check_type,
    bc.id as club_id,
    bc.name as club_name,
    bc.creator_id,
    u.name as creator_name,
    bcm.role as creator_role,
    CASE 
        WHEN bcm.user_id IS NULL THEN 'NOT A MEMBER'
        WHEN bcm.role = 'admin' THEN 'ADMIN MEMBER'
        ELSE 'MEMBER (NOT ADMIN)'
    END as status
FROM book_clubs bc
LEFT JOIN users u ON bc.creator_id = u.id
LEFT JOIN book_club_members bcm ON bc.id = bcm.club_id AND bc.creator_id = bcm.user_id
ORDER BY bc.name;

-- Let's manually add club creators as admin members if they're missing
INSERT INTO book_club_members (club_id, user_id, role, joined_at)
SELECT 
    bc.id as club_id,
    bc.creator_id as user_id,
    'admin' as role,
    bc.created_at as joined_at
FROM book_clubs bc
JOIN users u ON bc.creator_id = u.id
WHERE NOT EXISTS (
    SELECT 1 FROM book_club_members bcm
    WHERE bcm.club_id = bc.id 
    AND bcm.user_id = bc.creator_id
);

-- Update existing creator members to have admin role
UPDATE book_club_members 
SET role = 'admin'
WHERE user_id IN (
    SELECT bc.creator_id 
    FROM book_clubs bc 
    WHERE bc.creator_id = book_club_members.user_id
    AND bc.id = book_club_members.club_id
)
AND role != 'admin';

-- Check the updated state
SELECT 
    'Updated Membership State' as check_type,
    (SELECT COUNT(*) FROM book_clubs bc
     JOIN book_club_members bcm ON bc.id = bcm.club_id AND bc.creator_id = bcm.user_id) as creator_member_count,
    (SELECT COUNT(*) FROM book_club_members WHERE role = 'admin') as admin_member_count;

-- Test the helper functions to make sure they work
SELECT 
    'Helper Function Test' as check_type,
    'get_user_internal_id' as function_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'get_user_internal_id') 
        THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as status;

SELECT 
    'Helper Function Test' as check_type,
    'is_user_club_admin' as function_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'is_user_club_admin') 
        THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as status;

-- Test the main functions
SELECT 
    'Main Function Test' as check_type,
    'join_book_club' as function_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'join_book_club') 
        THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as status;

SELECT 
    'Main Function Test' as check_type,
    'add_book_club_message' as function_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'add_book_club_message') 
        THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as status;

SELECT 
    'Main Function Test' as check_type,
    'promote_user_to_admin' as function_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'promote_user_to_admin') 
        THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as status;

SELECT 
    'Main Function Test' as check_type,
    'invite_user_to_club' as function_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'invite_user_to_club') 
        THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as status;

-- Final membership check
SELECT 
    'Final Membership Check' as check_type,
    bc.id as club_id,
    bc.name as club_name,
    bc.creator_id,
    COUNT(bcm.user_id) as member_count,
    string_agg(u.name || ' (' || bcm.role || ')', ', ') as member_details
FROM book_clubs bc
LEFT JOIN book_club_members bcm ON bc.id = bcm.club_id
LEFT JOIN users u ON bcm.user_id = u.id
GROUP BY bc.id, bc.name, bc.creator_id
ORDER BY bc.name;

-- Show any notification functions that exist
SELECT 
    'Notification Functions' as check_type,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name LIKE '%notification%'
ORDER BY routine_name;














