-- Complete Tailor Mates functionality restore - get everything working again

-- 1. Drop ALL problematic functions and start completely fresh
DROP FUNCTION IF EXISTS promote_user_to_admin CASCADE;
DROP FUNCTION IF EXISTS promote_member_to_admin CASCADE;
DROP FUNCTION IF EXISTS promote_user_to_admin_v2 CASCADE;
DROP FUNCTION IF EXISTS invite_user_to_club CASCADE;
DROP FUNCTION IF EXISTS invite_user_to_book_club CASCADE;
DROP FUNCTION IF EXISTS respond_to_club_invitation CASCADE;
DROP FUNCTION IF EXISTS accept_club_invitation CASCADE;

-- 2. Create ALL essential functions with simple, working implementations

-- Promote user to admin function
CREATE OR REPLACE FUNCTION promote_user_to_admin(
    auth_user_id UUID,
    club_id_param UUID,
    user_to_promote_id UUID
)
RETURNS JSON AS $$
DECLARE
    admin_internal_id UUID;
    user_to_promote_internal_id UUID;
BEGIN
    -- Get the internal user ID of the admin
    SELECT id INTO admin_internal_id
    FROM users
    WHERE users.auth_user_id = promote_user_to_admin.auth_user_id;
    
    IF admin_internal_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Admin user not found');
    END IF;
    
    -- user_to_promote_id is already the internal ID from frontend
    user_to_promote_internal_id := promote_user_to_admin.user_to_promote_id;
    
    -- Simple admin check
    IF NOT EXISTS (
        SELECT 1 FROM book_club_members 
        WHERE book_club_members.user_id = admin_internal_id 
        AND book_club_members.club_id = promote_user_to_admin.club_id_param
        AND book_club_members.role IN ('admin', 'owner')
    ) THEN
        RETURN json_build_object('success', false, 'error', 'You are not an admin of this club');
    END IF;
    
    -- Check if the user to promote is a member of the club
    IF NOT EXISTS (
        SELECT 1 FROM book_club_members 
        WHERE book_club_members.user_id = user_to_promote_internal_id 
        AND book_club_members.club_id = promote_user_to_admin.club_id_param
    ) THEN
        RETURN json_build_object('success', false, 'error', 'User is not a member of this club');
    END IF;
    
    -- Promote the user to admin
    UPDATE book_club_members 
    SET role = 'admin'
    WHERE book_club_members.user_id = user_to_promote_internal_id 
    AND book_club_members.club_id = promote_user_to_admin.club_id_param;
    
    -- Create notification
    INSERT INTO notifications (
        user_id,
        type,
        title,
        message,
        related_id,
        related_name
    ) VALUES (
        user_to_promote_internal_id,
        'club_promotion',
        'You have been promoted!',
        'You have been promoted to admin',
        promote_user_to_admin.club_id_param,
        (SELECT name FROM book_clubs WHERE id = promote_user_to_admin.club_id_param)
    );
    
    RETURN json_build_object('success', true, 'message', 'User promoted to admin successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Invite user to club function
CREATE OR REPLACE FUNCTION invite_user_to_club(
    auth_user_id UUID,
    club_id_param UUID,
    username_param TEXT,
    message_param TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    admin_internal_id UUID;
    invitee_internal_id UUID;
    is_admin BOOLEAN;
BEGIN
    -- Get the internal user ID of the admin
    SELECT id INTO admin_internal_id
    FROM users
    WHERE users.auth_user_id = invite_user_to_club.auth_user_id;
    
    IF admin_internal_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Admin user not found');
    END IF;
    
    -- Get the internal user ID of the user to invite
    SELECT id INTO invitee_internal_id
    FROM users
    WHERE users.username = invite_user_to_club.username_param;
    
    IF invitee_internal_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Check if the admin is actually an admin of the club
    SELECT EXISTS (
        SELECT 1 FROM book_club_members 
        WHERE book_club_members.user_id = admin_internal_id 
        AND book_club_members.club_id = invite_user_to_club.club_id_param
        AND book_club_members.role IN ('admin', 'owner')
    ) INTO is_admin;
    
    IF NOT is_admin THEN
        RETURN json_build_object('success', false, 'error', 'You are not an admin of this club');
    END IF;
    
    -- Check if the user is already a member
    IF EXISTS (
        SELECT 1 FROM book_club_members 
        WHERE book_club_members.user_id = invitee_internal_id 
        AND book_club_members.club_id = invite_user_to_club.club_id_param
    ) THEN
        RETURN json_build_object('success', false, 'error', 'User is already a member of this club');
    END IF;
    
    -- Create the invitation
    INSERT INTO club_invitations (
        club_id,
        inviter_id,
        invitee_id,
        message,
        status,
        expires_at
    ) VALUES (
        invite_user_to_club.club_id_param,
        admin_internal_id,
        invitee_internal_id,
        message_param,
        'pending',
        NOW() + INTERVAL '7 days'
    );
    
    -- Create notification
    INSERT INTO notifications (
        user_id,
        type,
        title,
        message,
        related_id,
        related_name
    ) VALUES (
        invitee_internal_id,
        'club_invitation',
        'You have been invited!',
        COALESCE(message_param, 'You have been invited to join a book club'),
        invite_user_to_club.club_id_param,
        (SELECT name FROM book_clubs WHERE id = invite_user_to_club.club_id_param)
    );
    
    RETURN json_build_object('success', true, 'message', 'Invitation sent successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Respond to club invitation function
CREATE OR REPLACE FUNCTION respond_to_club_invitation(
    auth_user_id UUID,
    invitation_id_param UUID,
    response TEXT
)
RETURNS JSON AS $$
DECLARE
    user_internal_id UUID;
    invitation_record RECORD;
BEGIN
    -- Get the internal user ID
    SELECT id INTO user_internal_id
    FROM users
    WHERE users.auth_user_id = respond_to_club_invitation.auth_user_id;
    
    IF user_internal_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Get the invitation details
    SELECT * INTO invitation_record
    FROM club_invitations
    WHERE id = respond_to_club_invitation.invitation_id_param
    AND invitee_id = user_internal_id
    AND status = 'pending';
    
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'error', 'Invitation not found or already processed');
    END IF;
    
    -- Check if invitation has expired
    IF invitation_record.expires_at < NOW() THEN
        RETURN json_build_object('success', false, 'error', 'Invitation has expired');
    END IF;
    
    -- Handle the response
    IF response = 'accepted' THEN
        -- Check if user is already a member
        IF EXISTS (
            SELECT 1 FROM book_club_members 
            WHERE user_id = user_internal_id 
            AND club_id = invitation_record.club_id
        ) THEN
            RETURN json_build_object('success', false, 'error', 'User is already a member of this club');
        END IF;
        
        -- Add user to the club
        INSERT INTO book_club_members (user_id, club_id, role, joined_at)
        VALUES (user_internal_id, invitation_record.club_id, 'member', NOW());
        
        -- Update invitation status
        UPDATE club_invitations 
        SET status = 'accepted', updated_at = NOW()
        WHERE id = respond_to_club_invitation.invitation_id_param;
        
        RETURN json_build_object('success', true, 'message', 'Successfully joined the book club');
        
    ELSIF response = 'declined' THEN
        -- Update invitation status
        UPDATE club_invitations 
        SET status = 'declined', updated_at = NOW()
        WHERE id = respond_to_club_invitation.invitation_id_param;
        
        RETURN json_build_object('success', true, 'message', 'Invitation declined');
        
    ELSE
        RETURN json_build_object('success', false, 'error', 'Invalid response. Must be "accepted" or "declined"');
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Verify all functions were created
SELECT 
    'Functions Created' as check_type,
    routine_name,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name IN ('promote_user_to_admin', 'invite_user_to_club', 'respond_to_club_invitation')
ORDER BY routine_name;
