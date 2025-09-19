-- =====================================================
-- FIX LEAVE FUNCTION FINAL
-- =====================================================
-- Fix the parameter reference issue in DELETE statement

-- Drop the broken function
DROP FUNCTION IF EXISTS leave_discussion(UUID, UUID);

-- Create corrected function with proper parameter references
CREATE OR REPLACE FUNCTION leave_discussion(
    p_auth_user_id UUID,
    p_discussion_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
    is_creator BOOLEAN;
    is_participant BOOLEAN;
    rows_deleted INTEGER;
BEGIN
    -- Get user ID
    SELECT u.id INTO user_uuid FROM users u WHERE u.auth_user_id = p_auth_user_id;
    IF user_uuid IS NULL THEN RETURN false; END IF;
    
    -- Check if user is creator (creators cannot leave)
    SELECT EXISTS(
        SELECT 1 FROM discussions d WHERE d.id = p_discussion_id AND d.created_by = user_uuid
    ) INTO is_creator;
    IF is_creator THEN RETURN false; END IF;
    
    -- Check if user is participant
    SELECT EXISTS(
        SELECT 1 FROM discussion_participants dp 
        WHERE dp.discussion_id = p_discussion_id AND dp.user_id = user_uuid
    ) INTO is_participant;
    IF NOT is_participant THEN RETURN false; END IF;
    
    -- Remove user from participants (using local variables, not function parameters)
    DELETE FROM discussion_participants 
    WHERE discussion_id = p_discussion_id AND user_id = user_uuid;
    
    GET DIAGNOSTICS rows_deleted = ROW_COUNT;
    RETURN rows_deleted > 0;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION leave_discussion TO authenticated;

-- Test the corrected function step by step
-- Step 1: Ensure William is a participant first
INSERT INTO discussion_participants (discussion_id, user_id, joined_at)
SELECT 
    d.id,
    u.id,
    NOW()
FROM discussions d, users u
WHERE d.id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)
AND u.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID
ON CONFLICT (discussion_id, user_id) DO NOTHING;

-- Step 2: Test the function
SELECT 
    'CORRECTED FUNCTION TEST' as test_name,
    CASE 
        WHEN leave_discussion(
            'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,
            (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)
        ) = true THEN 'SUCCESS - Function now works!'
        ELSE 'FAILED - Still broken'
    END as result;

-- Step 3: Verify William was removed
SELECT 
    'WILLIAM REMOVED CHECK' as test_name,
    CASE 
        WHEN EXISTS(
            SELECT 1 FROM discussion_participants dp
            JOIN users u ON dp.user_id = u.id
            WHERE u.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID
            AND dp.discussion_id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)
        ) THEN 'FAILED - William still in participants'
        ELSE 'SUCCESS - William removed from participants'
    END as result;

-- Step 4: Show final participants list
SELECT 
    'FINAL PARTICIPANTS' as test_name,
    COALESCE(
        string_agg(u.name || ' (@' || u.username || ')', ', '),
        'NO PARTICIPANTS'
    ) as result
FROM discussion_participants dp
JOIN users u ON dp.user_id = u.id
WHERE dp.discussion_id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1);
