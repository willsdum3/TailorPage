-- Fix Get Discussion Messages Function
-- This script creates the missing get_discussion_messages database function
-- that allows users to view messages in discussions

-- ===========================================
-- STEP 1: DROP EXISTING FUNCTION (if any)
-- ===========================================

DROP FUNCTION IF EXISTS get_discussion_messages(UUID, UUID, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS get_discussion_messages(UUID, UUID, INTEGER);
DROP FUNCTION IF EXISTS get_discussion_messages(UUID, UUID);

-- ===========================================
-- STEP 2: CREATE GET_DISCUSSION_MESSAGES FUNCTION
-- ===========================================

-- Get discussion messages function that matches what the frontend expects
CREATE OR REPLACE FUNCTION get_discussion_messages(
    auth_user_id UUID,
    p_discussion_id UUID,
    limit_count INTEGER DEFAULT 50,
    offset_count INTEGER DEFAULT 0
)
RETURNS TABLE(
    id UUID,
    user_id UUID,
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    user_name TEXT,
    user_username TEXT,
    user_image_url TEXT,
    is_edited BOOLEAN
) AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if user is a member of the discussion
    IF NOT EXISTS (
        SELECT 1 FROM discussion_members dm
        WHERE dm.discussion_id = p_discussion_id 
        AND dm.user_id = user_internal_id
    ) THEN
        RAISE EXCEPTION 'User is not a member of this discussion';
    END IF;
    
    -- Return discussion messages with user details
    RETURN QUERY
    SELECT 
        dm.id,
        dm.user_id,
        dm.message,
        dm.created_at,
        COALESCE(u.name, 'User') AS user_name,
        u.username AS user_username,
        u.avatar_url AS user_image_url,
        FALSE AS is_edited  -- Default to false, can be updated if edit tracking is added
    FROM discussion_messages dm
    JOIN users u ON dm.user_id = u.id
    WHERE dm.discussion_id = p_discussion_id
    ORDER BY dm.created_at ASC  -- Order by oldest first (newest at bottom for chat UI)
    LIMIT limit_count
    OFFSET offset_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- STEP 3: GRANT PERMISSIONS
-- ===========================================

GRANT EXECUTE ON FUNCTION get_discussion_messages(UUID, UUID, INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_discussion_messages(UUID, UUID, INTEGER, INTEGER) TO anon;

-- ===========================================
-- STEP 4: VERIFY FUNCTION CREATION
-- ===========================================

SELECT 
    '=== GET_DISCUSSION_MESSAGES FUNCTION CREATED ===' as header,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name = 'get_discussion_messages';

SELECT '=== GET_DISCUSSION_MESSAGES FUNCTION FIX COMPLETE ===' as header;

