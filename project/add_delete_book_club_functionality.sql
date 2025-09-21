-- Add delete book club functionality for admins
-- This allows book club admins to completely delete their book clubs

-- First, let's check what book club related functions exist
DO $$
BEGIN
    RAISE NOTICE 'Checking existing book club functions...';
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
AND r.routine_name LIKE '%book_club%'
AND r.routine_type = 'FUNCTION'
GROUP BY r.routine_name, r.specific_name
ORDER BY r.routine_name;

-- Create the delete_book_club function
CREATE OR REPLACE FUNCTION delete_book_club(
    p_auth_user_id UUID,
    p_book_club_id UUID
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_book_club_record RECORD;
    v_deleted_count INTEGER := 0;
    v_messages_deleted INTEGER := 0;
    v_memberships_deleted INTEGER := 0;
    v_polls_deleted INTEGER := 0;
    v_poll_votes_deleted INTEGER := 0;
    v_invitations_deleted INTEGER := 0;
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
    
    -- Step 2: Check if book club exists and get info
    SELECT id, name, created_by INTO v_book_club_record
    FROM book_clubs 
    WHERE id = p_book_club_id;
    
    IF v_book_club_record.id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Book club not found'
        );
    END IF;
    
    -- Step 3: Verify user is an admin (creator or promoted admin)
    IF NOT EXISTS (
        SELECT 1 FROM club_memberships 
        WHERE club_id = p_book_club_id 
        AND user_id = v_user_id 
        AND role IN ('admin', 'owner')
    ) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Only admins can delete this book club'
        );
    END IF;
    
    -- Step 4: Delete related data in correct order (foreign key constraints)
    
    -- Delete book club poll votes first
    DELETE FROM book_club_poll_votes 
    WHERE poll_id IN (
        SELECT id FROM book_club_polls WHERE club_id = p_book_club_id
    );
    GET DIAGNOSTICS v_poll_votes_deleted = ROW_COUNT;
    
    -- Delete book club polls
    DELETE FROM book_club_polls 
    WHERE club_id = p_book_club_id;
    GET DIAGNOSTICS v_polls_deleted = ROW_COUNT;
    
    -- Delete book club messages
    DELETE FROM book_club_messages 
    WHERE club_id = p_book_club_id;
    GET DIAGNOSTICS v_messages_deleted = ROW_COUNT;
    
    -- Delete club invitations
    DELETE FROM club_invitations 
    WHERE club_id = p_book_club_id;
    GET DIAGNOSTICS v_invitations_deleted = ROW_COUNT;
    
    -- Delete club memberships
    DELETE FROM club_memberships 
    WHERE club_id = p_book_club_id;
    GET DIAGNOSTICS v_memberships_deleted = ROW_COUNT;
    
    -- Finally, delete the book club itself
    DELETE FROM book_clubs 
    WHERE id = p_book_club_id;
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    -- Step 5: Return success with cleanup stats
    IF v_deleted_count > 0 THEN
        RETURN json_build_object(
            'success', true,
            'message', 'Book club deleted successfully',
            'stats', json_build_object(
                'book_club_deleted', v_deleted_count,
                'messages_deleted', v_messages_deleted,
                'memberships_deleted', v_memberships_deleted,
                'polls_deleted', v_polls_deleted,
                'poll_votes_deleted', v_poll_votes_deleted,
                'invitations_deleted', v_invitations_deleted
            )
        );
    ELSE
        RETURN json_build_object(
            'success', false,
            'error', 'Failed to delete book club'
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
    RAISE NOTICE 'Testing delete_book_club function creation...';
    
    -- Just test that the function exists and can be called (with invalid IDs)
    SELECT delete_book_club(
        '00000000-0000-0000-0000-000000000000'::UUID,
        '00000000-0000-0000-0000-000000000000'::UUID
    ) INTO test_result;
    
    RAISE NOTICE 'Function test result: %', test_result;
END $$;

-- Show function signature
SELECT 
    'delete_book_club' as function_name,
    'p_auth_user_id UUID, p_book_club_id UUID' as parameters,
    'JSON' as return_type,
    'Allows book club admins to delete their book clubs and all related data' as description;
