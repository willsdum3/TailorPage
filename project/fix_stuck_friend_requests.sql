-- Fix stuck friend requests
-- This script helps identify and fix friend requests that are stuck

-- 1. Find all stuck requests (pending requests older than 30 days or with invalid status)
SELECT 
    '=== STUCK REQUESTS (OLD OR INVALID) ===' as section,
    fc.id,
    fc.user_id as requester_internal_id,
    fc.friend_id as recipient_internal_id,
    fc.status,
    LOWER(TRIM(fc.status)) as normalized_status,
    fc.created_at,
    NOW() - fc.created_at as age,
    requester.name as requester_name,
    requester.username as requester_username,
    recipient.name as recipient_name,
    recipient.username as recipient_username,
    CASE 
        WHEN fc.created_at < NOW() - INTERVAL '30 days' THEN 'OLD (30+ days)'
        WHEN LOWER(TRIM(fc.status)) NOT IN ('pending', 'accepted', 'rejected') THEN 'INVALID STATUS'
        ELSE 'OK'
    END as issue_type
FROM friend_connections fc
LEFT JOIN users requester ON fc.user_id = requester.id
LEFT JOIN users recipient ON fc.friend_id = recipient.id
WHERE (fc.created_at < NOW() - INTERVAL '30 days' AND LOWER(TRIM(fc.status)) = 'pending')
   OR (LOWER(TRIM(fc.status)) NOT IN ('pending', 'accepted', 'rejected'))
ORDER BY fc.created_at DESC;

-- 2. Normalize all status values (fix case/whitespace issues)
UPDATE friend_connections
SET status = CASE 
    WHEN LOWER(TRIM(status)) = 'pending' THEN 'pending'
    WHEN LOWER(TRIM(status)) = 'accepted' THEN 'accepted'
    WHEN LOWER(TRIM(status)) = 'rejected' THEN 'rejected'
    WHEN LOWER(TRIM(status)) IN ('declined', 'denied') THEN 'rejected'
    ELSE 'pending'  -- Default to pending for unknown statuses
END
WHERE LOWER(TRIM(status)) != status
   OR status IS NULL;

-- 3. Clean up duplicate requests (keep the most recent one)
WITH duplicates AS (
    SELECT 
        LEAST(user_id, friend_id) as user1_id,
        GREATEST(user_id, friend_id) as user2_id,
        COUNT(*) as dup_count,
        MAX(created_at) as latest_created_at
    FROM friend_connections
    WHERE LOWER(TRIM(status)) = 'pending'
    GROUP BY LEAST(user_id, friend_id), GREATEST(user_id, friend_id)
    HAVING COUNT(*) > 1
)
DELETE FROM friend_connections fc
WHERE EXISTS (
    SELECT 1 FROM duplicates d
    WHERE (LEAST(fc.user_id, fc.friend_id) = d.user1_id 
       AND GREATEST(fc.user_id, fc.friend_id) = d.user2_id)
      AND fc.created_at < d.latest_created_at
      AND LOWER(TRIM(fc.status)) = 'pending'
);

-- 4. Create a function to cancel/delete a friend request
CREATE OR REPLACE FUNCTION cancel_friend_request(
    p_auth_user_id UUID,
    p_target_user_id UUID
)
RETURNS JSONB AS $$
DECLARE
    user_internal_id UUID;
    target_internal_id UUID;
    deleted_count INTEGER;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(p_auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- p_target_user_id is the internal ID of the target user
    target_internal_id := p_target_user_id;
    
    -- Delete pending requests FROM the user TO the target
    DELETE FROM friend_connections
    WHERE user_id = user_internal_id
      AND friend_id = target_internal_id
      AND LOWER(TRIM(status)) = 'pending';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    IF deleted_count > 0 THEN
        RETURN jsonb_build_object('success', true, 'message', 'Friend request cancelled successfully');
    ELSE
        RETURN jsonb_build_object('success', false, 'error', 'No pending friend request found to cancel');
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION cancel_friend_request(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION cancel_friend_request(UUID, UUID) TO anon;

-- 5. Verify the cleanup
SELECT 
    '=== AFTER CLEANUP ===' as section,
    COUNT(*) as total_connections,
    COUNT(*) FILTER (WHERE LOWER(TRIM(status)) = 'pending') as pending_count,
    COUNT(*) FILTER (WHERE LOWER(TRIM(status)) = 'accepted') as accepted_count,
    COUNT(*) FILTER (WHERE LOWER(TRIM(status)) = 'rejected') as rejected_count
FROM friend_connections;

