-- Fix the get_blocked_users function to include avatar_url
-- This will allow blocked users' profile pictures to display correctly

-- Drop the existing function first
DROP FUNCTION IF EXISTS get_blocked_users(UUID);

CREATE OR REPLACE FUNCTION get_blocked_users(
    p_auth_user_id UUID
) RETURNS TABLE(
    id UUID,
    blocked_user_id UUID,
    blocked_user_name TEXT,
    blocked_user_username TEXT,
    blocked_user_image_url TEXT,
    blocked_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Get the user ID from auth_user_id
    SELECT users.id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RETURN;
    END IF;
    
    RETURN QUERY
    SELECT 
        bu.id,
        bu.blocked_id as blocked_user_id,
        u.name as blocked_user_name,
        u.username as blocked_user_username,
        u.avatar_url as blocked_user_image_url,
        bu.created_at as blocked_at
    FROM blocked_users bu
    JOIN users u ON bu.blocked_id = u.id
    WHERE bu.blocker_id = v_user_id
    ORDER BY bu.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the updated function
SELECT 
    'Test Updated Function' as test_type,
    get_blocked_users('ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID) as result;
