-- Create a flexible blocking function that can handle both internal IDs and auth user IDs
-- This will eliminate the need for frontend ID conversion

CREATE OR REPLACE FUNCTION block_friend_flexible(
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
    club_removal_result JSONB;
    discussion_removal_result JSONB;
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
    
    -- Check if already blocked
    IF EXISTS (
        SELECT 1 FROM blocked_users 
        WHERE blocker_id = blocker_internal_id 
        AND blocked_id = blocked_internal_id
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'User is already blocked'
        );
    END IF;
    
    -- Block the user
    INSERT INTO blocked_users (blocker_id, blocked_id, created_at)
    VALUES (blocker_internal_id, blocked_internal_id, NOW());
    
    -- Remove from book clubs
    SELECT remove_blocked_user_from_clubs(blocker_internal_id, blocked_internal_id) 
    INTO club_removal_result;
    
    -- Remove from discussions
    SELECT remove_blocked_user_from_discussions(blocker_internal_id, blocked_internal_id) 
    INTO discussion_removal_result;
    
    -- Return success
    RETURN jsonb_build_object(
        'success', true,
        'message', 'User blocked successfully',
        'club_removal', club_removal_result,
        'discussion_removal', discussion_removal_result
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', false,
        'error', 'Database error: ' || SQLERRM
    );
END;
$$;

-- Test the function with the problematic ID
SELECT 
    'Test Flexible Blocking Function' as test_type,
    block_friend_flexible(
        'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,  -- William's auth_user_id
        'df1ec11e-9b78-4fb5-8218-c6fb03320100'        -- Tailor Page's ID (internal or auth)
    ) as result;
