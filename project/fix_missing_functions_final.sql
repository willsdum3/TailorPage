-- Fix the actual missing functions that frontend is calling

-- 1. Check what functions the frontend is actually calling
SELECT 
    'Frontend calls respond_to_club_invitation' as check_type,
    'Need to create this function' as status;

-- 2. Drop any existing versions
DROP FUNCTION IF EXISTS respond_to_club_invitation(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS respond_to_club_invitation CASCADE;

-- 3. Create the correct respond_to_club_invitation function that frontend is calling
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
        
        -- Create notification for club admins
        BEGIN
            INSERT INTO notifications (
                user_id,
                type,
                title,
                message,
                related_id,
                related_name
            )
            SELECT 
                bcm.user_id,
                'club_new_member',
                'New member joined!',
                (SELECT name FROM users WHERE id = user_internal_id) || ' joined your book club',
                invitation_record.club_id,
                (SELECT name FROM book_clubs WHERE id = invitation_record.club_id)
            FROM book_club_members bcm
            WHERE bcm.club_id = invitation_record.club_id
            AND bcm.role IN ('admin', 'owner');
        EXCEPTION
            WHEN OTHERS THEN
                -- Ignore notification errors
                NULL;
        END;
        
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

-- 4. Check if promote_user_to_admin function exists and has correct signature
SELECT 
    'Current promote_user_to_admin functions' as check_type,
    routine_name,
    data_type as return_type,
    specific_name
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name = 'promote_user_to_admin';

-- 5. If promote_user_to_admin doesn't exist or has wrong signature, recreate it
DROP FUNCTION IF EXISTS promote_user_to_admin(UUID, UUID, UUID);
DROP FUNCTION IF EXISTS promote_user_to_admin(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS promote_user_to_admin CASCADE;

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

-- 6. Verify both functions were created correctly
SELECT 
    'Functions Created Successfully' as check_type,
    routine_name,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name IN ('promote_user_to_admin', 'respond_to_club_invitation')
ORDER BY routine_name;

-- 7. Check function parameters
SELECT 
    'respond_to_club_invitation Parameters' as check_type,
    parameter_name,
    data_type,
    ordinal_position
FROM information_schema.parameters 
WHERE specific_schema = 'public'
AND specific_name IN (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_schema = 'public' 
    AND routine_name = 'respond_to_club_invitation'
)
ORDER BY ordinal_position;

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







