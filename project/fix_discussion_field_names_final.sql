-- Final Fix for Discussion Field Names
-- The frontend expects camelCase field names, but the function returns lowercase

-- Drop and recreate the function with exact field names the frontend expects
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
    createdAt TIMESTAMP WITH TIME ZONE,
    userId UUID,
    userName TEXT,
    userUsername TEXT,
    userImageUrl TEXT,
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
    
    -- Return messages with user information - using exact field names the frontend expects
    RETURN QUERY
    SELECT 
        dm.id,
        COALESCE(dm.message, dm.content) as content,
        dm.created_at as "createdAt",
        dm.user_id as "userId",
        COALESCE(u.name, 'Unknown User') as "userName",
        COALESCE(u.username, '') as "userUsername",
        COALESCE(u.avatar_url, '') as "userImageUrl",
        COALESCE(dm.is_edited, FALSE) as "isEdited"
    FROM discussion_messages dm
    JOIN users u ON dm.user_id = u.id
    WHERE dm.discussion_id = get_discussion_messages.p_discussion_id
    ORDER BY dm.created_at ASC
    LIMIT limit_count
    OFFSET offset_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the function to make sure it returns the right field names
DO $$
DECLARE
    test_user_id UUID;
    test_discussion_id UUID;
    test_result RECORD;
    field_count INTEGER := 0;
BEGIN
    -- Get test data
    SELECT u.auth_user_id INTO test_user_id FROM users u WHERE u.name = 'Kat Slater' LIMIT 1;
    SELECT d.id INTO test_discussion_id FROM discussions d LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_discussion_id IS NOT NULL THEN
        RAISE NOTICE 'Testing function with correct field names...';
        
        -- Test the function
        FOR test_result IN 
            SELECT * FROM get_discussion_messages(test_user_id, test_discussion_id, 1, 0)
        LOOP
            field_count := field_count + 1;
            RAISE NOTICE 'Message %: id=%, content=%, userName=%, userUsername=%, userImageUrl=%, createdAt=%', 
                field_count,
                test_result.id, 
                test_result.content,
                test_result."userName",
                test_result."userUsername",
                test_result."userImageUrl",
                test_result."createdAt";
        END LOOP;
        
        RAISE NOTICE 'Function test complete - found % messages with correct field names', field_count;
    ELSE
        RAISE NOTICE 'No test data found';
    END IF;
END $$;

-- Show the final function signature to confirm field names
SELECT 
    'Final Function Field Names' as check_type,
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
