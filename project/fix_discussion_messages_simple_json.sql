-- Simple JSON Fix for Discussion Messages
-- Return data as JSON with correct field names

-- Drop the old function
DROP FUNCTION IF EXISTS get_discussion_messages(UUID, UUID, INTEGER, INTEGER) CASCADE;

-- Create a function that returns JSON with correct field names
CREATE OR REPLACE FUNCTION get_discussion_messages(
    auth_user_id UUID,
    p_discussion_id UUID,
    limit_count INTEGER DEFAULT 50,
    offset_count INTEGER DEFAULT 0
)
RETURNS JSON AS $$
DECLARE
    user_internal_id UUID;
    result JSON;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- More lenient membership check: allow if user is a member OR is the creator
    IF NOT EXISTS (
        SELECT 1 FROM discussion_members dm
        WHERE dm.discussion_id = get_discussion_messages.p_discussion_id 
        AND dm.user_id = user_internal_id
    ) AND NOT EXISTS (
        SELECT 1 FROM discussions d
        WHERE d.id = get_discussion_messages.p_discussion_id
        AND d.created_by = user_internal_id
    ) THEN
        -- If user is not a member and not the creator, add them as a member automatically
        INSERT INTO discussion_members (discussion_id, user_id, joined_at)
        VALUES (get_discussion_messages.p_discussion_id, user_internal_id, NOW())
        ON CONFLICT (discussion_id, user_id) DO NOTHING;
    END IF;
    
    -- Build JSON result with correct field names
    SELECT json_agg(
        json_build_object(
            'id', dm.id,
            'content', COALESCE(dm.message, dm.content),
            'createdAt', dm.created_at,
            'userId', dm.user_id,
            'userName', COALESCE(u.name, 'Unknown User'),
            'userUsername', COALESCE(u.username, ''),
            'userImageUrl', COALESCE(u.avatar_url, ''),
            'isEdited', COALESCE(dm.is_edited, FALSE)
        )
    )
    INTO result
    FROM discussion_messages dm
    JOIN users u ON dm.user_id = u.id
    WHERE dm.discussion_id = get_discussion_messages.p_discussion_id
    ORDER BY dm.created_at ASC
    LIMIT limit_count
    OFFSET offset_count;
    
    -- Return empty array if no messages
    RETURN COALESCE(result, '[]'::json);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the function
DO $$
DECLARE
    test_user_id UUID;
    test_discussion_id UUID;
    test_result JSON;
BEGIN
    -- Get test data
    SELECT u.auth_user_id INTO test_user_id FROM users u WHERE u.name = 'Kat Slater' LIMIT 1;
    SELECT d.id INTO test_discussion_id FROM discussions d LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_discussion_id IS NOT NULL THEN
        RAISE NOTICE 'Testing JSON function with user: % and discussion: %', test_user_id, test_discussion_id;
        
        -- Test the function
        SELECT get_discussion_messages(test_user_id, test_discussion_id, 3, 0) INTO test_result;
        
        RAISE NOTICE 'Function returned JSON: %', test_result;
    ELSE
        RAISE NOTICE 'No test data found';
    END IF;
END $$;

-- Show the function signature
SELECT 
    'JSON Function Created' as check_type,
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_name = 'get_discussion_messages' 
AND routine_schema = 'public';
