-- Final comprehensive fix for all remaining issues
-- This script addresses the root cause of all problems

-- First, let's see what the actual issue is by checking the current state
SELECT 
    'Current State' as check_type,
    (SELECT COUNT(*) FROM users) as user_count,
    (SELECT COUNT(*) FROM book_clubs) as club_count,
    (SELECT COUNT(*) FROM book_club_members) as member_count,
    (SELECT COUNT(*) FROM discussions) as discussion_count,
    (SELECT COUNT(*) FROM discussion_members) as discussion_member_count;

-- Check if club creators are actually admin members
SELECT 
    'Creator Admin Status' as check_type,
    bc.id as club_id,
    bc.name as club_name,
    bc.creator_id,
    u.name as creator_name,
    bcm.role as creator_role,
    CASE 
        WHEN bcm.user_id IS NULL THEN 'NOT A MEMBER'
        WHEN bcm.role = 'admin' THEN 'ADMIN MEMBER'
        ELSE 'MEMBER (NOT ADMIN)'
    END as status
FROM book_clubs bc
LEFT JOIN users u ON bc.creator_id = u.id
LEFT JOIN book_club_members bcm ON bc.id = bcm.club_id AND bc.creator_id = bcm.user_id
ORDER BY bc.name;

-- The core issue: Let's manually add ALL club creators as admin members
INSERT INTO book_club_members (club_id, user_id, role, joined_at)
SELECT 
    bc.id as club_id,
    bc.creator_id as user_id,
    'admin' as role,
    bc.created_at as joined_at
FROM book_clubs bc
JOIN users u ON bc.creator_id = u.id
WHERE NOT EXISTS (
    SELECT 1 FROM book_club_members bcm
    WHERE bcm.club_id = bc.id 
    AND bcm.user_id = bc.creator_id
);

-- Update existing creator members to have admin role
UPDATE book_club_members 
SET role = 'admin'
WHERE user_id IN (
    SELECT bc.creator_id 
    FROM book_clubs bc 
    WHERE bc.creator_id = book_club_members.user_id
    AND bc.id = book_club_members.club_id
)
AND role != 'admin';

-- Now let's check if the helper functions exist and work
SELECT 
    'Helper Functions' as check_type,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name IN ('get_user_internal_id', 'is_user_club_admin')
ORDER BY routine_name;

-- If the helper functions don't exist, let's create them
CREATE OR REPLACE FUNCTION get_user_internal_id(auth_user_id UUID)
RETURNS UUID AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    SELECT u.id INTO user_internal_id
    FROM users u 
    WHERE u.auth_user_id = get_user_internal_id.auth_user_id;
    
    RETURN user_internal_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION is_user_club_admin(user_internal_id UUID, club_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    is_admin BOOLEAN := FALSE;
    club_creator_id UUID;
BEGIN
    -- Get club creator
    SELECT bc.creator_id INTO club_creator_id
    FROM book_clubs bc
    WHERE bc.id = is_user_club_admin.club_id;
    
    -- Check if user is creator or has admin role
    IF user_internal_id = club_creator_id THEN
        is_admin := TRUE;
    ELSE
        -- Check if user has admin role in book_club_members
        SELECT EXISTS (
            SELECT 1 FROM book_club_members bcm
            WHERE bcm.club_id = is_user_club_admin.club_id 
            AND bcm.user_id = user_internal_id
            AND bcm.role = 'admin'
        ) INTO is_admin;
    END IF;
    
    RETURN is_admin;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Now let's completely recreate the main functions with the correct logic
DROP FUNCTION IF EXISTS join_book_club(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS add_book_club_message(UUID, UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS promote_user_to_admin(UUID, UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS invite_user_to_club(UUID, UUID, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS add_discussion_message(UUID, UUID, TEXT) CASCADE;

-- 1. join_book_club function
CREATE OR REPLACE FUNCTION join_book_club(
    auth_user_id UUID,
    club_id UUID
)
RETURNS JSONB AS $$
DECLARE
    user_internal_id UUID;
    club_name TEXT;
    existing_member_count INTEGER;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'User not found'
        );
    END IF;
    
    -- Get club name
    SELECT bc.name INTO club_name
    FROM book_clubs bc
    WHERE bc.id = join_book_club.club_id;
    
    IF club_name IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Club not found'
        );
    END IF;
    
    -- Check if user is already a member
    IF EXISTS (
        SELECT 1 FROM book_club_members bcm
        WHERE bcm.club_id = join_book_club.club_id 
        AND bcm.user_id = user_internal_id
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'You are already a member of this club'
        );
    END IF;
    
    -- Add user as member
    INSERT INTO book_club_members (club_id, user_id, role, joined_at)
    VALUES (join_book_club.club_id, user_internal_id, 'member', NOW());
    
    -- Get current member count
    SELECT COUNT(*) INTO existing_member_count
    FROM book_club_members bcm
    WHERE bcm.club_id = join_book_club.club_id;
    
    -- Create notification for club admins about new member
    PERFORM create_member_joined_notification(
        join_book_club.club_id,
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

-- 2. add_book_club_message function
CREATE OR REPLACE FUNCTION add_book_club_message(
    auth_user_id UUID,
    club_id_param UUID,
    content_param TEXT
)
RETURNS UUID AS $$
DECLARE
    user_internal_id UUID;
    message_id UUID;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if user is a member of the club
    IF NOT EXISTS (
        SELECT 1 FROM book_club_members bcm
        WHERE bcm.club_id = add_book_club_message.club_id_param 
        AND bcm.user_id = user_internal_id
    ) THEN
        RAISE EXCEPTION 'User is not a member of this club';
    END IF;
    
    -- Insert the message
    INSERT INTO book_club_messages (club_id, user_id, message, created_at)
    VALUES (add_book_club_message.club_id_param, user_internal_id, add_book_club_message.content_param, NOW())
    RETURNING id INTO message_id;
    
    -- Create notification for other members
    PERFORM create_club_message_notification(
        add_book_club_message.club_id_param,
        user_internal_id,
        add_book_club_message.content_param
    );
    
    RETURN message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. promote_user_to_admin function
CREATE OR REPLACE FUNCTION promote_user_to_admin(
    auth_user_id UUID,
    club_id_param UUID,
    user_to_promote_id TEXT
)
RETURNS JSONB AS $$
DECLARE
    promoter_internal_id UUID;
    target_internal_id UUID;
    target_name TEXT;
    club_name TEXT;
    is_promoter_admin BOOLEAN;
BEGIN
    -- Get promoter's internal ID
    promoter_internal_id := get_user_internal_id(auth_user_id);
    
    IF promoter_internal_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Promoter not found'
        );
    END IF;
    
    -- Get target user's internal ID
    SELECT u.id, u.name INTO target_internal_id, target_name
    FROM users u 
    WHERE u.id::text = promote_user_to_admin.user_to_promote_id;
    
    IF target_internal_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Target user not found'
        );
    END IF;
    
    -- Get club name
    SELECT bc.name INTO club_name
    FROM book_clubs bc
    WHERE bc.id = promote_user_to_admin.club_id_param;
    
    IF club_name IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Club not found'
        );
    END IF;
    
    -- Check if promoter is admin
    is_promoter_admin := is_user_club_admin(promoter_internal_id, promote_user_to_admin.club_id_param);
    
    IF NOT is_promoter_admin THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Only admins can promote users'
        );
    END IF;
    
    -- Check if target user is a member
    IF NOT EXISTS (
        SELECT 1 FROM book_club_members bcm
        WHERE bcm.club_id = promote_user_to_admin.club_id_param 
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
    WHERE club_id = promote_user_to_admin.club_id_param 
    AND user_id = target_internal_id;
    
    -- Create notification for promoted user
    PERFORM create_admin_promotion_notification(
        target_internal_id,
        promote_user_to_admin.club_id_param,
        club_name
    );
    
    RETURN jsonb_build_object(
        'success', true,
        'message', target_name || ' has been promoted to admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. invite_user_to_club function
CREATE OR REPLACE FUNCTION invite_user_to_club(
    auth_user_id UUID,
    club_id_param UUID,
    username_param TEXT,
    message_param TEXT
)
RETURNS JSONB AS $$
DECLARE
    inviter_internal_id UUID;
    target_user_id UUID;
    target_name TEXT;
    club_name TEXT;
    invitation_id UUID;
    is_inviter_admin BOOLEAN;
BEGIN
    -- Get inviter's internal ID
    inviter_internal_id := get_user_internal_id(auth_user_id);
    
    IF inviter_internal_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Inviter not found'
        );
    END IF;
    
    -- Get target user by username
    SELECT u.id, u.name INTO target_user_id, target_name
    FROM users u 
    WHERE u.username = invite_user_to_club.username_param;
    
    IF target_user_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'User not found'
        );
    END IF;
    
    -- Check if user is already a member
    IF EXISTS (
        SELECT 1 FROM book_club_members bcm 
        WHERE bcm.club_id = invite_user_to_club.club_id_param 
        AND bcm.user_id = target_user_id
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'User is already a member of this club'
        );
    END IF;
    
    -- Get club name
    SELECT bc.name INTO club_name
    FROM book_clubs bc
    WHERE bc.id = invite_user_to_club.club_id_param;
    
    IF club_name IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Club not found'
        );
    END IF;
    
    -- Check if inviter is admin
    is_inviter_admin := is_user_club_admin(inviter_internal_id, invite_user_to_club.club_id_param);
    
    IF NOT is_inviter_admin THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Only admins can invite users to clubs'
        );
    END IF;
    
    -- Create invitation
    INSERT INTO club_invitations (club_id, invitee_id, inviter_id, message, status)
    VALUES (invite_user_to_club.club_id_param, target_user_id, inviter_internal_id, invite_user_to_club.message_param, 'pending')
    RETURNING id INTO invitation_id;
    
    -- Create notification for invited user
    PERFORM create_club_invitation_notification(
        target_user_id,
        invite_user_to_club.club_id_param,
        club_name
    );
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Invitation sent successfully'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. add_discussion_message function
CREATE OR REPLACE FUNCTION add_discussion_message(
    auth_user_id UUID,
    discussion_id UUID,
    message_content TEXT
)
RETURNS UUID AS $$
DECLARE
    user_internal_id UUID;
    message_id UUID;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if user is a member of the discussion
    IF NOT EXISTS (
        SELECT 1 FROM discussion_members dm
        WHERE dm.discussion_id = add_discussion_message.discussion_id 
        AND dm.user_id = user_internal_id
    ) THEN
        RAISE EXCEPTION 'User is not a member of this discussion';
    END IF;
    
    -- Insert the message
    INSERT INTO discussion_messages (discussion_id, user_id, message, created_at)
    VALUES (add_discussion_message.discussion_id, user_internal_id, add_discussion_message.message_content, NOW())
    RETURNING id INTO message_id;
    
    -- Create notification for other members
    PERFORM create_discussion_message_notification(
        add_discussion_message.discussion_id,
        user_internal_id,
        add_discussion_message.message_content
    );
    
    RETURN message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Final verification
SELECT 
    'Final Function Verification' as check_type,
    routine_name,
    COUNT(*) as function_count
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name IN (
    'join_book_club',
    'invite_user_to_club', 
    'promote_user_to_admin',
    'add_book_club_message',
    'add_discussion_message',
    'get_user_internal_id',
    'is_user_club_admin'
)
GROUP BY routine_name
ORDER BY routine_name;

-- Final membership check
SELECT 
    'Final Membership Check' as check_type,
    bc.id as club_id,
    bc.name as club_name,
    bc.creator_id,
    COUNT(bcm.user_id) as member_count,
    string_agg(u.name || ' (' || bcm.role || ')', ', ') as member_details
FROM book_clubs bc
LEFT JOIN book_club_members bcm ON bc.id = bcm.club_id
LEFT JOIN users u ON bcm.user_id = u.id
GROUP BY bc.id, bc.name, bc.creator_id
ORDER BY bc.name;




















