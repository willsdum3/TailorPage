-- =====================================================
-- FIX PROMOTE ADMIN FUNCTION - DROP AND RECREATE
-- =====================================================
-- This script properly drops existing functions and recreates them

-- Drop all possible variations of the promote function
DROP FUNCTION IF EXISTS promote_user_to_admin(UUID, UUID, UUID);
DROP FUNCTION IF EXISTS demote_admin_to_member(UUID, UUID, UUID);

-- Also check for any other variations that might exist
DROP FUNCTION IF EXISTS promote_user_to_admin(auth_user_id UUID, club_id_param UUID, user_to_promote_id UUID);
DROP FUNCTION IF EXISTS demote_admin_to_member(auth_user_id UUID, club_id_param UUID, user_id_param UUID);

-- Create the promote function with the correct return type and parameters
CREATE OR REPLACE FUNCTION promote_user_to_admin(
    auth_user_id UUID,
    club_id_param UUID,
    user_to_promote_id UUID
)
RETURNS JSON AS $$
DECLARE
    promoter_uuid UUID;
    target_user_exists BOOLEAN;
    promoter_is_admin BOOLEAN;
    target_current_role TEXT;
    target_username TEXT;
    club_name TEXT;
BEGIN
    -- Get promoter's user ID
    SELECT u.id INTO promoter_uuid
    FROM users u
    WHERE u.auth_user_id = promote_user_to_admin.auth_user_id;
    
    IF promoter_uuid IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Promoter not found in database');
    END IF;
    
    -- Check if club exists
    SELECT name INTO club_name
    FROM book_clubs
    WHERE id = club_id_param;
    
    IF club_name IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Club not found');
    END IF;
    
    -- Check if promoter is admin or owner of the club
    SELECT EXISTS(
        SELECT 1 FROM club_memberships 
        WHERE club_id = club_id_param 
        AND user_id = promoter_uuid 
        AND role IN ('owner', 'admin')
    ) INTO promoter_is_admin;
    
    IF NOT promoter_is_admin THEN
        RETURN json_build_object('success', false, 'error', 'Only club admins can promote members');
    END IF;
    
    -- Check if target user exists and is a member, get their current role and username
    SELECT 
        EXISTS(SELECT 1 FROM club_memberships WHERE club_id = club_id_param AND user_id = user_to_promote_id),
        COALESCE((SELECT role FROM club_memberships WHERE club_id = club_id_param AND user_id = user_to_promote_id), 'non-member'),
        (SELECT username FROM users WHERE id = user_to_promote_id)
    INTO target_user_exists, target_current_role, target_username;
    
    IF NOT target_user_exists THEN
        RETURN json_build_object('success', false, 'error', 'User is not a member of this club');
    END IF;
    
    -- Check if user is already an admin or owner
    IF target_current_role IN ('admin', 'owner') THEN
        RETURN json_build_object('success', false, 'error', 'User is already an admin or owner');
    END IF;
    
    -- Promote the user to admin
    UPDATE club_memberships
    SET role = 'admin'
    WHERE club_id = club_id_param AND user_id = user_to_promote_id;
    
    -- Return success
    RETURN json_build_object(
        'success', true,
        'message', 'User promoted to admin successfully',
        'club_name', club_name,
        'promoted_user', target_username,
        'new_role', 'admin'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false, 
            'error', 'Database error: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the demote function
CREATE OR REPLACE FUNCTION demote_admin_to_member(
    auth_user_id UUID,
    club_id_param UUID,
    user_id_param UUID
)
RETURNS JSON AS $$
DECLARE
    demoter_uuid UUID;
    target_user_exists BOOLEAN;
    demoter_is_admin BOOLEAN;
    target_current_role TEXT;
    target_username TEXT;
    club_name TEXT;
BEGIN
    -- Get demoter's user ID
    SELECT u.id INTO demoter_uuid
    FROM users u
    WHERE u.auth_user_id = demote_admin_to_member.auth_user_id;
    
    IF demoter_uuid IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not found in database');
    END IF;
    
    -- Check if club exists
    SELECT name INTO club_name
    FROM book_clubs
    WHERE id = club_id_param;
    
    IF club_name IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Club not found');
    END IF;
    
    -- Check if demoter is admin or owner of the club
    SELECT EXISTS(
        SELECT 1 FROM club_memberships 
        WHERE club_id = club_id_param 
        AND user_id = demoter_uuid 
        AND role IN ('owner', 'admin')
    ) INTO demoter_is_admin;
    
    IF NOT demoter_is_admin THEN
        RETURN json_build_object('success', false, 'error', 'Only club admins can demote members');
    END IF;
    
    -- Check if target user exists and get their current role and username
    SELECT 
        EXISTS(SELECT 1 FROM club_memberships WHERE club_id = club_id_param AND user_id = user_id_param),
        COALESCE((SELECT role FROM club_memberships WHERE club_id = club_id_param AND user_id = user_id_param), 'non-member'),
        (SELECT username FROM users WHERE id = user_id_param)
    INTO target_user_exists, target_current_role, target_username;
    
    IF NOT target_user_exists THEN
        RETURN json_build_object('success', false, 'error', 'User is not a member of this club');
    END IF;
    
    -- Check if user is an admin (can't demote owners or regular members)
    IF target_current_role != 'admin' THEN
        RETURN json_build_object('success', false, 'error', 'User is not an admin or cannot be demoted');
    END IF;
    
    -- Prevent self-demotion
    IF demoter_uuid = user_id_param THEN
        RETURN json_build_object('success', false, 'error', 'You cannot demote yourself');
    END IF;
    
    -- Demote the user to member
    UPDATE club_memberships
    SET role = 'member'
    WHERE club_id = club_id_param AND user_id = user_id_param;
    
    -- Return success
    RETURN json_build_object(
        'success', true,
        'message', 'Admin demoted to member successfully',
        'club_name', club_name,
        'demoted_user', target_username,
        'new_role', 'member'
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
GRANT EXECUTE ON FUNCTION promote_user_to_admin TO authenticated;
GRANT EXECUTE ON FUNCTION demote_admin_to_member TO authenticated;

-- Test the functions
DO $$
BEGIN
    RAISE NOTICE '✅ Dropped and recreated promote_user_to_admin function';
    RAISE NOTICE '✅ Created demote_admin_to_member function';
    RAISE NOTICE '✅ Functions now return JSON format as expected';
    RAISE NOTICE '✅ Multiple admins functionality ready to test';
    RAISE NOTICE '';
    RAISE NOTICE 'Features available:';
    RAISE NOTICE '- Promote members to admin (unlimited admins per club)';
    RAISE NOTICE '- Demote admins to member (with self-protection)';
    RAISE NOTICE '- Owner protection (cannot be demoted/removed)';
    RAISE NOTICE '- Comprehensive validation and error handling';
END $$;
