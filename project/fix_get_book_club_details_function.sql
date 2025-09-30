-- Fix the get_book_club_details function that determines isMember status
-- This addresses William's "Join Club" button showing instead of "Leave Club"

-- First, let's check if the function exists and what it returns
SELECT 
    'Function Existence Check' as check_type,
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name = 'get_book_club_details';

-- Drop the existing function first to avoid return type conflicts
DROP FUNCTION IF EXISTS get_book_club_details(UUID, UUID);

-- Create the function with correct return type
CREATE OR REPLACE FUNCTION get_book_club_details(
    auth_user_id UUID,
    club_id_param UUID
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    current_book_title TEXT,
    current_book_author TEXT,
    max_members INTEGER,
    is_public BOOLEAN,
    target_personality_traits TEXT[],
    tags TEXT[],
    meeting_info TEXT,
    created_by UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    is_member BOOLEAN,
    user_role TEXT,
    creator_name TEXT,
    member_count BIGINT
) AS $$
BEGIN
    -- Return club details with membership information
    RETURN QUERY
    SELECT 
        bc.id,
        bc.name,
        bc.description,
        bc.current_book_title,
        bc.current_book_author,
        bc.max_members,
        bc.is_public,
        bc.target_personality_traits,
        bc.tags,
        bc.meeting_info,
        bc.created_by,
        bc.created_at,
        -- Check if the user is a member
        EXISTS (
            SELECT 1 FROM book_club_members bcm
            JOIN users u ON bcm.user_id = u.id
            WHERE u.auth_user_id = get_book_club_details.auth_user_id
            AND bcm.club_id = get_book_club_details.club_id_param
        ) as is_member,
        -- Get the user's role in the club
        COALESCE((
            SELECT bcm.role FROM book_club_members bcm
            JOIN users u ON bcm.user_id = u.id
            WHERE u.auth_user_id = get_book_club_details.auth_user_id
            AND bcm.club_id = get_book_club_details.club_id_param
        ), '') as user_role,
        -- Get creator name
        COALESCE((
            SELECT u.name FROM users u
            WHERE u.id = bc.created_by
        ), 'Unknown') as creator_name,
        -- Get member count
        (SELECT COUNT(*) FROM book_club_members WHERE club_id = get_book_club_details.club_id_param) as member_count
    FROM book_clubs bc
    WHERE bc.id = get_book_club_details.club_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the function with William Dumbili and the yjgbbu club
SELECT 
    'Test get_book_club_details Function - William' as check_type,
    id,
    name,
    description,
    is_member,
    user_role,
    creator_name,
    member_count
FROM get_book_club_details(
    'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,  -- William Dumbili's auth_user_id
    'b2391fc3-cd68-472d-a9a8-10c4353af145'::UUID   -- yjgbbu club ID
);

-- Test the function with Pauline Dumbili and the yjgbbu club
SELECT 
    'Test get_book_club_details Function - Pauline' as check_type,
    id,
    name,
    description,
    is_member,
    user_role,
    creator_name,
    member_count
FROM get_book_club_details(
    '4016845f-fb86-4f3b-be24-052855a7adec'::UUID,  -- Pauline Dumbili's auth_user_id
    'b2391fc3-cd68-472d-a9a8-10c4353af145'::UUID   -- yjgbbu club ID
);

-- Test the function with Tracey Beaker and the yjgbbu club
SELECT 
    'Test get_book_club_details Function - Tracey' as check_type,
    id,
    name,
    description,
    is_member,
    user_role,
    creator_name,
    member_count
FROM get_book_club_details(
    'ca692e7f-6522-4295-86cd-592d7fd754b5'::UUID,  -- Tracey Beaker's auth_user_id
    'b2391fc3-cd68-472d-a9a8-10c4353af145'::UUID   -- yjgbbu club ID
);

-- Let's also verify the membership data directly
SELECT 
    'Direct Membership Check' as check_type,
    bcm.club_id,
    bcm.user_id,
    bcm.role,
    u.username,
    u.name,
    u.auth_user_id
FROM book_club_members bcm
JOIN users u ON bcm.user_id = u.id
WHERE bcm.club_id = 'b2391fc3-cd68-472d-a9a8-10c4353af145'::UUID
ORDER BY bcm.role, u.username;
