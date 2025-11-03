-- Verify Data is Working
-- This script tests if the data is properly set up and functions are working

-- ===========================================
-- STEP 1: CHECK DATA COUNTS
-- ===========================================

SELECT '=== DATA COUNTS ===' as header;

SELECT 
    'Users' as item,
    COUNT(*) as total_records
FROM users
UNION ALL
SELECT 
    'Book Clubs' as item,
    COUNT(*) as total_records
FROM book_clubs
UNION ALL
SELECT 
    'Book Club Members' as item,
    COUNT(*) as total_records
FROM book_club_members
UNION ALL
SELECT 
    'Discussions' as item,
    COUNT(*) as total_records
FROM discussions
UNION ALL
SELECT 
    'Discussion Members' as item,
    COUNT(*) as total_records
FROM discussion_members
UNION ALL
SELECT 
    'Book Club Messages' as item,
    COUNT(*) as total_records
FROM book_club_messages
UNION ALL
SELECT 
    'Discussion Messages' as item,
    COUNT(*) as total_records
FROM discussion_messages;

-- ===========================================
-- STEP 2: TEST FUNCTIONS WITH ALL USERS
-- ===========================================

SELECT '=== TESTING FUNCTIONS ===' as header;

DO $$
DECLARE
    test_auth_id UUID;
    club_count INTEGER;
    discussion_count INTEGER;
    user_record RECORD;
BEGIN
    -- Test with each user
    FOR user_record IN SELECT auth_user_id, name FROM users ORDER BY created_at LOOP
        test_auth_id := user_record.auth_user_id;
        
        RAISE NOTICE 'Testing with user: % (%)', user_record.name, test_auth_id;
        
        -- Test get_book_clubs
        SELECT COUNT(*) INTO club_count FROM get_book_clubs(test_auth_id);
        RAISE NOTICE '  get_book_clubs returned % records', club_count;
        
        -- Test get_discussions
        SELECT COUNT(*) INTO discussion_count FROM get_discussions(test_auth_id);
        RAISE NOTICE '  get_discussions returned % records', discussion_count;
        
        -- Show first club if any
        IF club_count > 0 THEN
            DECLARE
                club_record RECORD;
            BEGIN
                FOR club_record IN SELECT name, creator_name FROM get_book_clubs(test_auth_id) LIMIT 1 LOOP
                    RAISE NOTICE '  First club: % (by %)', club_record.name, club_record.creator_name;
                END LOOP;
            END;
        END IF;
        
        -- Show first discussion if any
        IF discussion_count > 0 THEN
            DECLARE
                discussion_record RECORD;
            BEGIN
                FOR discussion_record IN SELECT title, creator_name FROM get_discussions(test_auth_id) LIMIT 1 LOOP
                    RAISE NOTICE '  First discussion: % (by %)', discussion_record.title, discussion_record.creator_name;
                END LOOP;
            END;
        END IF;
        
        RAISE NOTICE '---';
    END LOOP;
END $$;

-- ===========================================
-- STEP 3: SHOW SAMPLE DATA
-- ===========================================

SELECT '=== SAMPLE BOOK CLUBS ===' as header;
SELECT 
    bc.name,
    bc.description,
    u.name as creator_name,
    COUNT(bcm.user_id) as member_count
FROM book_clubs bc
LEFT JOIN users u ON bc.creator_id = u.id
LEFT JOIN book_club_members bcm ON bc.id = bcm.club_id
GROUP BY bc.id, bc.name, bc.description, u.name
ORDER BY bc.created_at DESC;

SELECT '=== SAMPLE DISCUSSIONS ===' as header;
SELECT 
    d.title,
    d.content,
    u.name as creator_name,
    COUNT(dm.user_id) as participant_count
FROM discussions d
LEFT JOIN users u ON d.created_by = u.id
LEFT JOIN discussion_members dm ON d.id = dm.discussion_id
GROUP BY d.id, d.title, d.content, u.name
ORDER BY d.created_at DESC;

-- ===========================================
-- STEP 4: TEST SPECIFIC USER
-- ===========================================

SELECT '=== TESTING SPECIFIC USER ===' as header;

DO $$
DECLARE
    test_auth_id UUID := '00000000-0000-0000-0000-000000000001';
    club_count INTEGER;
    discussion_count INTEGER;
    club_record RECORD;
    discussion_record RECORD;
BEGIN
    RAISE NOTICE 'Testing with user: %', test_auth_id;
    
    -- Test get_book_clubs
    SELECT COUNT(*) INTO club_count FROM get_book_clubs(test_auth_id);
    RAISE NOTICE 'get_book_clubs returned % records', club_count;
    
    -- Show all clubs for this user
    DECLARE
        club_record RECORD;
    BEGIN
        FOR club_record IN SELECT name, creator_name, is_member, is_admin FROM get_book_clubs(test_auth_id) LOOP
            RAISE NOTICE 'Club: % (by %, member: %, admin: %)', 
                club_record.name, club_record.creator_name, club_record.is_member, club_record.is_admin;
        END LOOP;
    END;
    
    -- Test get_discussions
    SELECT COUNT(*) INTO discussion_count FROM get_discussions(test_auth_id);
    RAISE NOTICE 'get_discussions returned % records', discussion_count;
    
    -- Show all discussions for this user
    DECLARE
        discussion_record RECORD;
    BEGIN
        FOR discussion_record IN SELECT title, creator_name, is_participant FROM get_discussions(test_auth_id) LOOP
            RAISE NOTICE 'Discussion: % (by %, participant: %)', 
                discussion_record.title, discussion_record.creator_name, discussion_record.is_participant;
        END LOOP;
    END;
END $$;

SELECT '=== VERIFICATION COMPLETE ===' as header;
