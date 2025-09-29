-- Fix database function errors based on console output
-- This script addresses the specific errors found in testing

-- 1. Fix invite_user_to_club function - ambiguous auth_user_id reference
DROP FUNCTION IF EXISTS invite_user_to_club(UUID, UUID, TEXT, TEXT);
CREATE OR REPLACE FUNCTION invite_user_to_club(
    auth_user_id UUID,
    club_id_param UUID,
    username_param TEXT,
    message_param TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    target_user_id UUID;
    target_name TEXT;
    club_name TEXT;
    club_creator_id UUID;
    invitation_id UUID;
BEGIN
    -- Get target user by username
    SELECT u.id, u.name INTO target_user_id, target_name
    FROM users u 
    WHERE u.username = username_param;
    
    IF target_user_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'User not found'
        );
    END IF;
    
    -- Check if user is already a member
    IF EXISTS (
        SELECT 1 FROM book_club_members bcm 
        WHERE bcm.club_id = club_id_param 
        AND bcm.user_id = target_user_id
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'User is already a member of this club'
        );
    END IF;
    
    -- Get club details and verify admin permissions
    SELECT bc.name, bc.creator_id INTO club_name, club_creator_id
    FROM book_clubs bc
    WHERE bc.id = club_id_param;
    
    IF club_name IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Club not found'
        );
    END IF;
    
    -- Check if current user is admin (creator or has admin role)
    IF NOT EXISTS (
        SELECT 1 FROM book_club_members bcm
        WHERE bcm.club_id = club_id_param 
        AND bcm.user_id = (
            SELECT id FROM users WHERE auth_user_id = users.auth_user_id
        )
        AND (bcm.role = 'admin' OR bcm.user_id = club_creator_id)
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Only admins can invite users to clubs'
        );
    END IF;
    
    -- Create invitation
    INSERT INTO club_invitations (club_id, invited_user_id, invited_by_user_id, message)
    VALUES (club_id_param, target_user_id, (SELECT id FROM users WHERE auth_user_id = users.auth_user_id), message_param)
    RETURNING id INTO invitation_id;
    
    -- Create notification for invited user
    PERFORM create_club_invitation_notification(
        target_user_id,
        club_id_param,
        club_name
    );
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Invitation sent successfully'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Fix promote_user_to_admin function - user_role field issue
DROP FUNCTION IF EXISTS promote_user_to_admin(UUID, UUID, TEXT);
CREATE OR REPLACE FUNCTION promote_user_to_admin(
    promoter_auth_user_id UUID,
    club_id_param UUID,
    target_user_id TEXT
)
RETURNS JSONB AS $$
DECLARE
    promoter_internal_id UUID;
    target_internal_id UUID;
    target_name TEXT;
    club_name TEXT;
    club_creator_id UUID;
BEGIN
    -- Get promoter's internal ID
    SELECT id INTO promoter_internal_id
    FROM users 
    WHERE auth_user_id = promoter_auth_user_id;
    
    IF promoter_internal_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Promoter not found'
        );
    END IF;
    
    -- Get target user's internal ID
    SELECT id, name INTO target_internal_id, target_name
    FROM users 
    WHERE id::text = target_user_id;
    
    IF target_internal_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Target user not found'
        );
    END IF;
    
    -- Get club details
    SELECT name, creator_id INTO club_name, club_creator_id
    FROM book_clubs
    WHERE id = club_id_param;
    
    IF club_name IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Club not found'
        );
    END IF;
    
    -- Check if promoter is admin (creator or has admin role)
    IF NOT EXISTS (
        SELECT 1 FROM book_club_members bcm
        WHERE bcm.club_id = club_id_param 
        AND bcm.user_id = promoter_internal_id
        AND (bcm.role = 'admin' OR bcm.user_id = club_creator_id)
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Only admins can promote users'
        );
    END IF;
    
    -- Check if target user is a member
    IF NOT EXISTS (
        SELECT 1 FROM book_club_members bcm
        WHERE bcm.club_id = club_id_param 
        AND bcm.user_id = target_internal_id
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'User is not a member of this club'
        );
    END IF;
    
    -- Update user role to admin
    UPDATE book_club_members 
    SET role = 'admin'
    WHERE club_id = club_id_param 
    AND user_id = target_internal_id;
    
    -- Create notification for promoted user
    PERFORM create_admin_promotion_notification(
        target_internal_id,
        club_id_param,
        club_name
    );
    
    RETURN jsonb_build_object(
        'success', true,
        'message', target_name || ' has been promoted to admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Fix join_book_club function - ensure it exists and works properly
DROP FUNCTION IF EXISTS join_book_club(UUID, UUID);
CREATE OR REPLACE FUNCTION join_book_club(
    auth_user_id UUID,
    club_id_param UUID
)
RETURNS JSONB AS $$
DECLARE
    user_internal_id UUID;
    club_name TEXT;
    club_creator_id UUID;
    existing_member_count INTEGER;
BEGIN
    -- Get user's internal ID
    SELECT id INTO user_internal_id
    FROM users 
    WHERE users.auth_user_id = join_book_club.auth_user_id;
    
    IF user_internal_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'User not found'
        );
    END IF;
    
    -- Get club details
    SELECT name, creator_id INTO club_name, club_creator_id
    FROM book_clubs
    WHERE id = club_id_param;
    
    IF club_name IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Club not found'
        );
    END IF;
    
    -- Check if user is already a member
    IF EXISTS (
        SELECT 1 FROM book_club_members bcm
        WHERE bcm.club_id = club_id_param 
        AND bcm.user_id = user_internal_id
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'You are already a member of this club'
        );
    END IF;
    
    -- Add user as member
    INSERT INTO book_club_members (club_id, user_id, role, joined_at)
    VALUES (club_id_param, user_internal_id, 'member', NOW());
    
    -- Get current member count
    SELECT COUNT(*) INTO existing_member_count
    FROM book_club_members
    WHERE club_id = club_id_param;
    
    -- Create notification for club admins about new member
    PERFORM create_member_joined_notification(
        club_id_param,
        user_internal_id,
        club_name
    );
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Successfully joined ' || club_name,
        'member_count', existing_member_count
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Create missing notification functions if they don't exist
CREATE OR REPLACE FUNCTION create_club_invitation_notification(
    invited_user_id UUID,
    club_id UUID,
    club_name TEXT
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO notifications (user_id, type, title, message, related_id, related_name, is_read, created_at)
    VALUES (
        invited_user_id,
        'club_invitation',
        'Club Invitation',
        'You have been invited to join "' || club_name || '"',
        club_id,
        club_name,
        false,
        NOW()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION create_admin_promotion_notification(
    promoted_user_id UUID,
    club_id UUID,
    club_name TEXT
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO notifications (user_id, type, title, message, related_id, related_name, is_read, created_at)
    VALUES (
        promoted_user_id,
        'admin_promotion',
        'Admin Promotion',
        'You have been promoted to admin in "' || club_name || '"',
        club_id,
        club_name,
        false,
        NOW()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION create_member_joined_notification(
    club_id UUID,
    new_member_id UUID,
    club_name TEXT
)
RETURNS VOID AS $$
DECLARE
    admin_user_id UUID;
    new_member_name TEXT;
BEGIN
    -- Get new member's name
    SELECT name INTO new_member_name
    FROM users
    WHERE id = new_member_id;
    
    -- Notify all admins of the club
    FOR admin_user_id IN 
        SELECT bcm.user_id
        FROM book_club_members bcm
        WHERE bcm.club_id = create_member_joined_notification.club_id
        AND bcm.role = 'admin'
    LOOP
        INSERT INTO notifications (user_id, type, title, message, related_id, related_name, is_read, created_at)
        VALUES (
            admin_user_id,
            'member_joined',
            'New Member',
            new_member_name || ' has joined "' || club_name || '"',
            club_id,
            club_name,
            false,
            NOW()
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Fix message notification functions to ensure they work properly
DROP FUNCTION IF EXISTS create_club_message_notification(UUID, UUID, TEXT);
CREATE OR REPLACE FUNCTION create_club_message_notification(
    club_id UUID,
    sender_id UUID,
    message_content TEXT
)
RETURNS VOID AS $$
DECLARE
    member_user_id UUID;
    sender_name TEXT;
    club_name TEXT;
BEGIN
    -- Get sender name and club name
    SELECT u.name, bc.name INTO sender_name, club_name
    FROM users u, book_clubs bc
    WHERE u.id = sender_id AND bc.id = club_id;
    
    -- Notify all members except the sender
    FOR member_user_id IN 
        SELECT bcm.user_id
        FROM book_club_members bcm
        WHERE bcm.club_id = create_club_message_notification.club_id
        AND bcm.user_id != sender_id
    LOOP
        INSERT INTO notifications (user_id, type, title, message, related_id, related_name, is_read, created_at)
        VALUES (
            member_user_id,
            'club_message',
            'New Message in ' || club_name,
            sender_name || ': ' || LEFT(message_content, 100),
            club_id,
            club_name,
            false,
            NOW()
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP FUNCTION IF EXISTS create_discussion_message_notification(UUID, UUID, TEXT);
CREATE OR REPLACE FUNCTION create_discussion_message_notification(
    discussion_id UUID,
    sender_id UUID,
    message_content TEXT
)
RETURNS VOID AS $$
DECLARE
    member_user_id UUID;
    sender_name TEXT;
    discussion_name TEXT;
BEGIN
    -- Get sender name and discussion name
    SELECT u.name, d.title INTO sender_name, discussion_name
    FROM users u, discussions d
    WHERE u.id = sender_id AND d.id = discussion_id;
    
    -- Notify all members except the sender
    FOR member_user_id IN 
        SELECT dm.user_id
        FROM discussion_members dm
        WHERE dm.discussion_id = create_discussion_message_notification.discussion_id
        AND dm.user_id != sender_id
    LOOP
        INSERT INTO notifications (user_id, type, title, message, related_id, related_name, is_read, created_at)
        VALUES (
            member_user_id,
            'discussion_message',
            'New Message in ' || discussion_name,
            sender_name || ': ' || LEFT(message_content, 100),
            discussion_id,
            discussion_name,
            false,
            NOW()
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP FUNCTION IF EXISTS create_friend_message_notification(UUID, UUID, TEXT);
CREATE OR REPLACE FUNCTION create_friend_message_notification(
    recipient_id UUID,
    sender_id UUID,
    message_content TEXT
)
RETURNS VOID AS $$
DECLARE
    sender_name TEXT;
BEGIN
    -- Get sender name
    SELECT name INTO sender_name
    FROM users
    WHERE id = sender_id;
    
    -- Create notification for recipient
    INSERT INTO notifications (user_id, type, title, message, related_id, related_name, is_read, created_at)
    VALUES (
        recipient_id,
        'friend_message',
        'New Message from ' || sender_name,
        LEFT(message_content, 100),
        sender_id,
        sender_name,
        false,
        NOW()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
