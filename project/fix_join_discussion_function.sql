-- Fix Join Discussion Function
-- This script creates the missing join_discussion database function
-- that allows users to join existing discussions

-- ===========================================
-- STEP 1: DROP EXISTING FUNCTION (if any)
-- ===========================================

DROP FUNCTION IF EXISTS join_discussion(UUID, UUID);

-- ===========================================
-- STEP 2: CREATE JOIN_DISCUSSION FUNCTION
-- ===========================================

-- Join discussion function that matches what the frontend expects
CREATE OR REPLACE FUNCTION join_discussion(
    auth_user_id UUID,
    p_discussion_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    user_internal_id UUID;
    discussion_exists BOOLEAN;
    already_member BOOLEAN;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if discussion exists
    SELECT EXISTS(
        SELECT 1 FROM discussions d
        WHERE d.id = p_discussion_id
    ) INTO discussion_exists;
    
    IF NOT discussion_exists THEN
        RAISE EXCEPTION 'Discussion not found';
    END IF;
    
    -- Check if user is already a member
    SELECT EXISTS(
        SELECT 1 FROM discussion_members dm
        WHERE dm.discussion_id = p_discussion_id
        AND dm.user_id = user_internal_id
    ) INTO already_member;
    
    IF already_member THEN
        -- User is already a member, return true (success)
        RETURN TRUE;
    END IF;
    
    -- Add user as member of the discussion
    INSERT INTO discussion_members (
        discussion_id,
        user_id,
        role,
        joined_at
    )
    VALUES (
        p_discussion_id,
        user_internal_id,
        'member',
        NOW()
    )
    ON CONFLICT (discussion_id, user_id) DO NOTHING;
    
    -- Return success
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- STEP 3: GRANT PERMISSIONS
-- ===========================================

GRANT EXECUTE ON FUNCTION join_discussion(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION join_discussion(UUID, UUID) TO anon;

-- ===========================================
-- STEP 4: VERIFY FUNCTION CREATION
-- ===========================================

SELECT 
    '=== JOIN_DISCUSSION FUNCTION CREATED ===' as header,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name = 'join_discussion';

SELECT '=== JOIN_DISCUSSION FUNCTION FIX COMPLETE ===' as header;

