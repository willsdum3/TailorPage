-- Clean up membership data to fix UI/database mismatch
-- This script will clean up duplicate and orphaned memberships

-- First, let's see what we're working with
SELECT 
    'Before Cleanup - Total Memberships' as check_type,
    COUNT(*) as total_memberships
FROM book_club_members;

-- Remove duplicate memberships (keep the oldest one)
DELETE FROM book_club_members 
WHERE id IN (
    SELECT id FROM (
        SELECT id, 
               ROW_NUMBER() OVER (
                   PARTITION BY club_id, user_id 
                   ORDER BY joined_at ASC
               ) as rn
        FROM book_club_members
    ) t
    WHERE rn > 1
);

-- Remove orphaned memberships (where user doesn't exist)
DELETE FROM book_club_members 
WHERE user_id NOT IN (SELECT id FROM users);

-- Remove orphaned memberships (where club doesn't exist)
DELETE FROM book_club_members 
WHERE club_id NOT IN (SELECT id FROM book_clubs);

-- Check the results
SELECT 
    'After Cleanup - Total Memberships' as check_type,
    COUNT(*) as total_memberships
FROM book_club_members;

-- Show the cleaned up memberships
SELECT 
    'Cleaned Up Memberships' as check_type,
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

-- Specifically check for William Dumbili's memberships after cleanup
SELECT 
    'William Dumbili Memberships After Cleanup' as check_type,
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

-- Check the specific club "yjgbbu" and its members after cleanup
SELECT 
    'yjgbbu Club Members After Cleanup' as check_type,
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








