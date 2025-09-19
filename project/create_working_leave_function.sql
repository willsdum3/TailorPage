-- =====================================================
-- CREATE WORKING LEAVE FUNCTION
-- =====================================================
-- Simple, bulletproof leave function

-- Drop any existing versions
DROP FUNCTION IF EXISTS leave_discussion(UUID, UUID);

-- Create a simple, working version
CREATE OR REPLACE FUNCTION leave_discussion(
    auth_user_id UUID,
    discussion_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
    is_creator BOOLEAN;
    is_participant BOOLEAN;
    rows_deleted INTEGER;
BEGIN
    -- Get user ID
    SELECT u.id INTO user_uuid FROM users u WHERE u.auth_user_id = leave_discussion.auth_user_id;
    IF user_uuid IS NULL THEN RETURN false; END IF;
    
    -- Check if user is creator (creators cannot leave)
    SELECT EXISTS(
        SELECT 1 FROM discussions d WHERE d.id = discussion_id AND d.created_by = user_uuid
    ) INTO is_creator;
    IF is_creator THEN RETURN false; END IF;
    
    -- Check if user is participant
    SELECT EXISTS(
        SELECT 1 FROM discussion_participants dp 
        WHERE dp.discussion_id = leave_discussion.discussion_id AND dp.user_id = user_uuid
    ) INTO is_participant;
    IF NOT is_participant THEN RETURN false; END IF;
    
    -- Remove user from participants
    DELETE FROM discussion_participants 
    WHERE discussion_id = leave_discussion.discussion_id AND user_id = user_uuid;
    
    GET DIAGNOSTICS rows_deleted = ROW_COUNT;
    RETURN rows_deleted > 0;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION leave_discussion TO authenticated;

-- Test the simple function
SELECT 
    'SIMPLE FUNCTION TEST' as test_name,
    CASE 
        WHEN leave_discussion(
            'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,
            (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)
        ) = true THEN 'SUCCESS - William can now leave!'
        ELSE 'FAILED - Still not working'
    END as result;

-- Verify William was actually removed
SELECT 
    'PARTICIPATION AFTER LEAVE' as test_name,
    CASE 
        WHEN EXISTS(
            SELECT 1 FROM discussion_participants dp
            JOIN users u ON dp.user_id = u.id
            WHERE u.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID
            AND dp.discussion_id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)
        ) THEN 'STILL PARTICIPANT - Function did not remove user'
        ELSE 'NOT PARTICIPANT - Function successfully removed user'
    END as result;

-- Show remaining participants
SELECT 
    'REMAINING PARTICIPANTS' as test_name,
    string_agg(u.name || ' (@' || u.username || ')', ', ') as participants
FROM discussion_participants dp
JOIN users u ON dp.user_id = u.id
WHERE dp.discussion_id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1);
