-- Implement unblocking functionality
-- This will allow users to unblock others and restore their ability to interact

-- Create unblock function
CREATE OR REPLACE FUNCTION unblock_friend(
    p_blocker_auth_user_id UUID,
    p_blocked_user_id TEXT  -- Can be either internal ID or auth user ID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    blocker_internal_id UUID;
    blocked_internal_id UUID;
    blocked_auth_user_id UUID;
    blocking_exists BOOLEAN := FALSE;
BEGIN
    -- Get blocker's internal ID
    SELECT id INTO blocker_internal_id 
    FROM users 
    WHERE auth_user_id = p_blocker_auth_user_id;
    
    -- Check if blocker exists
    IF blocker_internal_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Blocker user not found'
        );
    END IF;
    
    -- Try to find blocked user by internal ID first
    SELECT id, auth_user_id INTO blocked_internal_id, blocked_auth_user_id
    FROM users 
    WHERE id = p_blocked_user_id::UUID;
    
    -- If not found by internal ID, try by auth user ID
    IF blocked_internal_id IS NULL THEN
        SELECT id, auth_user_id INTO blocked_internal_id, blocked_auth_user_id
        FROM users 
        WHERE auth_user_id = p_blocked_user_id::UUID;
    END IF;
    
    -- Check if blocked user exists
    IF blocked_internal_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Blocked user not found'
        );
    END IF;
    
    -- Check if blocking relationship exists
    SELECT EXISTS(
        SELECT 1 FROM blocked_users 
        WHERE blocker_id = blocker_internal_id 
        AND blocked_id = blocked_internal_id
    ) INTO blocking_exists;
    
    IF NOT blocking_exists THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'User is not blocked'
        );
    END IF;
    
    -- Remove the blocking relationship
    DELETE FROM blocked_users 
    WHERE blocker_id = blocker_internal_id 
    AND blocked_id = blocked_internal_id;
    
    -- Return success
    RETURN jsonb_build_object(
        'success', true,
        'message', 'User unblocked successfully',
        'unblocked_user_id', blocked_internal_id,
        'unblocked_auth_user_id', blocked_auth_user_id
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', false,
        'error', 'Database error: ' || SQLERRM
    );
END;
$$;

-- Test the unblock function
SELECT 
    'Test Unblock Function' as test_type,
    unblock_friend(
        'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,  -- William's auth_user_id
        'df1ec11e-9b78-4fb5-8218-c6fb03320100'        -- Tailor Page's ID (internal or auth)
    ) as result;
