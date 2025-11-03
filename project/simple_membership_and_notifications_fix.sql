-- Simple membership and notifications fix without complex PL/pgSQL blocks
-- This script addresses the remaining problems after fixing creator IDs

-- First, let's check the current state
SELECT 
    'Current State' as check_type,
    (SELECT COUNT(*) FROM users) as user_count,
    (SELECT COUNT(*) FROM book_clubs) as club_count,
    (SELECT COUNT(*) FROM book_club_members) as member_count,
    (SELECT COUNT(*) FROM discussions) as discussion_count,
    (SELECT COUNT(*) FROM discussion_members) as discussion_member_count;

-- Check if clubs now have valid creators
SELECT 
    'Club Creator Status' as check_type,
    bc.id as club_id,
    bc.name as club_name,
    bc.creator_id,
    u.name as creator_name,
    u.username as creator_username
FROM book_clubs bc
LEFT JOIN users u ON bc.creator_id = u.id
ORDER BY bc.name;

-- Check if creators are admin members
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

-- Ensure all creators are admin members
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

-- Check the notifications table structure
SELECT 
    'Notifications Table Structure' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'notifications' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check if there are any check constraints on notifications table
SELECT 
    'Notifications Constraints' as check_type,
    tc.constraint_name,
    tc.constraint_type,
    cc.check_clause
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.check_constraints cc ON tc.constraint_name = cc.constraint_name
WHERE tc.table_name = 'notifications' 
AND tc.table_schema = 'public'
AND tc.constraint_type = 'CHECK';

-- Let's check if the notification functions exist and work
SELECT 
    'Notification Functions' as check_type,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name LIKE '%notification%'
ORDER BY routine_name;

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

-- Let's check if there are any existing memberships
SELECT 
    'Current Memberships' as check_type,
    bc.id as club_id,
    bc.name as club_name,
    COUNT(bcm.user_id) as member_count,
    string_agg(u.name || ' (' || bcm.role || ')', ', ') as member_details
FROM book_clubs bc
LEFT JOIN book_club_members bcm ON bc.id = bcm.club_id
LEFT JOIN users u ON bcm.user_id = u.id
GROUP BY bc.id, bc.name
ORDER BY bc.name;

-- Let's check if there are any existing discussion memberships
SELECT 
    'Current Discussion Memberships' as check_type,
    d.id as discussion_id,
    d.title as discussion_title,
    COUNT(dm.user_id) as member_count,
    string_agg(u.name || ' (' || dm.role || ')', ', ') as member_details
FROM discussions d
LEFT JOIN discussion_members dm ON d.id = dm.discussion_id
LEFT JOIN users u ON dm.user_id = u.id
GROUP BY d.id, d.title
ORDER BY d.title;

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














