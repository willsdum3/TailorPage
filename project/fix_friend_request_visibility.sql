-- Fix friend request visibility issues
-- This script ensures all friend requests are properly visible and manageable

-- 1. First, let's ensure all status values are normalized
UPDATE friend_connections
SET status = CASE 
    WHEN LOWER(TRIM(COALESCE(status, ''))) = 'pending' THEN 'pending'
    WHEN LOWER(TRIM(COALESCE(status, ''))) = 'accepted' THEN 'accepted'
    WHEN LOWER(TRIM(COALESCE(status, ''))) = 'rejected' THEN 'rejected'
    WHEN LOWER(TRIM(COALESCE(status, ''))) IN ('declined', 'denied', 'cancelled') THEN 'rejected'
    WHEN status IS NULL OR TRIM(COALESCE(status, '')) = '' THEN 'pending'
    ELSE 'pending'  -- Default unknown statuses to pending
END
WHERE status IS NULL 
   OR LOWER(TRIM(status)) != status
   OR LENGTH(TRIM(COALESCE(status, ''))) = 0;

-- 2. Create a function to get outgoing friend requests (requests you sent)
CREATE OR REPLACE FUNCTION get_outgoing_friend_requests(
    p_auth_user_id UUID
)
RETURNS TABLE(
    id UUID,
    user_id UUID,
    friend_id UUID,
    status TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    friend_name TEXT,
    friend_username TEXT,
    friend_email TEXT,
    friend_image_url TEXT,
    personality_match_score NUMERIC
) AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(p_auth_user_id);
    
    -- If user not found, return empty result
    IF user_internal_id IS NULL THEN
        RETURN;
    END IF;
    
    -- Return pending friend requests where the current user is the requester (sent requests)
    RETURN QUERY
    SELECT 
        fc.id,
        fc.user_id,
        fc.friend_id as friend_id,  -- Return recipient's ID as friend_id
        fc.status,
        fc.created_at,
        COALESCE(u.name, 'User') as friend_name,
        COALESCE(u.username, '') as friend_username,
        COALESCE(u.email, '') as friend_email,
        u.avatar_url as friend_image_url,
        0::NUMERIC as personality_match_score
    FROM friend_connections fc
    INNER JOIN users u ON fc.friend_id = u.id
    WHERE fc.user_id = user_internal_id
      AND LOWER(TRIM(fc.status)) = 'pending'
    ORDER BY fc.created_at DESC;
EXCEPTION
    WHEN OTHERS THEN
        -- Return empty result on any error
        RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_outgoing_friend_requests(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_outgoing_friend_requests(UUID) TO anon;

-- 3. Update send_friend_request to handle edge cases better
-- (Already done in fix_send_friend_request_function.sql, but ensure it's applied)

-- 4. Verify the cleanup worked
SELECT 
    '=== STATUS NORMALIZATION VERIFICATION ===' as section,
    status,
    COUNT(*) as count
FROM friend_connections
GROUP BY status
ORDER BY count DESC;

-- 5. Show summary of all friend connections
SELECT 
    '=== SUMMARY ===' as section,
    COUNT(*) as total_connections,
    COUNT(*) FILTER (WHERE LOWER(TRIM(status)) = 'pending') as pending_count,
    COUNT(*) FILTER (WHERE LOWER(TRIM(status)) = 'accepted') as accepted_count,
    COUNT(*) FILTER (WHERE LOWER(TRIM(status)) = 'rejected') as rejected_count,
    COUNT(*) FILTER (WHERE status IS NULL OR LOWER(TRIM(COALESCE(status, ''))) NOT IN ('pending', 'accepted', 'rejected')) as invalid_count
FROM friend_connections;

