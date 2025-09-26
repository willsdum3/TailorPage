-- Create a database function to check if users are blocked
-- This will avoid the ID conversion issues in the frontend

CREATE OR REPLACE FUNCTION is_user_blocked(
    p_blocker_auth_user_id UUID,
    p_blocked_auth_user_id UUID
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
    -- Get internal IDs for both users
    SELECT id INTO blocker_internal_id 
    FROM users 
    WHERE auth_user_id = p_blocker_auth_user_id;
    
    SELECT id INTO blocked_internal_id 
    FROM users 
    WHERE auth_user_id = p_blocked_auth_user_id;
    
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
    'Test Blocking Function' as test_type,
    is_user_blocked(
        'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,  -- William's auth_user_id
        'ca692e7f-6522-4295-86cd-592d7fd754b5'::UUID   -- Tracey's auth_user_id
    ) as is_blocked;
