-- Debug Data Flow Issue
-- This script checks if data is being returned by the functions and identifies display issues

-- ===========================================
-- STEP 1: CHECK IF DATA EXISTS IN TABLES
-- ===========================================

SELECT '=== DATA EXISTENCE CHECK ===' as header;

SELECT 
    'book_clubs' as table_name,
    COUNT(*) as total_count
FROM book_clubs
UNION ALL
SELECT 
    'book_club_members' as table_name,
    COUNT(*) as total_count
FROM book_club_members
UNION ALL
SELECT 
    'discussions' as table_name,
    COUNT(*) as total_count
FROM discussions
UNION ALL
SELECT 
    'discussion_members' as table_name,
    COUNT(*) as total_count
FROM discussion_members
UNION ALL
SELECT 
    'users' as table_name,
    COUNT(*) as total_count
FROM users;

-- ===========================================
-- STEP 2: SHOW ACTUAL DATA CONTENT
-- ===========================================

SELECT '=== BOOK CLUBS DATA ===' as header;
SELECT 
    id,
    name,
    description,
    creator_id,
    created_at,
    is_public
FROM book_clubs
ORDER BY created_at DESC
LIMIT 5;

SELECT '=== DISCUSSIONS DATA ===' as header;
SELECT 
    id,
    title,
    content,
    created_by,
    created_at
FROM discussions
ORDER BY created_at DESC
LIMIT 5;

SELECT '=== USERS DATA ===' as header;
SELECT 
    id,
    auth_user_id,
    name,
    username,
    email
FROM users
ORDER BY created_at DESC
LIMIT 5;

-- ===========================================
-- STEP 3: TEST FUNCTION OUTPUT DIRECTLY
-- ===========================================

SELECT '=== TESTING FUNCTIONS WITH SAMPLE DATA ===' as header;

DO $$
DECLARE
    test_auth_id UUID;
    test_internal_id UUID;
    club_count INTEGER := 0;
    discussion_count INTEGER := 0;
    club_record RECORD;
    discussion_record RECORD;
BEGIN
    -- Get a test user
    SELECT auth_user_id INTO test_auth_id FROM users LIMIT 1;
    
    IF test_auth_id IS NOT NULL THEN
        RAISE NOTICE 'Testing with auth_user_id: %', test_auth_id;
        
        -- Test get_user_internal_id
        SELECT get_user_internal_id(test_auth_id) INTO test_internal_id;
        RAISE NOTICE 'get_user_internal_id returned: %', test_internal_id;
        
        -- Test get_book_clubs and show actual data
        SELECT COUNT(*) INTO club_count FROM get_book_clubs(test_auth_id);
        RAISE NOTICE 'get_book_clubs returned % records', club_count;
        
        -- Show first club record
        FOR club_record IN SELECT * FROM get_book_clubs(test_auth_id) LIMIT 1 LOOP
            RAISE NOTICE 'First club: id=%, name=%, creator=%, is_member=%, is_admin=%', 
                club_record.id, club_record.name, club_record.creator_name, club_record.is_member, club_record.is_admin;
        END LOOP;
        
        -- Test get_discussions and show actual data
        SELECT COUNT(*) INTO discussion_count FROM get_discussions(test_auth_id);
        RAISE NOTICE 'get_discussions returned % records', discussion_count;
        
        -- Show first discussion record
        FOR discussion_record IN SELECT * FROM get_discussions(test_auth_id) LIMIT 1 LOOP
            RAISE NOTICE 'First discussion: id=%, title=%, creator=%, is_participant=%', 
                discussion_record.id, discussion_record.title, discussion_record.creator_name, discussion_record.is_participant;
        END LOOP;
        
    ELSE
        RAISE NOTICE 'No users found for testing';
    END IF;
END $$;

-- ===========================================
-- STEP 4: CHECK IF USER IS MEMBER OF CLUBS/DISCUSSIONS
-- ===========================================

SELECT '=== CHECKING USER MEMBERSHIPS ===' as header;

DO $$
DECLARE
    test_auth_id UUID;
    test_internal_id UUID;
    membership_count INTEGER;
    discussion_membership_count INTEGER;
BEGIN
    -- Get a test user
    SELECT auth_user_id INTO test_auth_id FROM users LIMIT 1;
    
    IF test_auth_id IS NOT NULL THEN
        SELECT get_user_internal_id(test_auth_id) INTO test_internal_id;
        
        -- Check club memberships
        SELECT COUNT(*) INTO membership_count 
        FROM book_club_members 
        WHERE user_id = test_internal_id;
        
        RAISE NOTICE 'User is member of % clubs', membership_count;
        
        -- Check discussion memberships
        SELECT COUNT(*) INTO discussion_membership_count 
        FROM discussion_members 
        WHERE user_id = test_internal_id;
        
        RAISE NOTICE 'User is member of % discussions', discussion_membership_count;
        
        -- If user is not a member of anything, add them to existing clubs/discussions
        IF membership_count = 0 AND discussion_membership_count = 0 THEN
            RAISE NOTICE 'User is not a member of any clubs or discussions - adding to existing ones';
            
            -- Add user to first club
            INSERT INTO book_club_members (club_id, user_id, role, joined_at)
            SELECT id, test_internal_id, 'member', NOW()
            FROM book_clubs
            WHERE id NOT IN (SELECT club_id FROM book_club_members WHERE user_id = test_internal_id)
            LIMIT 1;
            
            -- Add user to first discussion
            INSERT INTO discussion_members (discussion_id, user_id, role, joined_at)
            SELECT id, test_internal_id, 'member', NOW()
            FROM discussions
            WHERE id NOT IN (SELECT discussion_id FROM discussion_members WHERE user_id = test_internal_id)
            LIMIT 1;
            
            RAISE NOTICE 'Added user to existing club and discussion';
        END IF;
    END IF;
END $$;

-- ===========================================
-- STEP 5: RE-TEST FUNCTIONS AFTER ADDING MEMBERSHIPS
-- ===========================================

SELECT '=== RE-TESTING AFTER ADDING MEMBERSHIPS ===' as header;

DO $$
DECLARE
    test_auth_id UUID;
    club_count INTEGER := 0;
    discussion_count INTEGER := 0;
BEGIN
    -- Get a test user
    SELECT auth_user_id INTO test_auth_id FROM users LIMIT 1;
    
    IF test_auth_id IS NOT NULL THEN
        -- Test get_book_clubs again
        SELECT COUNT(*) INTO club_count FROM get_book_clubs(test_auth_id);
        RAISE NOTICE 'After adding memberships - get_book_clubs returned % records', club_count;
        
        -- Test get_discussions again
        SELECT COUNT(*) INTO discussion_count FROM get_discussions(test_auth_id);
        RAISE NOTICE 'After adding memberships - get_discussions returned % records', discussion_count;
    END IF;
END $$;

-- ===========================================
-- STEP 6: CREATE SAMPLE DATA IF NONE EXISTS
-- ===========================================

SELECT '=== CREATING SAMPLE DATA IF NEEDED ===' as header;

DO $$
DECLARE
    user_count INTEGER;
    club_count INTEGER;
    discussion_count INTEGER;
    test_user_id UUID;
    test_club_id UUID;
    test_discussion_id UUID;
BEGIN
    -- Check if we have users
    SELECT COUNT(*) INTO user_count FROM users;
    
    IF user_count = 0 THEN
        RAISE NOTICE 'No users found - creating sample user';
        
        INSERT INTO users (auth_user_id, name, username, email, created_at)
        VALUES (
            gen_random_uuid(),
            'Sample User',
            'sampleuser',
            'sample@example.com',
            NOW()
        )
        RETURNING id INTO test_user_id;
        
        RAISE NOTICE 'Created sample user: %', test_user_id;
    ELSE
        SELECT id INTO test_user_id FROM users LIMIT 1;
    END IF;
    
    -- Check if we have clubs
    SELECT COUNT(*) INTO club_count FROM book_clubs;
    
    IF club_count = 0 THEN
        RAISE NOTICE 'No clubs found - creating sample clubs';
        
        INSERT INTO book_clubs (name, description, creator_id, created_at, is_public)
        VALUES 
            ('Fantasy Book Club', 'A club for fantasy literature enthusiasts', test_user_id, NOW(), true),
            ('Mystery Readers', 'Discuss mystery and thriller novels', test_user_id, NOW(), true)
        RETURNING id INTO test_club_id;
        
        -- Add creator as admin member
        INSERT INTO book_club_members (club_id, user_id, role, joined_at)
        SELECT id, test_user_id, 'admin', NOW()
        FROM book_clubs
        WHERE creator_id = test_user_id;
        
        RAISE NOTICE 'Created sample clubs and added creator as admin';
    END IF;
    
    -- Check if we have discussions
    SELECT COUNT(*) INTO discussion_count FROM discussions;
    
    IF discussion_count = 0 THEN
        RAISE NOTICE 'No discussions found - creating sample discussions';
        
        INSERT INTO discussions (title, content, book_title, book_author, created_by, created_at)
        VALUES 
            ('Best Fantasy Novels', 'What are your favorite fantasy novels?', 'Various', 'Various Authors', test_user_id, NOW()),
            ('Mystery Recommendations', 'Share your favorite mystery books', 'Various', 'Various Authors', test_user_id, NOW())
        RETURNING id INTO test_discussion_id;
        
        -- Add creator as member of discussions
        INSERT INTO discussion_members (discussion_id, user_id, role, joined_at)
        SELECT id, test_user_id, 'admin', NOW()
        FROM discussions
        WHERE created_by = test_user_id;
        
        RAISE NOTICE 'Created sample discussions and added creator as member';
    END IF;
END $$;

-- ===========================================
-- STEP 7: FINAL VERIFICATION
-- ===========================================

SELECT '=== FINAL DATA VERIFICATION ===' as header;

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
FROM discussion_members;

-- Show sample data that should be returned
SELECT '=== SAMPLE DATA THAT SHOULD DISPLAY ===' as header;

-- Show clubs with membership info
SELECT 
    bc.id,
    bc.name,
    bc.description,
    u.name as creator_name,
    COUNT(bcm.user_id) as member_count
FROM book_clubs bc
LEFT JOIN users u ON bc.creator_id = u.id
LEFT JOIN book_club_members bcm ON bc.id = bcm.club_id
GROUP BY bc.id, bc.name, bc.description, u.name
ORDER BY bc.created_at DESC
LIMIT 3;

-- Show discussions with membership info
SELECT 
    d.id,
    d.title,
    d.content,
    u.name as creator_name,
    COUNT(dm.user_id) as participant_count
FROM discussions d
LEFT JOIN users u ON d.created_by = u.id
LEFT JOIN discussion_members dm ON d.id = dm.discussion_id
GROUP BY d.id, d.title, d.content, u.name
ORDER BY d.created_at DESC
LIMIT 3;

SELECT '=== DATA FLOW DEBUG COMPLETE ===' as header;
