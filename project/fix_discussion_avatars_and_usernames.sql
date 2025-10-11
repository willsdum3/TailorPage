-- Fix Discussion Message Avatars and Usernames Display
-- Address both avatar_url and username field issues

-- First, let's check what's in the users table for avatars and usernames
SELECT 
    'Users Table Sample' as check_type,
    id,
    name,
    username,
    avatar_url,
    email
FROM users 
LIMIT 5;

-- Check the current function return fields
SELECT 
    'Current Function Fields' as check_type,
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

-- Let's also check if there are any messages and what user data they have
SELECT 
    'Sample Discussion Messages' as check_type,
    dm.id,
    dm.content,
    dm.created_at,
    u.name,
    u.username,
    u.avatar_url,
    u.email
FROM discussion_messages dm
JOIN users u ON dm.user_id = u.id
LIMIT 5;

-- Update the get_discussion_messages function to handle missing data gracefully
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
    
    -- Return messages with user information, handling missing data gracefully
    RETURN QUERY
    SELECT 
        dm.id,
        COALESCE(dm.message, dm.content, 'Legacy message') as content,
        dm.created_at as createdAt,
        dm.user_id as userId,
        COALESCE(u.name, 'Unknown User') as userName,
        COALESCE(u.username, u.email, 'unknown') as userUsername,
        COALESCE(u.avatar_url, '') as userImageUrl,
        COALESCE(dm.is_edited, FALSE) as isEdited
    FROM discussion_messages dm
    JOIN users u ON dm.user_id = u.id
    WHERE dm.discussion_id = get_discussion_messages.p_discussion_id
    ORDER BY dm.created_at ASC
    LIMIT limit_count
    OFFSET offset_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Also ensure we have the get_user_internal_id function
CREATE OR REPLACE FUNCTION get_user_internal_id(auth_user_id UUID)
RETURNS UUID AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    SELECT u.id INTO user_internal_id
    FROM users u 
    WHERE u.auth_user_id = get_user_internal_id.auth_user_id;
    
    RETURN user_internal_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the function with detailed output
DO $$
DECLARE
    test_user_id UUID;
    test_discussion_id UUID;
    test_result RECORD;
    message_count INTEGER := 0;
BEGIN
    -- Get test data if available
    SELECT u.auth_user_id INTO test_user_id FROM users u LIMIT 1;
    SELECT d.id INTO test_discussion_id FROM discussions d LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_discussion_id IS NOT NULL THEN
        BEGIN
            -- Test the get_discussion_messages function and show detailed results
            FOR test_result IN 
                SELECT * FROM get_discussion_messages(test_user_id, test_discussion_id, 10, 0)
            LOOP
                message_count := message_count + 1;
                RAISE NOTICE 'Message %: content=%, userName=%, userUsername=%, userImageUrl=%, createdAt=%', 
                    message_count,
                    COALESCE(test_result.content, 'NULL'), 
                    COALESCE(test_result.userName, 'NULL'), 
                    COALESCE(test_result.userUsername, 'NULL'), 
                    COALESCE(test_result.userImageUrl, 'NULL'),
                    test_result.createdAt;
                
                -- Only show first 3 messages to avoid spam
                IF message_count >= 3 THEN
                    EXIT;
                END IF;
            END LOOP;
            
            IF message_count > 0 THEN
                RAISE NOTICE '✅ get_discussion_messages test successful - found % messages', message_count;
            ELSE
                RAISE NOTICE '⚠️ No messages found in test discussion';
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE '❌ Function test failed: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE '⚠️ No test data available for function test';
    END IF;
END $$;

-- Show the final function signature
SELECT 
    'Final Function Fields' as check_type,
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
