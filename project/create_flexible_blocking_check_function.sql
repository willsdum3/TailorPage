-- Create a flexible blocking check function that can handle both internal IDs and auth user IDs
-- This will be used for all blocking checks in messaging, joining, etc.

CREATE OR REPLACE FUNCTION is_user_blocked_flexible(
    p_blocker_user_id TEXT,  -- Can be either internal ID or auth user ID
    p_blocked_user_id TEXT   -- Can be either internal ID or auth user ID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    blocker_internal_id UUID;
    blocked_internal_id UUID;
    blocking_exists BOOLEAN := FALSE;
BEGIN
    -- Try to find blocker by internal ID first
    SELECT id INTO blocker_internal_id 
    FROM users 
    WHERE id = p_blocker_user_id::UUID;
    
    -- If not found by internal ID, try by auth user ID
    IF blocker_internal_id IS NULL THEN
        SELECT id INTO blocker_internal_id 
        FROM users 
        WHERE auth_user_id = p_blocker_user_id::UUID;
    END IF;
    
    -- Try to find blocked user by internal ID first
    SELECT id INTO blocked_internal_id 
    FROM users 
    WHERE id = p_blocked_user_id::UUID;
    
    -- If not found by internal ID, try by auth user ID
    IF blocked_internal_id IS NULL THEN
        SELECT id INTO blocked_internal_id 
        FROM users 
        WHERE auth_user_id = p_blocked_user_id::UUID;
    END IF;
    
    -- Check if either user doesn't exist
    IF blocker_internal_id IS NULL OR blocked_internal_id IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Check if blocking relationship exists
    SELECT EXISTS(
        SELECT 1 FROM blocked_users 
        WHERE blocker_id = blocker_internal_id 
        AND blocked_id = blocked_internal_id
    ) INTO blocking_exists;
    
    RETURN blocking_exists;
END;
$$;

-- Test the function
SELECT 
    'Test Flexible Blocking Check' as test_type,
    is_user_blocked_flexible(
        'ee11bb62-0684-4293-a77a-d385c9a070f9',  -- William's auth_user_id
        'df1ec11e-9b78-4fb5-8218-c6fb03320100'   -- Tailor Page's ID (should be blocked)
    ) as is_blocked;
