-- Comprehensive diagnostic and fix for membership UI mismatch
-- This addresses both Pauline's admin status and William's membership display issues

-- First, let's get a complete picture of the current state
SELECT 
    'Current Club State' as check_type,
    bc.id as club_id,
    bc.name as club_name,
    bc.creator_id,
    u_creator.username as creator_username,
    u_creator.name as creator_name
FROM book_clubs bc
LEFT JOIN users u_creator ON bc.creator_id = u_creator.id
WHERE bc.id = 'b2391fc3-cd68-472d-a9a8-10c4353af145'::UUID;

-- Check all current members and their roles
SELECT 
    'Current Members' as check_type,
    bcm.club_id,
    bc.name as club_name,
    bcm.user_id,
    u.username,
    u.name,
    bcm.role,
    bcm.joined_at,
    CASE 
        WHEN bc.creator_id = bcm.user_id THEN 'CREATOR'
        ELSE 'REGULAR_MEMBER'
    END as creator_status
FROM book_club_members bcm
JOIN book_clubs bc ON bcm.club_id = bc.id
JOIN users u ON bcm.user_id = u.id
WHERE bcm.club_id = 'b2391fc3-cd68-472d-a9a8-10c4353af145'::UUID
ORDER BY 
    CASE 
        WHEN bc.creator_id = bcm.user_id THEN 1
        WHEN bcm.role = 'admin' THEN 2
        WHEN bcm.role = 'member' THEN 3
        ELSE 4
    END,
    bcm.joined_at;

-- Check if Pauline Dumbili exists and get her details
SELECT 
    'Pauline Dumbili Check' as check_type,
    id,
    auth_user_id,
    username,
    name,
    email
FROM users
WHERE username = 'paulinedumbili6';

-- Check if William Dumbili exists and get his details
SELECT 
    'William Dumbili Check' as check_type,
    id,
    auth_user_id,
    username,
    name,
    email
FROM users
WHERE username = 'hereistand';

-- Check if Pauline is actually a member of the club
SELECT 
    'Pauline Membership Check' as check_type,
    bcm.club_id,
    bcm.user_id,
    bcm.role,
    bcm.joined_at,
    u.username,
    u.name
FROM book_club_members bcm
JOIN users u ON bcm.user_id = u.id
WHERE bcm.club_id = 'b2391fc3-cd68-472d-a9a8-10c4353af145'::UUID
AND u.username = 'paulinedumbili6';

-- Check if William is actually a member of the club
SELECT 
    'William Membership Check' as check_type,
    bcm.club_id,
    bcm.user_id,
    bcm.role,
    bcm.joined_at,
    u.username,
    u.name
FROM book_club_members bcm
JOIN users u ON bcm.user_id = u.id
WHERE bcm.club_id = 'b2391fc3-cd68-472d-a9a8-10c4353af145'::UUID
AND u.username = 'hereistand';

-- Now let's fix the issues:

-- 1. Ensure Pauline Dumbili is properly set as creator and admin
-- First, get Pauline's user ID
DO $$
DECLARE
    pauline_user_id UUID;
    pauline_auth_user_id UUID;
    club_id UUID := 'b2391fc3-cd68-472d-a9a8-10c4353af145'::UUID;
BEGIN
    -- Get Pauline's user ID
    SELECT id, auth_user_id INTO pauline_user_id, pauline_auth_user_id
    FROM users
    WHERE username = 'paulinedumbili6';
    
    IF pauline_user_id IS NOT NULL THEN
        -- Update the club to have Pauline as creator
        UPDATE book_clubs 
        SET creator_id = pauline_user_id
        WHERE id = club_id;
        
        -- Ensure Pauline is a member with admin role
        INSERT INTO book_club_members (club_id, user_id, role, joined_at)
        VALUES (club_id, pauline_user_id, 'admin', NOW())
        ON CONFLICT (club_id, user_id) 
        DO UPDATE SET 
            role = 'admin',
            joined_at = COALESCE(book_club_members.joined_at, NOW());
        
        RAISE NOTICE 'Pauline Dumbili set as creator and admin for club %', club_id;
    ELSE
        RAISE NOTICE 'Pauline Dumbili not found in users table';
    END IF;
END $$;

-- 2. Ensure William Dumbili is properly set as a member
DO $$
DECLARE
    william_user_id UUID;
    william_auth_user_id UUID;
    club_id UUID := 'b2391fc3-cd68-472d-a9a8-10c4353af145'::UUID;
BEGIN
    -- Get William's user ID
    SELECT id, auth_user_id INTO william_user_id, william_auth_user_id
    FROM users
    WHERE username = 'hereistand';
    
    IF william_user_id IS NOT NULL THEN
        -- Ensure William is a member
        INSERT INTO book_club_members (club_id, user_id, role, joined_at)
        VALUES (club_id, william_user_id, 'member', NOW())
        ON CONFLICT (club_id, user_id) 
        DO UPDATE SET 
            role = 'member',
            joined_at = COALESCE(book_club_members.joined_at, NOW());
        
        RAISE NOTICE 'William Dumbili set as member for club %', club_id;
    ELSE
        RAISE NOTICE 'William Dumbili not found in users table';
    END IF;
END $$;

-- 3. Verify the fixes
SELECT 
    'After Fix - Club State' as check_type,
    bc.id as club_id,
    bc.name as club_name,
    bc.creator_id,
    u_creator.username as creator_username,
    u_creator.name as creator_name
FROM book_clubs bc
LEFT JOIN users u_creator ON bc.creator_id = u_creator.id
WHERE bc.id = 'b2391fc3-cd68-472d-a9a8-10c4353af145'::UUID;

SELECT 
    'After Fix - All Members' as check_type,
    bcm.club_id,
    bc.name as club_name,
    bcm.user_id,
    u.username,
    u.name,
    bcm.role,
    bcm.joined_at,
    CASE 
        WHEN bc.creator_id = bcm.user_id THEN 'CREATOR'
        ELSE 'REGULAR_MEMBER'
    END as creator_status
FROM book_club_members bcm
JOIN book_clubs bc ON bcm.club_id = bc.id
JOIN users u ON bcm.user_id = u.id
WHERE bcm.club_id = 'b2391fc3-cd68-472d-a9a8-10c4353af145'::UUID
ORDER BY 
    CASE 
        WHEN bc.creator_id = bcm.user_id THEN 1
        WHEN bcm.role = 'admin' THEN 2
        WHEN bcm.role = 'member' THEN 3
        ELSE 4
    END,
    bcm.joined_at;

-- 4. Test the get_book_club_members function to ensure it returns correct data
SELECT 
    'Function Test - Pauline as Admin' as check_type,
    id,
    name,
    username,
    avatar_url,
    role,
    joined_at
FROM get_book_club_members(
    (SELECT auth_user_id FROM users WHERE username = 'paulinedumbili6'),
    'b2391fc3-cd68-472d-a9a8-10c4353af145'::UUID
);

SELECT 
    'Function Test - William as Member' as check_type,
    id,
    name,
    username,
    avatar_url,
    role,
    joined_at
FROM get_book_club_members(
    (SELECT auth_user_id FROM users WHERE username = 'hereistand'),
    'b2391fc3-cd68-472d-a9a8-10c4353af145'::UUID
);

-- 5. Check if there are any duplicate memberships
SELECT 
    'Duplicate Check' as check_type,
    club_id,
    user_id,
    COUNT(*) as duplicate_count
FROM book_club_members
WHERE club_id = 'b2391fc3-cd68-472d-a9a8-10c4353af145'::UUID
GROUP BY club_id, user_id
HAVING COUNT(*) > 1;

-- 6. Check for any orphaned memberships
SELECT 
    'Orphaned Check' as check_type,
    bcm.club_id,
    bcm.user_id,
    bcm.role
FROM book_club_members bcm
LEFT JOIN users u ON bcm.user_id = u.id
WHERE bcm.club_id = 'b2391fc3-cd68-472d-a9a8-10c4353af145'::UUID
AND u.id IS NULL;
