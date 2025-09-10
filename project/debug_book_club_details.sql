-- Debug script to check book club details function
-- This will help identify why the function is not returning data

-- First, let's check if the function exists and what it returns
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_name = 'get_book_club_details';

-- Let's also check what book clubs exist
SELECT 
    id,
    name,
    description,
    is_public,
    created_by
FROM book_clubs 
ORDER BY created_at DESC 
LIMIT 5;

-- Let's check what users exist
SELECT 
    id,
    auth_user_id,
    username,
    name
FROM users 
ORDER BY created_at DESC 
LIMIT 5;

-- Let's check club memberships
SELECT 
    cm.club_id,
    bc.name as club_name,
    cm.user_id,
    u.username,
    cm.role
FROM club_memberships cm
JOIN book_clubs bc ON cm.club_id = bc.id
JOIN users u ON cm.user_id = u.id
ORDER BY bc.created_at DESC 
LIMIT 10;
