-- Fix Discussion Messaging Parameter Names
-- The frontend calls with 'discussion_id' but function expects 'discussion_id_param'

-- Drop and recreate the function with the correct parameter names that match the frontend
DROP FUNCTION IF EXISTS add_discussion_message(UUID, UUID, TEXT) CASCADE;

CREATE OR REPLACE FUNCTION add_discussion_message(
    auth_user_id UUID,
    discussion_id UUID,  -- Changed back to match frontend call
    message_content TEXT
)
RETURNS UUID AS $$
DECLARE
    user_internal_id UUID;
    message_id UUID;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if user is a member of the discussion with explicit table reference
    IF NOT EXISTS (
        SELECT 1 FROM discussion_members dm
        WHERE dm.discussion_id = add_discussion_message.discussion_id 
        AND dm.user_id = user_internal_id
    ) THEN
        RAISE EXCEPTION 'User is not a member of this discussion';
    END IF;
    
    -- Insert the message with explicit column references
    INSERT INTO discussion_messages (discussion_id, user_id, message, created_at)
    VALUES (add_discussion_message.discussion_id, user_internal_id, add_discussion_message.message_content, NOW())
    RETURNING id INTO message_id;
    
    -- Create notification for other members (if function exists)
    BEGIN
        PERFORM create_discussion_message_notification(
            add_discussion_message.discussion_id,
            user_internal_id,
            add_discussion_message.message_content
        );
    EXCEPTION
        WHEN OTHERS THEN
            -- Log the error but don't fail the main operation
            RAISE NOTICE 'Failed to create discussion message notification: %', SQLERRM;
    END;
    
    RETURN message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the function with the exact parameters the frontend sends
DO $$
DECLARE
    test_user_id UUID;
    test_discussion_id UUID;
    message_id UUID;
BEGIN
    -- Get test data if available
    SELECT u.auth_user_id INTO test_user_id FROM users u LIMIT 1;
    SELECT d.id INTO test_discussion_id FROM discussions d LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_discussion_id IS NOT NULL THEN
        BEGIN
            -- Test with the exact parameter names the frontend uses
            message_id := add_discussion_message(test_user_id, test_discussion_id, 'Test message with correct parameters');
            RAISE NOTICE '✅ add_discussion_message test successful with correct parameters, message_id: %', message_id;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE '❌ Function test failed: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE '⚠️ No test data available for function test';
    END IF;
END $$;

-- Show the function signature to confirm parameter names
SELECT 
    'Function Parameter Check' as check_type,
    parameter_name,
    data_type,
    parameter_mode
FROM information_schema.parameters 
WHERE specific_name IN (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_name = 'add_discussion_message' 
    AND routine_schema = 'public'
)
ORDER BY ordinal_position;

-- Final verification
SELECT 
    'Final Function Verification' as check_type,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name = 'add_discussion_message'
AND routine_schema = 'public';
