-- =====================================================
-- BLOCKING REMOVAL SYSTEM
-- =====================================================
-- This script implements automatic removal of blocked users
-- from book clubs and discussions when they are blocked

-- Function to remove blocked user from book clubs where blocker is admin/owner
CREATE OR REPLACE FUNCTION remove_blocked_user_from_clubs(
    p_blocker_user_id UUID,
    p_blocked_user_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    removed_clubs INTEGER := 0;
    club_record RECORD;
BEGIN
    -- Find all clubs where the blocker is admin/owner
    FOR club_record IN 
        SELECT DISTINCT cm.club_id
        FROM club_memberships cm
        WHERE cm.user_id = p_blocker_user_id 
        AND cm.role IN ('admin', 'owner')
    LOOP
        -- Remove the blocked user from this club
        DELETE FROM club_memberships 
        WHERE user_id = p_blocked_user_id 
        AND club_id = club_record.club_id;
        
        -- Count if any rows were affected
        IF FOUND THEN
            removed_clubs := removed_clubs + 1;
        END IF;
    END LOOP;
    
    RETURN jsonb_build_object(
        'success', true,
        'removed_from_clubs', removed_clubs,
        'message', 'Blocked user removed from book clubs'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', SQLERRM,
            'message', 'Failed to remove blocked user from book clubs'
        );
END;
$$;

-- Function to remove blocked user from discussions where blocker is creator
CREATE OR REPLACE FUNCTION remove_blocked_user_from_discussions(
    p_blocker_user_id UUID,
    p_blocked_user_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    removed_discussions INTEGER := 0;
    discussion_record RECORD;
BEGIN
    -- Find all discussions where the blocker is creator
    FOR discussion_record IN 
        SELECT id
        FROM discussions
        WHERE created_by = p_blocker_user_id
    LOOP
        -- Remove the blocked user from this discussion
        DELETE FROM discussion_participants 
        WHERE user_id = p_blocked_user_id 
        AND discussion_id = discussion_record.id;
        
        -- Count if any rows were affected
        IF FOUND THEN
            removed_discussions := removed_discussions + 1;
        END IF;
    END LOOP;
    
    RETURN jsonb_build_object(
        'success', true,
        'removed_from_discussions', removed_discussions,
        'message', 'Blocked user removed from discussions'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', SQLERRM,
            'message', 'Failed to remove blocked user from discussions'
        );
END;
$$;

-- Enhanced block friend function that includes automatic removal
CREATE OR REPLACE FUNCTION block_friend_with_removal(
    p_blocker_auth_user_id UUID,
    p_blocked_auth_user_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    blocker_internal_id UUID;
    blocked_internal_id UUID;
    block_result JSONB;
    club_removal_result JSONB;
    discussion_removal_result JSONB;
BEGIN
    -- Get internal IDs for both users
    SELECT id INTO blocker_internal_id 
    FROM users 
    WHERE auth_user_id = p_blocker_auth_user_id;
    
    SELECT id INTO blocked_internal_id 
    FROM users 
    WHERE auth_user_id = p_blocked_auth_user_id;
    
    -- Check if users exist
    IF blocker_internal_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Blocker user not found'
        );
    END IF;
    
    IF blocked_internal_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Blocked user not found'
        );
    END IF;
    
    -- Check if already blocked
    IF EXISTS (
        SELECT 1 FROM blocked_users 
        WHERE blocker_id = blocker_internal_id 
        AND blocked_id = blocked_internal_id
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'User is already blocked'
        );
    END IF;
    
    -- Block the user
    INSERT INTO blocked_users (blocker_id, blocked_id, created_at)
    VALUES (blocker_internal_id, blocked_internal_id, NOW());
    
    -- Remove from book clubs
    SELECT remove_blocked_user_from_clubs(blocker_internal_id, blocked_internal_id) 
    INTO club_removal_result;
    
    -- Remove from discussions
    SELECT remove_blocked_user_from_discussions(blocker_internal_id, blocked_internal_id) 
    INTO discussion_removal_result;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'User blocked successfully',
        'club_removal', club_removal_result,
        'discussion_removal', discussion_removal_result
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', SQLERRM,
            'message', 'Failed to block user'
        );
END;
$$;

-- Test the functions
DO $$
DECLARE
    test_result JSONB;
BEGIN
    RAISE NOTICE 'Blocking removal system functions created successfully';
    RAISE NOTICE 'Functions available:';
    RAISE NOTICE '- remove_blocked_user_from_clubs(blocker_user_id, blocked_user_id)';
    RAISE NOTICE '- remove_blocked_user_from_discussions(blocker_user_id, blocked_user_id)';
    RAISE NOTICE '- block_friend_with_removal(blocker_auth_user_id, blocked_auth_user_id)';
END $$;
