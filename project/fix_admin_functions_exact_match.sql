-- Fix admin functions to match EXACT frontend parameter names

-- 1. Drop ALL versions of both functions
DROP FUNCTION IF EXISTS promote_user_to_admin(UUID, UUID, UUID);
DROP FUNCTION IF EXISTS promote_user_to_admin(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS promote_user_to_admin;

DROP FUNCTION IF EXISTS invite_user_to_club(UUID, UUID, TEXT, TEXT);
DROP FUNCTION IF EXISTS invite_user_to_club(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS invite_user_to_club;

-- 2. Create promote_user_to_admin with EXACT parameter names from frontend
CREATE OR REPLACE FUNCTION promote_user_to_admin(
    auth_user_id UUID,
    club_id_param UUID,
    user_to_promote_id UUID
)
RETURNS JSON AS $$
DECLARE
    admin_internal_id UUID;
    user_to_promote_internal_id UUID;
    is_admin BOOLEAN;
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
    
    -- Check if the admin is actually an admin of the club
    SELECT EXISTS (
        SELECT 1 FROM book_club_members 
        WHERE book_club_members.user_id = admin_internal_id 
        AND book_club_members.club_id = promote_user_to_admin.club_id_param
        AND book_club_members.role IN ('admin', 'owner')
    ) INTO is_admin;
    
    IF NOT is_admin THEN
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
    
    -- Create notification for the promoted user
    BEGIN
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
    EXCEPTION
        WHEN OTHERS THEN
            -- Ignore notification errors
            NULL;
    END;
    
    RETURN json_build_object('success', true, 'message', 'User promoted to admin successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Create invite_user_to_club with EXACT parameter names from frontend
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
    invitation_exists BOOLEAN;
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
    
    -- Check if there's already a pending invitation
    SELECT EXISTS (
        SELECT 1 FROM club_invitations 
        WHERE club_invitations.invitee_id = invitee_internal_id 
        AND club_invitations.club_id = invite_user_to_club.club_id_param
        AND club_invitations.status = 'pending'
    ) INTO invitation_exists;
    
    IF invitation_exists THEN
        RETURN json_build_object('success', false, 'error', 'User already has a pending invitation');
    END IF;
    
    -- Create the invitation using the correct field names
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
    
    -- Create notification for the invited user
    BEGIN
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
    EXCEPTION
        WHEN OTHERS THEN
            -- Ignore notification errors
            NULL;
    END;
    
    RETURN json_build_object('success', true, 'message', 'Invitation sent successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Verify the functions are created correctly
SELECT 
    'Functions Created Successfully' as check_type,
    routine_name,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name IN ('promote_user_to_admin', 'invite_user_to_club')
ORDER BY routine_name;

-- 5. Check function parameters to confirm they match frontend
SELECT 
    'promote_user_to_admin Parameters' as check_type,
    parameter_name,
    data_type,
    ordinal_position
FROM information_schema.parameters 
WHERE specific_schema = 'public'
AND specific_name IN (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_schema = 'public' 
    AND routine_name = 'promote_user_to_admin'
)
ORDER BY ordinal_position;

SELECT 
    'invite_user_to_club Parameters' as check_type,
    parameter_name,
    data_type,
    ordinal_position
FROM information_schema.parameters 
WHERE specific_schema = 'public'
AND specific_name IN (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_schema = 'public' 
    AND routine_name = 'invite_user_to_club'
)
ORDER BY ordinal_position;




















