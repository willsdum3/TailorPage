-- Debug script to check the users table schema
-- This will help us understand the correct column names

-- Check the structure of the users table
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;

-- Check if there are any existing club_invitations tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_name LIKE '%invitation%';

-- Check the structure of book_club_members table for reference
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'book_club_members' 
ORDER BY ordinal_position;
