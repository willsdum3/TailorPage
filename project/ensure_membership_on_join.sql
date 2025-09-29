-- Ensure users are properly added as members when they join clubs/discussions
-- This script creates functions to handle automatic membership creation

-- Create a function to ensure user is a member of a club
CREATE OR REPLACE FUNCTION ensure_club_membership(
    user_internal_id UUID,
    club_id UUID,
    role TEXT DEFAULT 'member'
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if user is already a member
    IF NOT EXISTS (
        SELECT 1 FROM book_club_members bcm
        WHERE bcm.club_id = ensure_club_membership.club_id 
        AND bcm.user_id = user_internal_id
    ) THEN
        -- Add user as member
        INSERT INTO book_club_members (club_id, user_id, role, joined_at)
        VALUES (club_id, user_internal_id, role, NOW());
        
        RETURN TRUE;
    END IF;
    
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to ensure user is a member of a discussion
CREATE OR REPLACE FUNCTION ensure_discussion_membership(
    user_internal_id UUID,
    discussion_id UUID,
    role TEXT DEFAULT 'member'
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if user is already a member
    IF NOT EXISTS (
        SELECT 1 FROM discussion_members dm
        WHERE dm.discussion_id = ensure_discussion_membership.discussion_id 
        AND dm.user_id = user_internal_id
    ) THEN
        -- Add user as member
        INSERT INTO discussion_members (discussion_id, user_id, role, joined_at)
        VALUES (discussion_id, user_internal_id, role, NOW());
        
        RETURN TRUE;
    END IF;
    
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to get user's internal ID from auth_user_id
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

-- Test the functions
DO $$
DECLARE
    test_user_id UUID;
    test_club_id UUID;
    test_discussion_id UUID;
BEGIN
    -- Get a test user ID
    SELECT id INTO test_user_id FROM users LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        RAISE NOTICE 'Test user ID: %', test_user_id;
        
        -- Get a test club ID
        SELECT id INTO test_club_id FROM book_clubs LIMIT 1;
        
        IF test_club_id IS NOT NULL THEN
            RAISE NOTICE 'Test club ID: %', test_club_id;
            
            -- Test club membership function
            IF ensure_club_membership(test_user_id, test_club_id, 'member') THEN
                RAISE NOTICE 'User added to club successfully';
            ELSE
                RAISE NOTICE 'User was already a member of the club';
            END IF;
        END IF;
        
        -- Get a test discussion ID
        SELECT id INTO test_discussion_id FROM discussions LIMIT 1;
        
        IF test_discussion_id IS NOT NULL THEN
            RAISE NOTICE 'Test discussion ID: %', test_discussion_id;
            
            -- Test discussion membership function
            IF ensure_discussion_membership(test_user_id, test_discussion_id, 'member') THEN
                RAISE NOTICE 'User added to discussion successfully';
            ELSE
                RAISE NOTICE 'User was already a member of the discussion';
            END IF;
        END IF;
    ELSE
        RAISE NOTICE 'No users found in database';
    END IF;
END $$;
