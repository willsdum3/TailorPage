-- Add admin functions for book club management
-- This adds comprehensive admin capabilities to book clubs

-- Function to invite users to book club (admin only)
CREATE OR REPLACE FUNCTION invite_user_to_book_club(
    auth_user_id UUID,
    club_id_param UUID,
    invited_user_id UUID
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    user_uuid UUID;
    is_admin BOOLEAN;
    club_exists BOOLEAN;
    user_already_member BOOLEAN;
    club_full BOOLEAN;
    current_member_count INTEGER;
    max_members INTEGER;
BEGIN
    -- Get user UUID
    SELECT u.id INTO user_uuid 
    FROM users u 
    WHERE u.auth_user_id = invite_user_to_book_club.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RETURN QUERY SELECT false, 'User not found';
        RETURN;
    END IF;
    
    -- Check if user is admin of the club
    SELECT EXISTS(
        SELECT 1 FROM club_memberships 
        WHERE club_id = invite_user_to_book_club.club_id_param 
        AND user_id = user_uuid
        AND role = 'admin'
    ) INTO is_admin;
    
    IF NOT is_admin THEN
        RETURN QUERY SELECT false, 'Only admins can invite users';
        RETURN;
    END IF;
    
    -- Check if club exists
    SELECT EXISTS(SELECT 1 FROM book_clubs WHERE id = invite_user_to_book_club.club_id_param) INTO club_exists;
    IF NOT club_exists THEN
        RETURN QUERY SELECT false, 'Book club not found';
        RETURN;
    END IF;
    
    -- Check if user is already a member
    SELECT EXISTS(
        SELECT 1 FROM club_memberships 
        WHERE club_id = invite_user_to_book_club.club_id_param 
        AND user_id = invited_user_id
    ) INTO user_already_member;
    
    IF user_already_member THEN
        RETURN QUERY SELECT false, 'User is already a member';
        RETURN;
    END IF;
    
    -- Check if club is full
    SELECT COUNT(*) INTO current_member_count
    FROM club_memberships 
    WHERE club_id = invite_user_to_book_club.club_id_param;
    
    SELECT max_members INTO max_members
    FROM book_clubs 
    WHERE id = invite_user_to_book_club.club_id_param;
    
    IF current_member_count >= max_members THEN
        RETURN QUERY SELECT false, 'Book club is full';
        RETURN;
    END IF;
    
    -- Add user to club
    INSERT INTO club_memberships (club_id, user_id, role, joined_at)
    VALUES (invite_user_to_book_club.club_id_param, invited_user_id, 'member', NOW());
    
    RETURN QUERY SELECT true, 'User invited successfully';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to remove user from book club (admin only)
CREATE OR REPLACE FUNCTION remove_user_from_book_club(
    auth_user_id UUID,
    club_id_param UUID,
    user_to_remove_id UUID
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    user_uuid UUID;
    is_admin BOOLEAN;
    user_to_remove_role TEXT;
    is_removing_self BOOLEAN;
BEGIN
    -- Get user UUID
    SELECT u.id INTO user_uuid 
    FROM users u 
    WHERE u.auth_user_id = remove_user_from_book_club.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RETURN QUERY SELECT false, 'User not found';
        RETURN;
    END IF;
    
    -- Check if user is admin of the club
    SELECT EXISTS(
        SELECT 1 FROM club_memberships 
        WHERE club_id = remove_user_from_book_club.club_id_param 
        AND user_id = user_uuid
        AND role = 'admin'
    ) INTO is_admin;
    
    IF NOT is_admin THEN
        RETURN QUERY SELECT false, 'Only admins can remove users';
        RETURN;
    END IF;
    
    -- Check if trying to remove self
    SELECT (user_uuid = user_to_remove_id) INTO is_removing_self;
    IF is_removing_self THEN
        RETURN QUERY SELECT false, 'Cannot remove yourself. Use leave club instead.';
        RETURN;
    END IF;
    
    -- Get role of user to be removed
    SELECT role INTO user_to_remove_role
    FROM club_memberships 
    WHERE club_id = remove_user_from_book_club.club_id_param 
    AND user_id = user_to_remove_id;
    
    IF user_to_remove_role IS NULL THEN
        RETURN QUERY SELECT false, 'User is not a member of this club';
        RETURN;
    END IF;
    
    -- Remove user from club
    DELETE FROM club_memberships 
    WHERE club_id = remove_user_from_book_club.club_id_param 
    AND user_id = user_to_remove_id;
    
    RETURN QUERY SELECT true, 'User removed successfully';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to promote user to admin (admin only)
CREATE OR REPLACE FUNCTION promote_user_to_admin(
    auth_user_id UUID,
    club_id_param UUID,
    user_to_promote_id UUID
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    user_uuid UUID;
    is_admin BOOLEAN;
    user_to_promote_role TEXT;
BEGIN
    -- Get user UUID
    SELECT u.id INTO user_uuid 
    FROM users u 
    WHERE u.auth_user_id = promote_user_to_admin.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RETURN QUERY SELECT false, 'User not found';
        RETURN;
    END IF;
    
    -- Check if user is admin of the club
    SELECT EXISTS(
        SELECT 1 FROM club_memberships 
        WHERE club_id = promote_user_to_admin.club_id_param 
        AND user_id = user_uuid
        AND role = 'admin'
    ) INTO is_admin;
    
    IF NOT is_admin THEN
        RETURN QUERY SELECT false, 'Only admins can promote users';
        RETURN;
    END IF;
    
    -- Get role of user to be promoted
    SELECT role INTO user_to_promote_role
    FROM club_memberships 
    WHERE club_id = promote_user_to_admin.club_id_param 
    AND user_id = user_to_promote_id;
    
    IF user_to_promote_role IS NULL THEN
        RETURN QUERY SELECT false, 'User is not a member of this club';
        RETURN;
    END IF;
    
    IF user_to_promote_role = 'admin' THEN
        RETURN QUERY SELECT false, 'User is already an admin';
        RETURN;
    END IF;
    
    -- Promote user to admin
    UPDATE club_memberships 
    SET role = 'admin'
    WHERE club_id = promote_user_to_admin.club_id_param 
    AND user_id = user_to_promote_id;
    
    RETURN QUERY SELECT true, 'User promoted to admin successfully';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update book club details (admin only)
CREATE OR REPLACE FUNCTION update_book_club_details(
    auth_user_id UUID,
    club_id_param UUID,
    new_name TEXT,
    new_description TEXT,
    new_current_book_title TEXT,
    new_current_book_author TEXT,
    new_meeting_info TEXT
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    user_uuid UUID;
    is_admin BOOLEAN;
BEGIN
    -- Get user UUID
    SELECT u.id INTO user_uuid 
    FROM users u 
    WHERE u.auth_user_id = update_book_club_details.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RETURN QUERY SELECT false, 'User not found';
        RETURN;
    END IF;
    
    -- Check if user is admin of the club
    SELECT EXISTS(
        SELECT 1 FROM club_memberships 
        WHERE club_id = update_book_club_details.club_id_param 
        AND user_id = user_uuid
        AND role = 'admin'
    ) INTO is_admin;
    
    IF NOT is_admin THEN
        RETURN QUERY SELECT false, 'Only admins can update club details';
        RETURN;
    END IF;
    
    -- Update club details
    UPDATE book_clubs 
    SET 
        name = COALESCE(new_name, name),
        description = COALESCE(new_description, description),
        current_book_title = COALESCE(new_current_book_title, current_book_title),
        current_book_author = COALESCE(new_current_book_author, current_book_author),
        meeting_info = COALESCE(new_meeting_info, meeting_info),
        updated_at = NOW()
    WHERE id = update_book_club_details.club_id_param;
    
    RETURN QUERY SELECT true, 'Club details updated successfully';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION invite_user_to_book_club(UUID, UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION remove_user_from_book_club(UUID, UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION promote_user_to_admin(UUID, UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_book_club_details(UUID, UUID, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;
