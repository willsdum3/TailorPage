-- Fix the unblock function to handle ID resolution better
-- The issue is in the user lookup logic

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
    debug_info JSONB;
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
    
    -- Try to find blocked user by internal ID first (if it's a valid UUID)
    BEGIN
        SELECT id, auth_user_id INTO blocked_internal_id, blocked_auth_user_id
        FROM users 
        WHERE id = p_blocked_user_id::UUID;
    EXCEPTION WHEN OTHERS THEN
        -- If UUID conversion fails, try by auth user ID
        SELECT id, auth_user_id INTO blocked_internal_id, blocked_auth_user_id
        FROM users 
        WHERE auth_user_id = p_blocked_user_id::UUID;
    END;
    
    -- If still not found by internal ID, try by auth user ID
    IF blocked_internal_id IS NULL THEN
        BEGIN
            SELECT id, auth_user_id INTO blocked_internal_id, blocked_auth_user_id
            FROM users 
            WHERE auth_user_id = p_blocked_user_id::UUID;
        EXCEPTION WHEN OTHERS THEN
            -- If this also fails, the user doesn't exist
            blocked_internal_id := NULL;
        END;
    END IF;
    
    -- Check if blocked user exists
    IF blocked_internal_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Blocked user not found',
            'debug_info', jsonb_build_object(
                'provided_id', p_blocked_user_id,
                'blocker_internal_id', blocker_internal_id,
                'blocker_auth_id', p_blocker_auth_user_id
            )
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
            'error', 'User is not blocked',
            'debug_info', jsonb_build_object(
                'blocker_internal_id', blocker_internal_id,
                'blocked_internal_id', blocked_internal_id,
                'blocking_exists', blocking_exists
            )
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

-- Test the improved unblock function
SELECT 
    'Test Improved Unblock Function' as test_type,
    unblock_friend(
        '4016845f-fb86-4f3b-be24-052855a7adec'::UUID,  -- Current user's auth_user_id
        '0bcb64b6-0777-444d-9b3c-5d61a1434471'         -- The ID being passed
    ) as result;
