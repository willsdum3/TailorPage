-- Fix Book Club Members Display
-- This script updates the get_book_club_members function to include avatar_url
-- and ensures proper field names for member display

-- ===========================================
-- STEP 1: DROP EXISTING FUNCTION
-- ===========================================

DROP FUNCTION IF EXISTS get_book_club_members(UUID, UUID);

-- ===========================================
-- STEP 2: CREATE UPDATED FUNCTION WITH AVATAR_URL
-- ===========================================

-- Get book club members function with avatar_url
CREATE OR REPLACE FUNCTION get_book_club_members(
    p_auth_user_id UUID,
    p_club_id UUID
)
RETURNS TABLE(
    id UUID,
    user_id UUID,
    role TEXT,
    joined_at TIMESTAMP WITH TIME ZONE,
    user_name TEXT,
    user_username TEXT,
    user_email TEXT,
    avatar_url TEXT
) AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(p_auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if user is a member of the club
    IF NOT EXISTS (
        SELECT 1 FROM book_club_members bcm
        WHERE bcm.club_id = p_club_id 
        AND bcm.user_id = user_internal_id
    ) THEN
        RAISE EXCEPTION 'User is not a member of this club';
    END IF;
    
    -- Return club members with user details including avatar_url
    RETURN QUERY
    SELECT 
        bcm.id,
        bcm.user_id,
        bcm.role,
        bcm.joined_at,
        u.name AS user_name,
        u.username AS user_username,
        u.email AS user_email,
        u.avatar_url AS avatar_url
    FROM book_club_members bcm
    JOIN users u ON bcm.user_id = u.id
    WHERE bcm.club_id = p_club_id
    ORDER BY 
        CASE 
            WHEN bcm.role = 'admin' OR bcm.role = 'owner' THEN 1
            WHEN bcm.role = 'member' THEN 2
            ELSE 3
        END,
        bcm.joined_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- STEP 3: GRANT PERMISSIONS
-- ===========================================

GRANT EXECUTE ON FUNCTION get_book_club_members(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_book_club_members(UUID, UUID) TO anon;

SELECT '=== BOOK CLUB MEMBERS DISPLAY FUNCTION UPDATED ===' as header;

