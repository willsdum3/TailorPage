-- =====================================================
-- FIX LEAVE DISCUSSION FUNCTION BUG
-- =====================================================
-- The logic is correct but the function has a bug - let's recreate it

-- Drop the buggy function
DROP FUNCTION IF EXISTS leave_discussion(UUID, UUID);

-- Create a corrected version with better logging
CREATE OR REPLACE FUNCTION leave_discussion(
    auth_user_id UUID,
    discussion_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
    discussion_exists BOOLEAN;
    is_participant BOOLEAN;
    is_creator BOOLEAN;
    rows_deleted INTEGER;
BEGIN
    RAISE NOTICE 'leave_discussion called: auth_user_id=%, discussion_id=%', auth_user_id, discussion_id;
    
    -- Get user ID
    SELECT u.id INTO user_uuid
    FROM users u
    WHERE u.auth_user_id = leave_discussion.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RAISE NOTICE 'STEP 1 FAILED: User not found for auth_user_id: %', auth_user_id;
        RETURN false;
    END IF;
    
    RAISE NOTICE 'STEP 1 SUCCESS: Found user: %', user_uuid;
    
    -- Check if discussion exists
    SELECT EXISTS(SELECT 1 FROM discussions WHERE id = discussion_id) INTO discussion_exists;
    IF NOT discussion_exists THEN
        RAISE NOTICE 'STEP 2 FAILED: Discussion not found: %', discussion_id;
        RETURN false;
    END IF;
    
    RAISE NOTICE 'STEP 2 SUCCESS: Discussion exists: %', discussion_id;
    
    -- Check if user is the creator
    SELECT EXISTS(
        SELECT 1 FROM discussions d 
        WHERE d.id = leave_discussion.discussion_id AND d.created_by = user_uuid
    ) INTO is_creator;
    
    RAISE NOTICE 'STEP 3: Creator check - User % is creator: %', user_uuid, is_creator;
    
    IF is_creator THEN
        RAISE NOTICE 'STEP 3 FAILED: User % is the creator of discussion % - cannot leave own discussion', user_uuid, discussion_id;
        RETURN false;
    END IF;
    
    RAISE NOTICE 'STEP 3 SUCCESS: User is not creator, can proceed';
    
    -- Check if user is participant
    SELECT EXISTS(
        SELECT 1 FROM discussion_participants dp
        WHERE dp.discussion_id = leave_discussion.discussion_id AND dp.user_id = user_uuid
    ) INTO is_participant;
    
    RAISE NOTICE 'STEP 4: Participation check - User % is participant: %', user_uuid, is_participant;
    
    IF NOT is_participant THEN
        RAISE NOTICE 'STEP 4 FAILED: User % is not a participant in discussion %', user_uuid, discussion_id;
        RETURN false;
    END IF;
    
    RAISE NOTICE 'STEP 4 SUCCESS: User is participant, proceeding to remove';
    
    -- Remove user from participants
    DELETE FROM discussion_participants 
    WHERE discussion_id = leave_discussion.discussion_id 
    AND user_id = user_uuid;
    
    GET DIAGNOSTICS rows_deleted = ROW_COUNT;
    RAISE NOTICE 'STEP 5: Deleted % rows from discussion_participants', rows_deleted;
    
    IF rows_deleted > 0 THEN
        RAISE NOTICE 'STEP 5 SUCCESS: User % successfully removed from discussion %', user_uuid, discussion_id;
        RETURN true;
    ELSE
        RAISE NOTICE 'STEP 5 FAILED: No rows deleted - user % may not have been participant', user_uuid;
        RETURN false;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'ERROR in leave_discussion: %', SQLERRM;
        RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION leave_discussion TO authenticated;

-- Test the fixed function immediately
DO $$
DECLARE
    test_auth_id UUID := 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID;
    test_discussion_id UUID;
    leave_result BOOLEAN;
BEGIN
    RAISE NOTICE '=== TESTING FIXED LEAVE FUNCTION ===';
    
    -- Get discussion ID
    SELECT id INTO test_discussion_id FROM discussions ORDER BY created_at DESC LIMIT 1;
    
    -- Ensure user is joined first (for testing)
    INSERT INTO discussion_participants (discussion_id, user_id, joined_at)
    SELECT 
        test_discussion_id,
        u.id,
        NOW()
    FROM users u 
    WHERE u.auth_user_id = test_auth_id
    ON CONFLICT (discussion_id, user_id) DO NOTHING;
    
    RAISE NOTICE 'User ensured to be participant for testing';
    
    -- Test the function
    SELECT leave_discussion(test_auth_id, test_discussion_id) INTO leave_result;
    
    IF leave_result = true THEN
        RAISE NOTICE '✅ FIXED: leave_discussion now returns true!';
        RAISE NOTICE '✅ William should now be able to leave discussions';
    ELSE
        RAISE NOTICE '❌ Still broken: Function returned false';
        RAISE NOTICE 'Check the step-by-step logs above to see where it failed';
    END IF;
END $$;

-- Show final test result as table
SELECT 
    'FIXED FUNCTION TEST' as test_name,
    CASE 
        WHEN leave_discussion(
            'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,
            (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)
        ) = true THEN 'SUCCESS - Function now works!'
        ELSE 'STILL FAILED - Check logs above'
    END as result;
