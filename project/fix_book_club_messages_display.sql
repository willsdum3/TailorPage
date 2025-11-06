-- Fix Book Club Messages Display
-- This script updates the get_book_club_messages function to include avatar_url
-- and ensures proper field names for message display

-- ===========================================
-- STEP 1: DROP EXISTING FUNCTION
-- ===========================================

DROP FUNCTION IF EXISTS get_book_club_messages(UUID, UUID);

-- ===========================================
-- STEP 2: CREATE UPDATED FUNCTION WITH AVATAR_URL
-- ===========================================

-- Get book club messages function with avatar_url
CREATE OR REPLACE FUNCTION get_book_club_messages(
    p_auth_user_id UUID,
    p_club_id UUID
)
RETURNS TABLE(
    id UUID,
    user_id UUID,
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    user_name TEXT,
    user_username TEXT,
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
    
    -- Return messages with user details including avatar_url
    RETURN QUERY
    SELECT 
        bcm.id,
        bcm.user_id,
        bcm.message,
        bcm.created_at,
        u.name AS user_name,
        u.username AS user_username,
        u.avatar_url AS avatar_url
    FROM book_club_messages bcm
    JOIN users u ON bcm.user_id = u.id
    WHERE bcm.club_id = p_club_id
    ORDER BY bcm.created_at ASC;  -- Changed to ASC so newest messages appear at bottom
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- STEP 3: GRANT PERMISSIONS
-- ===========================================

GRANT EXECUTE ON FUNCTION get_book_club_messages(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_book_club_messages(UUID, UUID) TO anon;

SELECT '=== BOOK CLUB MESSAGES DISPLAY FUNCTION UPDATED ===' as header;


