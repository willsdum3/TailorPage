-- Comprehensive debug script to identify remaining issues
-- This script will help us understand why the issues are still persisting

-- 1. Check current function status
SELECT 
    'Current Functions' as check_type,
    routine_name,
    routine_type,
    specific_name,
    data_type
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
ORDER BY routine_name, specific_name;

-- 2. Check table structure and data
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
    
    RAISE NOTICE 'Database state:';
    RAISE NOTICE 'Users: %', user_count;
    RAISE NOTICE 'Book clubs: %', club_count;
    RAISE NOTICE 'Book club members: %', member_count;
    RAISE NOTICE 'Discussions: %', discussion_count;
    RAISE NOTICE 'Discussion members: %', discussion_member_count;
END $$;

-- 3. Check for valid club creators
SELECT 
    'Club Creators Status' as check_type,
    bc.id as club_id,
    bc.name as club_name,
    bc.creator_id,
    CASE 
        WHEN u.id IS NULL THEN 'INVALID CREATOR'
        ELSE 'VALID CREATOR'
    END as creator_status,
    u.name as creator_name
FROM book_clubs bc
LEFT JOIN users u ON bc.creator_id = u.id
ORDER BY creator_status, bc.name;

-- 4. Check admin members
SELECT 
    'Admin Members' as check_type,
    bcm.club_id,
    bc.name as club_name,
    bcm.user_id,
    u.name as user_name,
    bcm.role,
    bcm.joined_at
FROM book_club_members bcm
JOIN book_clubs bc ON bcm.club_id = bc.id
JOIN users u ON bcm.user_id = u.id
WHERE bcm.role = 'admin'
ORDER BY bc.name, u.name;

-- 5. Test the helper functions with actual data
DO $$
DECLARE
    test_user_id UUID;
    test_club_id UUID;
    test_auth_user_id UUID;
    is_admin_result BOOLEAN;
    internal_id_result UUID;
    test_username TEXT;
BEGIN
    -- Get a test user
    SELECT id, auth_user_id, username INTO test_user_id, test_auth_user_id, test_username FROM users LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        RAISE NOTICE 'Testing with actual user: % (ID: %, Auth ID: %)', test_username, test_user_id, test_auth_user_id;
        
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
            RAISE NOTICE 'Testing with club ID: %', test_club_id;
            
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
            END;
        ELSE
            RAISE NOTICE 'No book clubs found for testing';
        END IF;
    ELSE
        RAISE NOTICE 'No users found for testing';
    END IF;
END $$;

-- 6. Test a simple join_book_club call
DO $$
DECLARE
    test_user_id UUID;
    test_club_id UUID;
    test_auth_user_id UUID;
    result JSONB;
BEGIN
    -- Get a test user
    SELECT id, auth_user_id INTO test_user_id, test_auth_user_id FROM users LIMIT 1;
    
    -- Get a test club
    SELECT id INTO test_club_id FROM book_clubs LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_club_id IS NOT NULL THEN
        RAISE NOTICE 'Testing join_book_club function...';
        
        BEGIN
            result := join_book_club(test_auth_user_id, test_club_id);
            RAISE NOTICE 'join_book_club result: %', result;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ join_book_club function ERROR: %', SQLERRM;
        END;
    END IF;
END $$;

-- 7. Check if notification functions exist
SELECT 
    'Notification Functions' as check_type,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name LIKE '%notification%'
ORDER BY routine_name;

-- 8. Check if club_invitations table exists and has data
SELECT 
    'Club Invitations' as check_type,
    COUNT(*) as invitation_count
FROM club_invitations;

-- 9. Check RLS policies
SELECT 
    'RLS Policies' as check_type,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename IN ('book_clubs', 'book_club_members', 'book_club_messages', 'discussions', 'discussion_members', 'discussion_messages', 'club_invitations')
ORDER BY tablename, policyname;




















