-- =====================================================
-- FINAL FIX FOR USERNAME COLUMN AMBIGUITY
-- =====================================================
-- This fixes the column ambiguity in the search function

-- Drop the problematic function
DROP FUNCTION IF EXISTS search_users_by_username(TEXT, INTEGER);

-- Recreate with proper table qualification to avoid ambiguity
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

-- Grant permissions
GRANT EXECUTE ON FUNCTION search_users_by_username TO authenticated;

-- Let's also create a simple debug query to check users without function conflicts
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
    
END $$;

-- Also ensure all other functions are properly qualified
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

-- Grant permissions
GRANT EXECUTE ON FUNCTION invite_user_to_club TO authenticated;

DO $$
BEGIN
    RAISE NOTICE '✅ Fixed all column ambiguity issues';
    RAISE NOTICE '✅ All table columns are now properly qualified with aliases';
    RAISE NOTICE '✅ Search function should now work without ambiguity errors';
    RAISE NOTICE '✅ Check the debug output above to see your users data';
END $$;
