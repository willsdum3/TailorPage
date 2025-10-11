-- Fix all missing database functions with proper DROP statements
-- This script drops all existing functions first to avoid return type conflicts

-- Drop all existing functions that might conflict
DROP FUNCTION IF EXISTS join_book_club(UUID, UUID);
DROP FUNCTION IF EXISTS invite_user_to_club(UUID, UUID, TEXT, TEXT);
DROP FUNCTION IF EXISTS promote_user_to_admin(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS add_book_club_message(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS add_discussion_message(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS create_club_invitation_notification(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS create_admin_promotion_notification(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS create_member_joined_notification(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS create_club_message_notification(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS create_discussion_message_notification(UUID, UUID, TEXT);

-- 1. Create join_book_club function
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

-- 2. Create invite_user_to_club function
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
    
    -- Create invitation using correct column names
    INSERT INTO club_invitations (club_id, invitee_id, inviter_id, message, status)
    VALUES (club_id_param, target_user_id, (SELECT id FROM users WHERE auth_user_id = users.auth_user_id), message_param, 'pending')
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

-- 3. Create promote_user_to_admin function
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

-- 4. Create add_book_club_message function
CREATE OR REPLACE FUNCTION add_book_club_message(
    auth_user_id UUID,
    club_id_param UUID,
    message_content TEXT
)
RETURNS UUID AS $$
DECLARE
    user_internal_id UUID;
    message_id UUID;
BEGIN
    -- Get user's internal ID
    SELECT id INTO user_internal_id
    FROM users 
    WHERE users.auth_user_id = add_book_club_message.auth_user_id;
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if user is a member of the club
    IF NOT EXISTS (
        SELECT 1 FROM book_club_members bcm
        WHERE bcm.club_id = club_id_param 
        AND bcm.user_id = user_internal_id
    ) THEN
        RAISE EXCEPTION 'User is not a member of this club';
    END IF;
    
    -- Insert the message
    INSERT INTO book_club_messages (club_id, user_id, message, created_at)
    VALUES (club_id_param, user_internal_id, message_content, NOW())
    RETURNING id INTO message_id;
    
    -- Create notification for other members
    PERFORM create_club_message_notification(
        club_id_param,
        user_internal_id,
        message_content
    );
    
    RETURN message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Create add_discussion_message function
CREATE OR REPLACE FUNCTION add_discussion_message(
    auth_user_id UUID,
    discussion_id_param UUID,
    message_content TEXT
)
RETURNS UUID AS $$
DECLARE
    user_internal_id UUID;
    message_id UUID;
BEGIN
    -- Get user's internal ID
    SELECT id INTO user_internal_id
    FROM users 
    WHERE users.auth_user_id = add_discussion_message.auth_user_id;
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if user is a member of the discussion
    IF NOT EXISTS (
        SELECT 1 FROM discussion_members dm
        WHERE dm.discussion_id = discussion_id_param 
        AND dm.user_id = user_internal_id
    ) THEN
        RAISE EXCEPTION 'User is not a member of this discussion';
    END IF;
    
    -- Insert the message
    INSERT INTO discussion_messages (discussion_id, user_id, message, created_at)
    VALUES (discussion_id_param, user_internal_id, message_content, NOW())
    RETURNING id INTO message_id;
    
    -- Create notification for other members
    PERFORM create_discussion_message_notification(
        discussion_id_param,
        user_internal_id,
        message_content
    );
    
    RETURN message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Create missing notification functions
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

-- Verify all functions were created
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name IN (
    'join_book_club',
    'invite_user_to_club', 
    'promote_user_to_admin',
    'add_book_club_message',
    'add_discussion_message',
    'create_club_invitation_notification',
    'create_admin_promotion_notification',
    'create_member_joined_notification',
    'create_club_message_notification',
    'create_discussion_message_notification'
)
ORDER BY routine_name;








