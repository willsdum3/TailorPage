-- Fix the get_book_club_members function that the frontend is calling
-- This script addresses the UI not showing members correctly

-- First, let's check if the function exists
SELECT 
    'Function Existence Check' as check_type,
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name = 'get_book_club_members';

-- Drop the existing function first to avoid return type conflicts
DROP FUNCTION IF EXISTS get_book_club_members(UUID, UUID);

-- Create the function with correct return type
CREATE OR REPLACE FUNCTION get_book_club_members(
    auth_user_id UUID,
    club_id_param UUID
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    username TEXT,
    avatar_url TEXT,
    role TEXT,
    joined_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    -- Check if the user is a member of the club
    IF NOT EXISTS (
        SELECT 1 FROM book_club_members bcm
        JOIN users u ON bcm.user_id = u.id
        WHERE u.auth_user_id = get_book_club_members.auth_user_id
        AND bcm.club_id = get_book_club_members.club_id_param
    ) THEN
        RAISE EXCEPTION 'User is not a member of this club';
    END IF;
    
    -- Return all members of the club
    RETURN QUERY
    SELECT 
        u.id,
        u.name,
        u.username,
        u.avatar_url,
        bcm.role,
        bcm.joined_at
    FROM book_club_members bcm
    JOIN users u ON bcm.user_id = u.id
    WHERE bcm.club_id = get_book_club_members.club_id_param
    ORDER BY 
        CASE 
            WHEN bcm.role = 'admin' THEN 1
            WHEN bcm.role = 'member' THEN 2
            ELSE 3
        END,
        bcm.joined_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the function with the yjgbbu club
SELECT 
    'Test get_book_club_members Function' as check_type,
    id,
    name,
    username,
    avatar_url,
    role,
    joined_at
FROM get_book_club_members(
    'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,  -- William Dumbili's auth_user_id
    'b2391fc3-cd68-472d-a9a8-10c4353af145'::UUID   -- yjgbbu club ID
);

-- Let's also check what the frontend is actually calling
-- The frontend calls: get_book_club_members(auth_user_id, club_id_param)
-- Let's test with different users to see if it works

-- Test with Tracey Beaker (who is an admin)
SELECT 
    'Test with Tracey Beaker (Admin)' as check_type,
    id,
    name,
    username,
    avatar_url,
    role,
    joined_at
FROM get_book_club_members(
    'ca692e7f-6522-4295-86cd-592d7fd754b5'::UUID,  -- Tracey Beaker's auth_user_id
    'b2391fc3-cd68-472d-a9a8-10c4353af145'::UUID   -- yjgbbu club ID
);

-- Let's also check if there are any issues with the table names
-- The frontend might be looking for 'club_memberships' instead of 'book_club_members'
SELECT 
    'Table Name Check' as check_type,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public'
AND table_name IN ('book_club_members', 'club_memberships')
ORDER BY table_name;

-- Check if there's a club_memberships table that might be causing confusion
SELECT 
    'club_memberships Table Check' as check_type,
    COUNT(*) as record_count
FROM club_memberships;

-- If club_memberships exists, let's see what's in it
SELECT 
    'club_memberships Data' as check_type,
    club_id,
    user_id,
    role,
    joined_at
FROM club_memberships
WHERE club_id = 'b2391fc3-cd68-472d-a9a8-10c4353af145'::UUID
ORDER BY joined_at;
