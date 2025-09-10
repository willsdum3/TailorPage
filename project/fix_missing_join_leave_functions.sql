-- Add missing join_book_club and leave_book_club functions
-- These functions are needed for users to join and leave book clubs

-- Create join_book_club function
CREATE OR REPLACE FUNCTION join_book_club(
    auth_user_id UUID,
    club_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
    existing_membership RECORD;
    current_member_count INTEGER;
    max_members INTEGER;
BEGIN
    -- Get user UUID from auth_user_id
    SELECT u.id INTO user_uuid 
    FROM users u 
    WHERE u.auth_user_id = join_book_club.auth_user_id;
    
    -- If user not found, raise error
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if user is already a member
    SELECT * INTO existing_membership
    FROM club_memberships 
    WHERE club_memberships.club_id = join_book_club.club_id 
    AND club_memberships.user_id = user_uuid;
    
    -- If already a member, return true
    IF existing_membership IS NOT NULL THEN
        RETURN true;
    END IF;
    
    -- Check if club is full
    SELECT 
        COUNT(*) as current_count,
        bc.max_members
    INTO current_member_count, max_members
    FROM club_memberships cm
    JOIN book_clubs bc ON cm.club_id = bc.id
    WHERE cm.club_id = join_book_club.club_id
    GROUP BY bc.max_members;
    
    -- If club is full, raise error
    IF current_member_count >= max_members THEN
        RAISE EXCEPTION 'Book club is full';
    END IF;
    
    -- Add user as a member with 'member' role
    INSERT INTO club_memberships (club_id, user_id, role)
    VALUES (join_book_club.club_id, user_uuid, 'member');
    
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create leave_book_club function
CREATE OR REPLACE FUNCTION leave_book_club(
    auth_user_id UUID,
    club_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
    user_role TEXT;
BEGIN
    -- Get user UUID from auth_user_id
    SELECT u.id INTO user_uuid 
    FROM users u 
    WHERE u.auth_user_id = leave_book_club.auth_user_id;
    
    -- If user not found, raise error
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Get user's role in the club
    SELECT role INTO user_role
    FROM club_memberships 
    WHERE club_memberships.club_id = leave_book_club.club_id 
    AND club_memberships.user_id = user_uuid;
    
    -- If user is not a member, return false
    IF user_role IS NULL THEN
        RETURN false;
    END IF;
    
    -- If user is the admin/creator, don't allow them to leave
    -- (They should transfer ownership or delete the club instead)
    IF user_role = 'admin' THEN
        RAISE EXCEPTION 'Club admin cannot leave. Transfer ownership or delete the club instead.';
    END IF;
    
    -- Remove user from the club
    DELETE FROM club_memberships 
    WHERE club_memberships.club_id = leave_book_club.club_id 
    AND club_memberships.user_id = user_uuid;
    
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION join_book_club(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION leave_book_club(UUID, UUID) TO authenticated;
