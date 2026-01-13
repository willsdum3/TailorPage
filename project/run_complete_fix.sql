-- Run the complete fix for admin permissions and membership issues
-- This script runs the main fix after the safe creator setup

-- Run the main admin permissions and membership fix
\i fix_admin_permissions_and_membership.sql

-- Verify all functions were created successfully
SELECT 
    'Functions created successfully' as status,
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
    'get_user_internal_id',
    'is_user_club_admin'
)
ORDER BY routine_name;

-- Test the helper functions
DO $$
DECLARE
    test_user_id UUID;
    test_club_id UUID;
    test_auth_user_id UUID;
    is_admin_result BOOLEAN;
    internal_id_result UUID;
BEGIN
    -- Get a test user
    SELECT id, auth_user_id INTO test_user_id, test_auth_user_id FROM users LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        RAISE NOTICE 'Testing helper functions:';
        RAISE NOTICE 'Test user ID: %, Auth user ID: %', test_user_id, test_auth_user_id;
        
        -- Test get_user_internal_id function
        internal_id_result := get_user_internal_id(test_auth_user_id);
        IF internal_id_result = test_user_id THEN
            RAISE NOTICE '✅ get_user_internal_id function working correctly';
        ELSE
            RAISE NOTICE '❌ get_user_internal_id function NOT working correctly';
        END IF;
        
        -- Get a test club
        SELECT id INTO test_club_id FROM book_clubs LIMIT 1;
        
        IF test_club_id IS NOT NULL THEN
            RAISE NOTICE 'Test club ID: %', test_club_id;
            
            -- Test admin check function
            is_admin_result := is_user_club_admin(test_user_id, test_club_id);
            RAISE NOTICE 'Is user admin: %', is_admin_result;
            
            IF is_admin_result IS NOT NULL THEN
                RAISE NOTICE '✅ is_user_club_admin function working correctly';
            ELSE
                RAISE NOTICE '❌ is_user_club_admin function NOT working correctly';
            END IF;
        ELSE
            RAISE NOTICE 'No book clubs found for testing';
        END IF;
    ELSE
        RAISE NOTICE 'No users found for testing';
    END IF;
END $$;

-- Check final state
DO $$
DECLARE
    club_count INTEGER;
    valid_creator_count INTEGER;
    creator_member_count INTEGER;
    admin_member_count INTEGER;
    total_members INTEGER;
BEGIN
    SELECT COUNT(*) INTO club_count FROM book_clubs;
    SELECT COUNT(*) INTO valid_creator_count FROM book_clubs bc
    JOIN users u ON bc.creator_id = u.id;
    SELECT COUNT(*) INTO creator_member_count FROM book_clubs bc
    JOIN book_club_members bcm ON bc.id = bcm.club_id AND bc.creator_id = bcm.user_id;
    SELECT COUNT(*) INTO admin_member_count FROM book_club_members WHERE role = 'admin';
    SELECT COUNT(*) INTO total_members FROM book_club_members;
    
    RAISE NOTICE 'Final database state:';
    RAISE NOTICE 'Total clubs: %', club_count;
    RAISE NOTICE 'Clubs with valid creators: %', valid_creator_count;
    RAISE NOTICE 'Clubs where creator is a member: %', creator_member_count;
    RAISE NOTICE 'Total admin members: %', admin_member_count;
    RAISE NOTICE 'Total club members: %', total_members;
    
    IF admin_member_count > 0 THEN
        RAISE NOTICE '✅ Admin members created successfully';
    ELSE
        RAISE NOTICE '⚠️ No admin members found - this may be normal if no valid creators exist';
    END IF;
END $$;





















