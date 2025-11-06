-- Fix Get Discussions Participant Status
-- This script ensures the get_discussions function correctly checks if users are participants
-- and that participant status persists after joining

-- ===========================================
-- STEP 1: DROP EXISTING FUNCTION
-- ===========================================

DROP FUNCTION IF EXISTS get_discussions(UUID);

-- ===========================================
-- STEP 2: CREATE UPDATED GET_DISCUSSIONS FUNCTION
-- ===========================================

-- Get discussions function with proper participant status checking
CREATE OR REPLACE FUNCTION get_discussions(
    p_auth_user_id UUID
)
RETURNS TABLE(
    id UUID,
    title TEXT,
    content TEXT,
    book_title TEXT,
    book_author TEXT,
    tags TEXT[],
    created_by UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    participant_count BIGINT,
    last_activity TIMESTAMP WITH TIME ZONE,
    is_participant BOOLEAN,
    creator_name TEXT,
    creator_username TEXT,
    is_created_by_user BOOLEAN
) AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(p_auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Return discussions with accurate participation info
    RETURN QUERY
    SELECT 
        d.id,
        d.title,
        d.content,
        d.book_title,
        d.book_author,
        COALESCE(d.tags, ARRAY[]::TEXT[]) as tags,
        d.created_by,
        d.created_at,
        COALESCE(
            (SELECT COUNT(*)::BIGINT 
             FROM discussion_members dm 
             WHERE dm.discussion_id = d.id), 
            0::BIGINT
        ) as participant_count,
        COALESCE(
            (SELECT MAX(dm.joined_at) 
             FROM discussion_members dm 
             WHERE dm.discussion_id = d.id),
            d.created_at
        ) as last_activity,
        -- Check if current user is a participant using EXISTS for better performance
        EXISTS(
            SELECT 1 
            FROM discussion_members dm2 
            WHERE dm2.discussion_id = d.id 
            AND dm2.user_id = user_internal_id
        ) as is_participant,
        COALESCE(u.name, 'Unknown') as creator_name,
        u.username as creator_username,
        (d.created_by = user_internal_id) as is_created_by_user
    FROM discussions d
    LEFT JOIN users u ON d.created_by = u.id
    ORDER BY d.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- STEP 3: GRANT PERMISSIONS
-- ===========================================

GRANT EXECUTE ON FUNCTION get_discussions(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_discussions(UUID) TO anon;

-- ===========================================
-- STEP 4: VERIFY FUNCTION CREATION
-- ===========================================

SELECT 
    '=== GET_DISCUSSIONS FUNCTION UPDATED ===' as header,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name = 'get_discussions';

-- ===========================================
-- STEP 5: VERIFY DISCUSSION_MEMBERS TABLE STRUCTURE
-- ===========================================

SELECT 
    '=== DISCUSSION_MEMBERS TABLE CHECK ===' as header,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public'
AND table_name = 'discussion_members'
ORDER BY ordinal_position;

SELECT '=== GET_DISCUSSIONS PARTICIPANT STATUS FIX COMPLETE ===' as header;


