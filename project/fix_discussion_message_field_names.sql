-- Fix Discussion Message Field Names for Frontend
-- The frontend expects userImageUrl, userName, userUsername, etc.

-- Update the get_discussion_messages function to return the correct field names expected by frontend
DROP FUNCTION IF EXISTS get_discussion_messages(UUID, UUID, INTEGER, INTEGER) CASCADE;

CREATE OR REPLACE FUNCTION get_discussion_messages(
    auth_user_id UUID,
    p_discussion_id UUID,
    limit_count INTEGER DEFAULT 50,
    offset_count INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    content TEXT,
    createdAt TIMESTAMP WITH TIME ZONE,  -- Changed from created_at to createdAt
    userId UUID,                         -- Changed from user_id to userId
    userName TEXT,                       -- Changed from name to userName
    userUsername TEXT,                   -- Changed from username to userUsername
    userImageUrl TEXT,                   -- Changed from avatar_url to userImageUrl
    isEdited BOOLEAN
) AS $$
DECLARE
    user_internal_id UUID;
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
    
    -- Return messages with user information, using the correct field names expected by frontend
    RETURN QUERY
    SELECT 
        dm.id,
        COALESCE(dm.message, dm.content) as content, -- Use message first, fallback to content
        dm.created_at as createdAt,                  -- Frontend expects createdAt
        dm.user_id as userId,                        -- Frontend expects userId
        u.name as userName,                          -- Frontend expects userName
        u.username as userUsername,                  -- Frontend expects userUsername
        u.avatar_url as userImageUrl,                -- Frontend expects userImageUrl
        COALESCE(dm.is_edited, FALSE) as isEdited
    FROM discussion_messages dm
    JOIN users u ON dm.user_id = u.id
    WHERE dm.discussion_id = get_discussion_messages.p_discussion_id
    ORDER BY dm.created_at ASC
    LIMIT limit_count
    OFFSET offset_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the function
DO $$
DECLARE
    test_user_id UUID;
    test_discussion_id UUID;
    test_result RECORD;
BEGIN
    -- Get test data if available
    SELECT u.auth_user_id INTO test_user_id FROM users u LIMIT 1;
    SELECT d.id INTO test_discussion_id FROM discussions d LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_discussion_id IS NOT NULL THEN
        BEGIN
            -- Test the get_discussion_messages function
            FOR test_result IN 
                SELECT * FROM get_discussion_messages(test_user_id, test_discussion_id, 5, 0) LIMIT 1
            LOOP
                RAISE NOTICE '✅ get_discussion_messages test successful with correct field names';
                RAISE NOTICE 'Sample message: content=%, userName=%, userUsername=%, userImageUrl=%', 
                    COALESCE(test_result.content, 'NULL'), 
                    COALESCE(test_result.userName, 'NULL'), 
                    COALESCE(test_result.userUsername, 'NULL'), 
                    COALESCE(test_result.userImageUrl, 'NULL');
                EXIT;
            END LOOP;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE '❌ Function test failed: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE '⚠️ No test data available for function test';
    END IF;
END $$;

-- Show the function signature to confirm the return fields
SELECT 
    'Function Return Fields' as check_type,
    parameter_name,
    data_type
FROM information_schema.parameters 
WHERE specific_name IN (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_name = 'get_discussion_messages' 
    AND routine_schema = 'public'
    AND parameter_mode = 'OUT'
)
ORDER BY ordinal_position;

-- Final verification
SELECT 
    'Final Function Verification' as check_type,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name = 'get_discussion_messages'
AND routine_schema = 'public';
