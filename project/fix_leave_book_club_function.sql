-- Fix the leave_book_club function that allows users to leave book clubs
-- The frontend sends: auth_user_id, club_id

-- First, let's check if the function exists
SELECT 
    'Function Existence Check' as check_type,
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name = 'leave_book_club';

-- Let's also check the function parameters if it exists
SELECT 
    'Function Parameters Check' as check_type,
    parameter_name,
    data_type,
    parameter_mode
FROM information_schema.parameters 
WHERE specific_schema = 'public'
AND specific_name IN (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_schema = 'public' 
    AND routine_name = 'leave_book_club'
)
ORDER BY ordinal_position;

-- Drop the existing function first to avoid conflicts
DROP FUNCTION IF EXISTS leave_book_club(UUID, UUID);

-- Create the function with correct parameters matching the frontend
CREATE OR REPLACE FUNCTION leave_book_club(
    auth_user_id UUID,
    club_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    user_internal_id UUID;
    membership_exists BOOLEAN;
BEGIN
    -- Get the internal user ID from auth_user_id
    SELECT id INTO user_internal_id
    FROM users
    WHERE users.auth_user_id = leave_book_club.auth_user_id;
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if the user is a member of the club
    SELECT EXISTS (
        SELECT 1 FROM book_club_members 
        WHERE book_club_members.user_id = user_internal_id 
        AND book_club_members.club_id = leave_book_club.club_id
    ) INTO membership_exists;
    
    IF NOT membership_exists THEN
        RAISE EXCEPTION 'User is not a member of this club';
    END IF;
    
    -- Remove the user from the club
    DELETE FROM book_club_members 
    WHERE book_club_members.user_id = user_internal_id 
    AND book_club_members.club_id = leave_book_club.club_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the function with William Dumbili and the yjgbbu club
-- First, let's check if William is currently a member
SELECT 
    'Check William Membership Before Test' as check_type,
    bcm.club_id,
    bcm.user_id,
    bcm.role,
    u.username,
    u.name,
    bc.name as club_name
FROM book_club_members bcm
JOIN users u ON bcm.user_id = u.id
JOIN book_clubs bc ON bcm.club_id = bc.id
WHERE u.username = 'hereistand'
AND bc.name = 'yjgbbu';

-- Test the function (this will remove William from the club)
SELECT 
    'Test leave_book_club Function' as check_type,
    leave_book_club(
        'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,  -- William Dumbili's auth_user_id
        'b2391fc3-cd68-472d-a9a8-10c4353af145'::UUID   -- yjgbbu club ID
    ) as result;

-- Check if William was removed from the club
SELECT 
    'Check William Membership After Test' as check_type,
    bcm.club_id,
    bcm.user_id,
    bcm.role,
    u.username,
    u.name,
    bc.name as club_name
FROM book_club_members bcm
JOIN users u ON bcm.user_id = u.id
JOIN book_clubs bc ON bcm.club_id = bc.id
WHERE u.username = 'hereistand'
AND bc.name = 'yjgbbu';

-- Add William back to the club for testing purposes
INSERT INTO book_club_members (club_id, user_id, role, joined_at)
VALUES (
    'b2391fc3-cd68-472d-a9a8-10c4353af145'::UUID,  -- yjgbbu club ID
    (SELECT id FROM users WHERE username = 'hereistand'),  -- William's internal ID
    'member',
    NOW()
) ON CONFLICT (club_id, user_id) DO NOTHING;

-- Verify William is back in the club
SELECT 
    'Verify William Back in Club' as check_type,
    bcm.club_id,
    bcm.user_id,
    bcm.role,
    u.username,
    u.name,
    bc.name as club_name
FROM book_club_members bcm
JOIN users u ON bcm.user_id = u.id
JOIN book_clubs bc ON bcm.club_id = bc.id
WHERE u.username = 'hereistand'
AND bc.name = 'yjgbbu';














