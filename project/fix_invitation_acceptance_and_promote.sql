-- Fix invitation acceptance and promote to admin issues

-- 1. First, let's check what functions exist for accepting invitations
SELECT 
    'Functions with accept/respond in name' as check_type,
    routine_name,
    routine_type,
    data_type as return_type,
    specific_name
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND (routine_name ILIKE '%accept%' OR routine_name ILIKE '%respond%' OR routine_name ILIKE '%invitation%')
ORDER BY routine_name, specific_name;

-- 2. Check for any triggers that might be causing the "user" field error
SELECT 
    'Functions with user field references' as check_type,
    routine_name,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_definition ILIKE '%NEW.user%';

-- 3. Check current promote_user_to_admin function
SELECT 
    'Current promote_user_to_admin function' as check_type,
    routine_name,
    routine_type,
    data_type as return_type,
    specific_name
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name = 'promote_user_to_admin';

-- 4. Drop and recreate promote_user_to_admin with exact frontend parameters
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

-- 5. Create or fix the accept invitation function
CREATE OR REPLACE FUNCTION accept_club_invitation(
    auth_user_id UUID,
    invitation_id UUID
)
RETURNS JSON AS $$
DECLARE
    user_internal_id UUID;
    invitation_record RECORD;
BEGIN
    -- Get the internal user ID
    SELECT id INTO user_internal_id
    FROM users
    WHERE users.auth_user_id = accept_club_invitation.auth_user_id;
    
    IF user_internal_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Get the invitation details
    SELECT * INTO invitation_record
    FROM club_invitations
    WHERE id = accept_club_invitation.invitation_id
    AND invitee_id = user_internal_id
    AND status = 'pending';
    
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'error', 'Invitation not found or already processed');
    END IF;
    
    -- Check if invitation has expired
    IF invitation_record.expires_at < NOW() THEN
        RETURN json_build_object('success', false, 'error', 'Invitation has expired');
    END IF;
    
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
    WHERE id = accept_club_invitation.invitation_id;
    
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
    
    RETURN json_build_object('success', true, 'message', 'Successfully joined the book club');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Verify the functions were created correctly
SELECT 
    'Functions Created Successfully' as check_type,
    routine_name,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name IN ('promote_user_to_admin', 'accept_club_invitation')
ORDER BY routine_name;

-- 7. Check function parameters
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
    'accept_club_invitation Parameters' as check_type,
    parameter_name,
    data_type,
    ordinal_position
FROM information_schema.parameters 
WHERE specific_schema = 'public'
AND specific_name IN (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_schema = 'public' 
    AND routine_name = 'accept_club_invitation'
)
ORDER BY ordinal_position;







