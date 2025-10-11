-- Fix the core membership creation issue (corrected version)
-- This script addresses why users aren't being added as members when they join

-- First, let's check the current state of memberships
DO $$
DECLARE
    user_count INTEGER;
    club_count INTEGER;
    member_count INTEGER;
    discussion_count INTEGER;
    discussion_member_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO user_count FROM users;
    SELECT COUNT(*) INTO club_count FROM book_clubs;
    SELECT COUNT(*) INTO member_count FROM book_club_members;
    SELECT COUNT(*) INTO discussion_count FROM discussions;
    SELECT COUNT(*) INTO discussion_member_count FROM discussion_members;
    
    RAISE NOTICE 'Current membership state:';
    RAISE NOTICE 'Users: %', user_count;
    RAISE NOTICE 'Book clubs: %', club_count;
    RAISE NOTICE 'Book club members: %', member_count;
    RAISE NOTICE 'Discussions: %', discussion_count;
    RAISE NOTICE 'Discussion members: %', discussion_member_count;
END $$;

-- Check if users are actually being added as members when they join
SELECT 
    'Club Membership Check' as check_type,
    bc.id as club_id,
    bc.name as club_name,
    bc.creator_id,
    COUNT(bcm.user_id) as member_count,
    string_agg(u.name, ', ') as member_names
FROM book_clubs bc
LEFT JOIN book_club_members bcm ON bc.id = bcm.club_id
LEFT JOIN users u ON bcm.user_id = u.id
GROUP BY bc.id, bc.name, bc.creator_id
ORDER BY bc.name;

-- Check if club creators are admin members
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

-- Let's manually add club creators as admin members if they're missing
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

-- Check the updated state
DO $$
DECLARE
    creator_member_count INTEGER;
    admin_member_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO creator_member_count FROM book_clubs bc
    JOIN book_club_members bcm ON bc.id = bcm.club_id AND bc.creator_id = bcm.user_id;
    SELECT COUNT(*) INTO admin_member_count FROM book_club_members WHERE role = 'admin';
    
    RAISE NOTICE 'Updated membership state:';
    RAISE NOTICE 'Clubs where creator is a member: %', creator_member_count;
    RAISE NOTICE 'Total admin members: %', admin_member_count;
END $$;

-- Test the helper functions to make sure they work
DO $$
DECLARE
    test_user_id UUID;
    test_club_id UUID;
    test_auth_user_id UUID;
    test_username TEXT;
    is_admin_result BOOLEAN;
    internal_id_result UUID;
BEGIN
    -- Get a test user
    SELECT id, auth_user_id, username INTO test_user_id, test_auth_user_id, test_username FROM users LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        RAISE NOTICE 'Testing helper functions:';
        RAISE NOTICE 'Test user: % (ID: %, Auth ID: %)', test_username, test_user_id, test_auth_user_id;
        
        -- Test get_user_internal_id function
        BEGIN
            internal_id_result := get_user_internal_id(test_auth_user_id);
            IF internal_id_result = test_user_id THEN
                RAISE NOTICE '✅ get_user_internal_id function working correctly';
            ELSE
                RAISE NOTICE '❌ get_user_internal_id function NOT working correctly. Expected: %, Got: %', test_user_id, internal_id_result;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ get_user_internal_id function ERROR: %', SQLERRM;
        END;
        
        -- Get a test club
        SELECT id INTO test_club_id FROM book_clubs LIMIT 1;
        
        IF test_club_id IS NOT NULL THEN
            RAISE NOTICE 'Test club ID: %', test_club_id;
            
            -- Test admin check function
            BEGIN
                is_admin_result := is_user_club_admin(test_user_id, test_club_id);
                RAISE NOTICE 'Is user admin: %', is_admin_result;
                
                IF is_admin_result IS NOT NULL THEN
                    RAISE NOTICE '✅ is_user_club_admin function working correctly';
                ELSE
                    RAISE NOTICE '❌ is_user_club_admin function NOT working correctly';
                END IF;
            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE '❌ is_user_club_admin function ERROR: %', SQLERRM;
            END IF;
        ELSE
            RAISE NOTICE 'No book clubs found for testing';
        END IF;
    ELSE
        RAISE NOTICE 'No users found for testing';
    END IF;
END $$;

-- Test the actual functions with real data
DO $$
DECLARE
    test_user_id UUID;
    test_club_id UUID;
    test_auth_user_id UUID;
    test_username TEXT;
    result JSONB;
    message_id UUID;
BEGIN
    -- Get a test user
    SELECT id, auth_user_id, username INTO test_user_id, test_auth_user_id, test_username FROM users LIMIT 1;
    
    -- Get a test club
    SELECT id INTO test_club_id FROM book_clubs LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_club_id IS NOT NULL THEN
        RAISE NOTICE 'Testing actual functions:';
        RAISE NOTICE 'Test user: % (ID: %, Auth ID: %)', test_username, test_user_id, test_auth_user_id;
        RAISE NOTICE 'Test club ID: %', test_club_id;
        
        -- Test join_book_club function
        BEGIN
            result := join_book_club(test_auth_user_id, test_club_id);
            RAISE NOTICE 'join_book_club result: %', result;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ join_book_club ERROR: %', SQLERRM;
        END;
        
        -- Test add_book_club_message function
        BEGIN
            message_id := add_book_club_message(test_auth_user_id, test_club_id, 'Test message');
            RAISE NOTICE 'add_book_club_message result: %', message_id;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ add_book_club_message ERROR: %', SQLERRM;
        END;
        
        -- Test promote_user_to_admin function
        BEGIN
            result := promote_user_to_admin(test_auth_user_id, test_club_id, test_user_id::text);
            RAISE NOTICE 'promote_user_to_admin result: %', result;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ promote_user_to_admin ERROR: %', SQLERRM;
        END;
        
        -- Test invite_user_to_club function
        BEGIN
            result := invite_user_to_club(test_auth_user_id, test_club_id, test_username, 'Test invitation');
            RAISE NOTICE 'invite_user_to_club result: %', result;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ invite_user_to_club ERROR: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE 'No test data available';
    END IF;
END $$;

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








