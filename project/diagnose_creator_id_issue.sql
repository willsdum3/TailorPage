-- Diagnose the creator_id issue in book_clubs table
-- This script will help us understand why some creator_id values are null or invalid

-- Check book_clubs table structure and data
SELECT 
    'book_clubs table structure' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'book_clubs' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check for null creator_id values
SELECT 
    'null_creator_ids' as check_type,
    COUNT(*) as count
FROM book_clubs 
WHERE creator_id IS NULL;

-- Check for creator_id values that don't exist in users table
SELECT 
    'invalid_creator_ids' as check_type,
    bc.id as club_id,
    bc.name as club_name,
    bc.creator_id,
    CASE 
        WHEN u.id IS NULL THEN 'NOT FOUND IN USERS TABLE'
        ELSE 'FOUND IN USERS TABLE'
    END as status
FROM book_clubs bc
LEFT JOIN users u ON bc.creator_id = u.id
WHERE bc.creator_id IS NOT NULL
ORDER BY status, bc.name;

-- Check users table structure
SELECT 
    'users table structure' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Sample of users table data
SELECT 
    'sample_users' as check_type,
    id,
    name,
    username,
    auth_user_id
FROM users 
LIMIT 5;

-- Sample of book_clubs table data
SELECT 
    'sample_book_clubs' as check_type,
    id,
    name,
    creator_id,
    created_at
FROM book_clubs 
LIMIT 5;

-- Check if there are any book_club_members already
SELECT 
    'existing_book_club_members' as check_type,
    COUNT(*) as count
FROM book_club_members;

-- Check for any existing admin members
SELECT 
    'existing_admin_members' as check_type,
    COUNT(*) as count
FROM book_club_members 
WHERE role = 'admin';
