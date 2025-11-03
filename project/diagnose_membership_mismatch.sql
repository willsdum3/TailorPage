-- Diagnose membership mismatch between database and UI
-- This script will help us understand why the UI doesn't reflect the actual membership status

-- First, let's check all users and their details
SELECT 
    'All Users' as check_type,
    u.id as user_id,
    u.name as user_name,
    u.username,
    u.auth_user_id
FROM users u
ORDER BY u.name;

-- Check all book clubs and their details
SELECT 
    'All Book Clubs' as check_type,
    bc.id as club_id,
    bc.name as club_name,
    bc.creator_id,
    u.name as creator_name
FROM book_clubs bc
LEFT JOIN users u ON bc.creator_id = u.id
ORDER BY bc.name;

-- Check all book club memberships
SELECT 
    'All Book Club Memberships' as check_type,
    bcm.club_id,
    bc.name as club_name,
    bcm.user_id,
    u.name as user_name,
    u.username,
    bcm.role,
    bcm.joined_at
FROM book_club_members bcm
JOIN book_clubs bc ON bcm.club_id = bc.id
JOIN users u ON bcm.user_id = u.id
ORDER BY bc.name, u.name;

-- Specifically check for William Dumbili's memberships
SELECT 
    'William Dumbili Memberships' as check_type,
    bcm.club_id,
    bc.name as club_name,
    bcm.user_id,
    u.name as user_name,
    u.username,
    bcm.role,
    bcm.joined_at
FROM book_club_members bcm
JOIN book_clubs bc ON bcm.club_id = bc.id
JOIN users u ON bcm.user_id = u.id
WHERE u.username = 'hereistand' OR u.name LIKE '%William%'
ORDER BY bc.name;

-- Check if there are any duplicate memberships
SELECT 
    'Duplicate Memberships Check' as check_type,
    bcm.club_id,
    bc.name as club_name,
    bcm.user_id,
    u.name as user_name,
    u.username,
    COUNT(*) as membership_count
FROM book_club_members bcm
JOIN book_clubs bc ON bcm.club_id = bc.id
JOIN users u ON bcm.user_id = u.id
GROUP BY bcm.club_id, bc.name, bcm.user_id, u.name, u.username
HAVING COUNT(*) > 1
ORDER BY bc.name, u.name;

-- Check the specific club "yjgbbu" and its members
SELECT 
    'yjgbbu Club Members' as check_type,
    bcm.club_id,
    bc.name as club_name,
    bcm.user_id,
    u.name as user_name,
    u.username,
    bcm.role,
    bcm.joined_at
FROM book_club_members bcm
JOIN book_clubs bc ON bcm.club_id = bc.id
JOIN users u ON bcm.user_id = u.id
WHERE bc.name = 'yjgbbu'
ORDER BY u.name;

-- Check if William Dumbili exists in the users table
SELECT 
    'William Dumbili User Check' as check_type,
    u.id as user_id,
    u.name as user_name,
    u.username,
    u.auth_user_id,
    u.created_at
FROM users u
WHERE u.username = 'hereistand' OR u.name LIKE '%William%'
ORDER BY u.name;

-- Check if there are any orphaned memberships (user_id that doesn't exist in users table)
SELECT 
    'Orphaned Memberships' as check_type,
    bcm.club_id,
    bc.name as club_name,
    bcm.user_id,
    bcm.role,
    bcm.joined_at
FROM book_club_members bcm
JOIN book_clubs bc ON bcm.club_id = bc.id
LEFT JOIN users u ON bcm.user_id = u.id
WHERE u.id IS NULL
ORDER BY bc.name;

-- Check if there are any orphaned memberships (club_id that doesn't exist in book_clubs table)
SELECT 
    'Orphaned Club Memberships' as check_type,
    bcm.club_id,
    bcm.user_id,
    u.name as user_name,
    u.username,
    bcm.role,
    bcm.joined_at
FROM book_club_members bcm
LEFT JOIN book_clubs bc ON bcm.club_id = bc.id
LEFT JOIN users u ON bcm.user_id = u.id
WHERE bc.id IS NULL
ORDER BY bcm.club_id;














