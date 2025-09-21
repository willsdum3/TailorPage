-- Add delete discussion functionality for creators
-- This allows discussion creators to completely delete their discussions

-- First, let's check what discussion-related functions exist
DO $$
BEGIN
    RAISE NOTICE 'Checking existing discussion functions...';
END $$;

SELECT 
    r.routine_name as function_name,
    string_agg(
        CASE 
            WHEN p.data_type = 'ARRAY' THEN p.udt_name || '[]'
            WHEN p.data_type = 'USER-DEFINED' THEN p.udt_name 
            ELSE p.data_type 
        END, 
        ', ' 
        ORDER BY p.ordinal_position
    ) as parameters
FROM information_schema.routines r
LEFT JOIN information_schema.parameters p ON r.specific_name = p.specific_name
WHERE r.routine_schema = 'public' 
AND r.routine_name LIKE '%discussion%'
AND r.routine_type = 'FUNCTION'
GROUP BY r.routine_name, r.specific_name
ORDER BY r.routine_name;

-- Create the delete_discussion function
CREATE OR REPLACE FUNCTION delete_discussion(
    p_auth_user_id UUID,
    p_discussion_id UUID
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_discussion_record RECORD;
    v_deleted_count INTEGER := 0;
    v_messages_deleted INTEGER := 0;
    v_participants_deleted INTEGER := 0;
BEGIN
    -- Step 1: Get the user ID from auth_user_id
    SELECT id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'User not found'
        );
    END IF;
    
    -- Step 2: Check if discussion exists and get creator info
    SELECT id, title, created_by INTO v_discussion_record
    FROM discussions 
    WHERE id = p_discussion_id;
    
    IF v_discussion_record.id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Discussion not found'
        );
    END IF;
    
    -- Step 3: Verify user is the creator
    IF v_discussion_record.created_by != v_user_id THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Only the creator can delete this discussion'
        );
    END IF;
    
    -- Step 4: Delete related data in correct order (foreign key constraints)
    
    -- Delete discussion messages first
    DELETE FROM discussion_messages 
    WHERE discussion_id = p_discussion_id;
    GET DIAGNOSTICS v_messages_deleted = ROW_COUNT;
    
    -- Delete discussion participants
    DELETE FROM discussion_participants 
    WHERE discussion_id = p_discussion_id;
    GET DIAGNOSTICS v_participants_deleted = ROW_COUNT;
    
    -- Finally, delete the discussion itself
    DELETE FROM discussions 
    WHERE id = p_discussion_id;
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    -- Step 5: Return success with cleanup stats
    IF v_deleted_count > 0 THEN
        RETURN json_build_object(
            'success', true,
            'message', 'Discussion deleted successfully',
            'stats', json_build_object(
                'discussion_deleted', v_deleted_count,
                'messages_deleted', v_messages_deleted,
                'participants_removed', v_participants_deleted
            )
        );
    ELSE
        RETURN json_build_object(
            'success', false,
            'error', 'Failed to delete discussion'
        );
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Database error: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the function with a simple diagnostic
DO $$
DECLARE
    test_result JSON;
BEGIN
    RAISE NOTICE 'Testing delete_discussion function creation...';
    
    -- Just test that the function exists and can be called (with invalid IDs)
    SELECT delete_discussion(
        '00000000-0000-0000-0000-000000000000'::UUID,
        '00000000-0000-0000-0000-000000000000'::UUID
    ) INTO test_result;
    
    RAISE NOTICE 'Function test result: %', test_result;
END $$;

-- Show function signature
SELECT 
    'delete_discussion' as function_name,
    'p_auth_user_id UUID, p_discussion_id UUID' as parameters,
    'JSON' as return_type,
    'Allows discussion creators to delete their discussions and all related data' as description;
