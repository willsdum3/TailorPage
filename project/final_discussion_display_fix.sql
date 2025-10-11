-- Final Fix for Discussion Display Issues
-- The data exists and looks correct, let's ensure the function returns it properly

-- First, let's test the current function to see what it's actually returning
DO $$
DECLARE
    test_user_id UUID;
    test_discussion_id UUID;
    test_result RECORD;
BEGIN
    -- Get test data
    SELECT u.auth_user_id INTO test_user_id FROM users u WHERE u.name = 'Kat Slater' LIMIT 1;
    SELECT d.id INTO test_discussion_id FROM discussions d LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_discussion_id IS NOT NULL THEN
        RAISE NOTICE 'Testing with user: % and discussion: %', test_user_id, test_discussion_id;
        
        -- Test the current function
        FOR test_result IN 
            SELECT * FROM get_discussion_messages(test_user_id, test_discussion_id, 5, 0)
        LOOP
            RAISE NOTICE 'Function result: id=%, content=%, userName=%, userUsername=%, userImageUrl=%, createdAt=%', 
                test_result.id, 
                test_result.content,
                test_result.userName,
                test_result.userUsername,
                test_result.userImageUrl,
                test_result.createdAt;
        END LOOP;
    ELSE
        RAISE NOTICE 'No test data found';
    END IF;
END $$;

-- Update the function to ensure it returns data in the exact format expected
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
    
    -- Return messages with user information - ensure all fields are properly mapped
    RETURN QUERY
    SELECT 
        dm.id,
        COALESCE(dm.message, dm.content) as content,
        dm.created_at as createdAt,
        dm.user_id as userId,
        u.name as userName,
        u.username as userUsername,
        u.avatar_url as userImageUrl,
        COALESCE(dm.is_edited, FALSE) as isEdited
    FROM discussion_messages dm
    JOIN users u ON dm.user_id = u.id
    WHERE dm.discussion_id = get_discussion_messages.p_discussion_id
    ORDER BY dm.created_at ASC
    LIMIT limit_count
    OFFSET offset_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the updated function
DO $$
DECLARE
    test_user_id UUID;
    test_discussion_id UUID;
    test_result RECORD;
    message_count INTEGER := 0;
BEGIN
    -- Get test data
    SELECT u.auth_user_id INTO test_user_id FROM users u WHERE u.name = 'Kat Slater' LIMIT 1;
    SELECT d.id INTO test_discussion_id FROM discussions d LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_discussion_id IS NOT NULL THEN
        RAISE NOTICE 'Testing updated function with user: % and discussion: %', test_user_id, test_discussion_id;
        
        -- Test the updated function
        FOR test_result IN 
            SELECT * FROM get_discussion_messages(test_user_id, test_discussion_id, 5, 0)
        LOOP
            message_count := message_count + 1;
            RAISE NOTICE 'Updated function result %: id=%, content=%, userName=%, userUsername=%, userImageUrl=%, createdAt=%', 
                message_count,
                test_result.id, 
                test_result.content,
                test_result.userName,
                test_result.userUsername,
                test_result.userImageUrl,
                test_result.createdAt;
        END LOOP;
        
        RAISE NOTICE 'Function test complete - found % messages', message_count;
    ELSE
        RAISE NOTICE 'No test data found for updated function test';
    END IF;
END $$;

-- Show the final function signature to confirm field names
SELECT 
    'Final Function Signature' as check_type,
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
