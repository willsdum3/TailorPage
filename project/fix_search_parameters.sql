-- =====================================================
-- FIX SEARCH FUNCTION PARAMETER MISMATCH
-- =====================================================
-- The frontend is calling with 'search_term' but function expects 'p_search_term'

-- Drop the existing function
DROP FUNCTION IF EXISTS search_users_by_username(TEXT, INTEGER);

-- Recreate with the correct parameter names that match the frontend call
CREATE OR REPLACE FUNCTION search_users_by_username(
    search_term TEXT, 
    limit_count INTEGER DEFAULT 10
)
RETURNS TABLE (
    id UUID,
    username TEXT,
    name TEXT,
    avatar_url TEXT
) AS $$
BEGIN
    -- Add some debug logging
    RAISE NOTICE 'Searching for: %, limit: %', search_term, limit_count;
    
    RETURN QUERY
    SELECT 
        u.id,
        u.username,
        u.name,
        u.avatar_url
    FROM users u
    WHERE 
        u.username IS NOT NULL
        AND u.username != ''
        AND (
            u.username ILIKE '%' || search_term || '%'
            OR u.name ILIKE '%' || search_term || '%'
        )
    ORDER BY 
        CASE 
            WHEN u.username ILIKE search_term THEN 1  -- Exact match first
            WHEN u.username ILIKE search_term || '%' THEN 2  -- Starts with
            WHEN u.name ILIKE search_term || '%' THEN 3  -- Name starts with
            ELSE 4  -- Contains
        END,
        u.username
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Also fix the invite function to use the original parameter names
DROP FUNCTION IF EXISTS invite_user_to_club(UUID, UUID, TEXT, TEXT);

CREATE OR REPLACE FUNCTION invite_user_to_club(
    auth_user_id UUID,
    club_id_param UUID,
    username_param TEXT,
    message_param TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_inviter_id UUID;
    v_invitee_id UUID;
    v_club_exists BOOLEAN := false;
    v_club_name TEXT;
    v_is_admin BOOLEAN := false;
    v_is_member BOOLEAN := false;
    v_has_pending BOOLEAN := false;
    v_invitation_id UUID;
BEGIN
    -- Step 1: Get inviter's internal user ID
    SELECT users.id INTO v_inviter_id
    FROM users 
    WHERE users.auth_user_id = invite_user_to_club.auth_user_id;
    
    IF v_inviter_id IS NULL THEN
        RETURN json_build_object(
            'success', false, 
            'error', 'Inviter not found in database'
        );
    END IF;
    
    -- Step 2: Verify club exists
    SELECT EXISTS(SELECT 1 FROM book_clubs WHERE id = club_id_param), 
           (SELECT name FROM book_clubs WHERE id = club_id_param LIMIT 1)
    INTO v_club_exists, v_club_name;
    
    IF NOT v_club_exists THEN
        RETURN json_build_object('success', false, 'error', 'Club not found');
    END IF;
    
    -- Step 3: Check admin permissions
    SELECT EXISTS(
        SELECT 1 FROM club_memberships 
        WHERE club_id = club_id_param 
        AND user_id = v_inviter_id 
        AND role IN ('owner', 'admin')
    ) INTO v_is_admin;
    
    IF NOT v_is_admin THEN
        RETURN json_build_object('success', false, 'error', 'Only club admins can send invitations');
    END IF;
    
    -- Step 4: Find invitee by username
    SELECT users.id INTO v_invitee_id
    FROM users 
    WHERE users.username = username_param;
    
    IF v_invitee_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not found: ' || username_param);
    END IF;
    
    -- Step 5: Prevent self-invitation
    IF v_inviter_id = v_invitee_id THEN
        RETURN json_build_object('success', false, 'error', 'Cannot invite yourself');
    END IF;
    
    -- Step 6: Check if already a member
    SELECT EXISTS(
        SELECT 1 FROM club_memberships 
        WHERE club_id = club_id_param AND user_id = v_invitee_id
    ) INTO v_is_member;
    
    IF v_is_member THEN
        RETURN json_build_object('success', false, 'error', 'User is already a member');
    END IF;
    
    -- Step 7: Check for existing pending invitation
    SELECT EXISTS(
        SELECT 1 FROM club_invitations 
        WHERE club_id = club_id_param 
        AND invitee_id = v_invitee_id 
        AND status = 'pending'
        AND expires_at > NOW()
    ) INTO v_has_pending;
    
    IF v_has_pending THEN
        RETURN json_build_object('success', false, 'error', 'User already has a pending invitation');
    END IF;
    
    -- Step 8: Create invitation
    INSERT INTO club_invitations (club_id, inviter_id, invitee_id, message)
    VALUES (club_id_param, v_inviter_id, v_invitee_id, message_param)
    RETURNING id INTO v_invitation_id;
    
    -- Step 9: Return success
    RETURN json_build_object(
        'success', true,
        'invitation_id', v_invitation_id,
        'club_name', v_club_name,
        'invitee_username', username_param,
        'message', 'Invitation sent successfully'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false, 
            'error', 'Database error: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION search_users_by_username TO authenticated;
GRANT EXECUTE ON FUNCTION invite_user_to_club TO authenticated;

-- Test the search function
DO $$
DECLARE
    search_results RECORD;
BEGIN
    -- Test search with common letters
    FOR search_results IN 
        SELECT * FROM search_users_by_username('a', 5)
    LOOP
        RAISE NOTICE 'Found user: % (username: %)', search_results.name, search_results.username;
    END LOOP;
    
    RAISE NOTICE '✅ Search function parameter names fixed to match frontend calls';
    RAISE NOTICE '✅ Function now searches both username and name fields';
END $$;
