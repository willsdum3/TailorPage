-- =====================================================
-- PROPERLY DROP AND RECREATE INVITATION FUNCTIONS
-- =====================================================
-- This script properly drops existing functions with all possible signatures

-- Drop all possible variations of the invite function
DROP FUNCTION IF EXISTS invite_user_to_club(UUID, UUID, TEXT, TEXT);
DROP FUNCTION IF EXISTS invite_user_to_club(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS invite_user_to_club(p_auth_user_id UUID, p_club_id UUID, p_username TEXT, p_message TEXT);
DROP FUNCTION IF EXISTS invite_user_to_club(auth_user_id UUID, club_id_param UUID, username_param TEXT, message_param TEXT);

-- Drop all possible variations of other functions
DROP FUNCTION IF EXISTS search_users_by_username(TEXT, INTEGER);
DROP FUNCTION IF EXISTS search_users_by_username(TEXT);
DROP FUNCTION IF EXISTS search_users_by_username(p_search_term TEXT, p_limit_count INTEGER);
DROP FUNCTION IF EXISTS search_users_by_username(search_term TEXT, limit_count INTEGER);

DROP FUNCTION IF EXISTS get_user_club_invitations(UUID);
DROP FUNCTION IF EXISTS get_user_club_invitations(p_auth_user_id UUID);
DROP FUNCTION IF EXISTS get_user_club_invitations(auth_user_id UUID);

DROP FUNCTION IF EXISTS respond_to_club_invitation(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS respond_to_club_invitation(p_auth_user_id UUID, p_invitation_id UUID, p_response TEXT);
DROP FUNCTION IF EXISTS respond_to_club_invitation(auth_user_id UUID, invitation_id_param UUID, response TEXT);

DROP FUNCTION IF EXISTS get_club_sent_invitations(UUID, UUID);
DROP FUNCTION IF EXISTS get_club_sent_invitations(p_auth_user_id UUID, p_club_id UUID);
DROP FUNCTION IF EXISTS get_club_sent_invitations(auth_user_id UUID, club_id_param UUID);

-- Now recreate all functions with consistent parameter names and proper table qualification
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
    -- Add some debug logging with proper table qualification
    RAISE NOTICE 'Searching for: %, limit: %', search_term, limit_count;
    RAISE NOTICE 'Total users with usernames: %', (
        SELECT COUNT(*) FROM users u
        WHERE u.username IS NOT NULL AND u.username != ''
    );
    
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
    -- Step 1: Get inviter's internal user ID (properly qualified)
    SELECT u.id INTO v_inviter_id
    FROM users u
    WHERE u.auth_user_id = invite_user_to_club.auth_user_id;
    
    IF v_inviter_id IS NULL THEN
        RETURN json_build_object(
            'success', false, 
            'error', 'Inviter not found in database'
        );
    END IF;
    
    -- Step 2: Verify club exists
    SELECT 
        EXISTS(SELECT 1 FROM book_clubs bc WHERE bc.id = club_id_param), 
        (SELECT bc.name FROM book_clubs bc WHERE bc.id = club_id_param LIMIT 1)
    INTO v_club_exists, v_club_name;
    
    IF NOT v_club_exists THEN
        RETURN json_build_object('success', false, 'error', 'Club not found');
    END IF;
    
    -- Step 3: Check admin permissions
    SELECT EXISTS(
        SELECT 1 FROM club_memberships cm
        WHERE cm.club_id = club_id_param 
        AND cm.user_id = v_inviter_id 
        AND cm.role IN ('owner', 'admin')
    ) INTO v_is_admin;
    
    IF NOT v_is_admin THEN
        RETURN json_build_object('success', false, 'error', 'Only club admins can send invitations');
    END IF;
    
    -- Step 4: Find invitee by username (properly qualified)
    SELECT u.id INTO v_invitee_id
    FROM users u
    WHERE u.username = username_param;
    
    IF v_invitee_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not found: ' || username_param);
    END IF;
    
    -- Step 5: Prevent self-invitation
    IF v_inviter_id = v_invitee_id THEN
        RETURN json_build_object('success', false, 'error', 'Cannot invite yourself');
    END IF;
    
    -- Step 6: Check if already a member
    SELECT EXISTS(
        SELECT 1 FROM club_memberships cm
        WHERE cm.club_id = club_id_param AND cm.user_id = v_invitee_id
    ) INTO v_is_member;
    
    IF v_is_member THEN
        RETURN json_build_object('success', false, 'error', 'User is already a member');
    END IF;
    
    -- Step 7: Check for existing pending invitation
    SELECT EXISTS(
        SELECT 1 FROM club_invitations ci
        WHERE ci.club_id = club_id_param 
        AND ci.invitee_id = v_invitee_id 
        AND ci.status = 'pending'
        AND ci.expires_at > NOW()
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

CREATE OR REPLACE FUNCTION get_user_club_invitations(auth_user_id UUID)
RETURNS TABLE (
    id UUID,
    club_id UUID,
    club_name TEXT,
    club_description TEXT,
    inviter_name TEXT,
    inviter_username TEXT,
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    status TEXT
) AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Get user ID
    SELECT u.id INTO v_user_id
    FROM users u
    WHERE u.auth_user_id = get_user_club_invitations.auth_user_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    RETURN QUERY
    SELECT 
        ci.id,
        ci.club_id,
        bc.name,
        bc.description,
        inviter.name,
        inviter.username,
        ci.message,
        ci.created_at,
        ci.expires_at,
        ci.status
    FROM club_invitations ci
    JOIN book_clubs bc ON ci.club_id = bc.id
    JOIN users inviter ON ci.inviter_id = inviter.id
    WHERE ci.invitee_id = v_user_id
    AND ci.status = 'pending'
    AND ci.expires_at > NOW()
    ORDER BY ci.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION respond_to_club_invitation(
    auth_user_id UUID,
    invitation_id_param UUID,
    response TEXT
)
RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_invitation RECORD;
    v_member_count INTEGER;
BEGIN
    -- Get user ID
    SELECT u.id INTO v_user_id
    FROM users u
    WHERE u.auth_user_id = respond_to_club_invitation.auth_user_id;
    
    IF v_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Validate response
    IF response NOT IN ('accepted', 'declined') THEN
        RETURN json_build_object('success', false, 'error', 'Invalid response');
    END IF;
    
    -- Get invitation
    SELECT ci.*, bc.name as club_name, bc.max_members
    INTO v_invitation
    FROM club_invitations ci
    JOIN book_clubs bc ON ci.club_id = bc.id
    WHERE ci.id = invitation_id_param
    AND ci.invitee_id = v_user_id
    AND ci.status = 'pending'
    AND ci.expires_at > NOW();
    
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'error', 'Invitation not found or expired');
    END IF;
    
    -- If accepting, check club capacity
    IF response = 'accepted' THEN
        SELECT COUNT(*) INTO v_member_count
        FROM club_memberships cm
        WHERE cm.club_id = v_invitation.club_id;
        
        IF v_member_count >= v_invitation.max_members THEN
            RETURN json_build_object('success', false, 'error', 'Club is full');
        END IF;
        
        -- Add to club
        INSERT INTO club_memberships (club_id, user_id, role)
        VALUES (v_invitation.club_id, v_user_id, 'member');
    END IF;
    
    -- Update invitation
    UPDATE club_invitations
    SET status = response, updated_at = NOW()
    WHERE id = invitation_id_param;
    
    RETURN json_build_object(
        'success', true,
        'club_name', v_invitation.club_name,
        'response', response,
        'message', CASE 
            WHEN response = 'accepted' THEN 'Successfully joined the club!'
            ELSE 'Invitation declined'
        END
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'error', 'Error: ' || SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_club_sent_invitations(
    auth_user_id UUID,
    club_id_param UUID
)
RETURNS TABLE (
    id UUID,
    invitee_username TEXT,
    invitee_name TEXT,
    message TEXT,
    status TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    v_user_id UUID;
    v_is_admin BOOLEAN;
BEGIN
    -- Get user ID
    SELECT u.id INTO v_user_id
    FROM users u
    WHERE u.auth_user_id = get_club_sent_invitations.auth_user_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check admin status
    SELECT EXISTS(
        SELECT 1 FROM club_memberships cm
        WHERE cm.club_id = club_id_param 
        AND cm.user_id = v_user_id 
        AND cm.role IN ('owner', 'admin')
    ) INTO v_is_admin;
    
    IF NOT v_is_admin THEN
        RAISE EXCEPTION 'Only admins can view sent invitations';
    END IF;
    
    RETURN QUERY
    SELECT 
        ci.id,
        invitee.username,
        invitee.name,
        ci.message,
        ci.status,
        ci.created_at,
        ci.expires_at
    FROM club_invitations ci
    JOIN users invitee ON ci.invitee_id = invitee.id
    WHERE ci.club_id = club_id_param
    ORDER BY ci.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION search_users_by_username TO authenticated;
GRANT EXECUTE ON FUNCTION invite_user_to_club TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_club_invitations TO authenticated;
GRANT EXECUTE ON FUNCTION respond_to_club_invitation TO authenticated;
GRANT EXECUTE ON FUNCTION get_club_sent_invitations TO authenticated;

-- Debug and test
DO $$
DECLARE
    user_count INTEGER;
    username_count INTEGER;
    sample_user RECORD;
BEGIN
    -- Count total users
    SELECT COUNT(*) INTO user_count FROM users;
    RAISE NOTICE 'Total users in database: %', user_count;
    
    -- Count users with usernames
    SELECT COUNT(*) INTO username_count 
    FROM users u 
    WHERE u.username IS NOT NULL AND u.username != '';
    RAISE NOTICE 'Users with usernames: %', username_count;
    
    -- Show some sample usernames
    RAISE NOTICE 'Sample users with usernames:';
    FOR sample_user IN 
        SELECT u.username, u.name 
        FROM users u 
        WHERE u.username IS NOT NULL AND u.username != '' 
        LIMIT 5
    LOOP
        RAISE NOTICE '  Username: %, Name: %', sample_user.username, sample_user.name;
    END LOOP;
    
    -- Test the search function
    RAISE NOTICE 'Testing search function with "a":';
    FOR sample_user IN 
        SELECT * FROM search_users_by_username('a', 3)
    LOOP
        RAISE NOTICE '  Found: % (@%)', sample_user.name, sample_user.username;
    END LOOP;
    
    RAISE NOTICE '✅ All functions recreated successfully with proper parameter names';
    RAISE NOTICE '✅ All table columns properly qualified to avoid ambiguity';
    RAISE NOTICE '✅ Functions should now work without errors';
    
END $$;
