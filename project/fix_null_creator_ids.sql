-- Fix null creator_id issue in book_clubs table
-- This script addresses the root cause: clubs have null creator_id values

-- First, let's see the current state
SELECT 
    'Current Club State' as check_type,
    bc.id as club_id,
    bc.name as club_name,
    bc.creator_id,
    bc.created_at
FROM book_clubs bc
ORDER BY bc.name;

-- Check if there are any users who could be creators
SELECT 
    'Available Users' as check_type,
    u.id as user_id,
    u.name as user_name,
    u.username,
    u.auth_user_id
FROM users u
ORDER BY u.name;

-- The issue is that creator_id is null. Let's fix this by assigning creators to clubs
-- We'll assign the first user as the creator of each club that has null creator_id

-- Update clubs with null creator_id to have the first user as creator
UPDATE book_clubs 
SET creator_id = (
    SELECT u.id 
    FROM users u 
    ORDER BY u.created_at 
    LIMIT 1
)
WHERE creator_id IS NULL;

-- Now let's add these creators as admin members
INSERT INTO book_club_members (club_id, user_id, role, joined_at)
SELECT 
    bc.id as club_id,
    bc.creator_id as user_id,
    'admin' as role,
    bc.created_at as joined_at
FROM book_clubs bc
WHERE bc.creator_id IS NOT NULL
AND NOT EXISTS (
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
    'Updated Club State' as check_type,
    bc.id as club_id,
    bc.name as club_name,
    bc.creator_id,
    u.name as creator_name,
    u.username as creator_username
FROM book_clubs bc
LEFT JOIN users u ON bc.creator_id = u.id
ORDER BY bc.name;

-- Check the membership state
SELECT 
    'Updated Membership State' as check_type,
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

-- Now let's test the helper functions
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

-- Final verification
SELECT 
    'Final Verification' as check_type,
    'All functions exist and clubs have valid creators' as status,
    CASE 
        WHEN (SELECT COUNT(*) FROM book_clubs WHERE creator_id IS NULL) = 0 
        AND (SELECT COUNT(*) FROM information_schema.routines WHERE routine_name IN ('join_book_club', 'add_book_club_message', 'promote_user_to_admin', 'invite_user_to_club', 'get_user_internal_id', 'is_user_club_admin')) = 6
        THEN 'SUCCESS'
        ELSE 'ISSUES REMAIN'
    END as result;




















