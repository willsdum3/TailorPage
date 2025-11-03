-- Final Data Display Fix
-- This script ensures all data is properly set up and creates a test user with proper memberships

-- ===========================================
-- STEP 1: CLEAR AND RECREATE ALL DATA
-- ===========================================

-- Clear existing data to start fresh
DELETE FROM book_club_members;
DELETE FROM discussion_members;
DELETE FROM book_club_messages;
DELETE FROM discussion_messages;
DELETE FROM book_clubs;
DELETE FROM discussions;
DELETE FROM users;

-- ===========================================
-- STEP 2: CREATE TEST USER
-- ===========================================

INSERT INTO users (auth_user_id, name, username, email, created_at)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'Test User',
    'testuser',
    'test@example.com',
    NOW()
);

-- ===========================================
-- STEP 3: CREATE TEST BOOK CLUBS
-- ===========================================

-- Get the user ID first
DO $$
DECLARE
    test_user_id UUID;
BEGIN
    -- Get the test user ID
    SELECT id INTO test_user_id FROM users WHERE auth_user_id = '00000000-0000-0000-0000-000000000001';
    
    IF test_user_id IS NOT NULL THEN
        -- Create book clubs with the user as creator
        INSERT INTO book_clubs (name, description, creator_id, created_by, created_at, is_public)
        VALUES 
            ('Fantasy Book Club', 'A club for fantasy literature enthusiasts', test_user_id, test_user_id, NOW(), true),
            ('Mystery Readers', 'Discuss mystery and thriller novels', test_user_id, test_user_id, NOW(), true),
            ('Sci-Fi Enthusiasts', 'Science fiction book discussions', test_user_id, test_user_id, NOW(), true);
        
        RAISE NOTICE 'Created book clubs with creator: %', test_user_id;
    ELSE
        RAISE NOTICE 'Test user not found';
    END IF;
END $$;

-- ===========================================
-- STEP 4: CREATE TEST DISCUSSIONS
-- ===========================================

-- Get the user ID first
DO $$
DECLARE
    test_user_id UUID;
BEGIN
    -- Get the test user ID
    SELECT id INTO test_user_id FROM users WHERE auth_user_id = '00000000-0000-0000-0000-000000000001';
    
    IF test_user_id IS NOT NULL THEN
        -- Create discussions with the user as creator
        INSERT INTO discussions (title, content, book_title, book_author, created_by, created_at)
        VALUES 
            ('Best Fantasy Novels', 'What are your favorite fantasy novels?', 'Various', 'Various Authors', test_user_id, NOW()),
            ('Mystery Recommendations', 'Share your favorite mystery books', 'Various', 'Various Authors', test_user_id, NOW()),
            ('Sci-Fi Classics', 'Discuss classic science fiction works', 'Various', 'Various Authors', test_user_id, NOW());
        
        RAISE NOTICE 'Created discussions with creator: %', test_user_id;
    ELSE
        RAISE NOTICE 'Test user not found for discussions';
    END IF;
END $$;

-- ===========================================
-- STEP 5: ADD USER AS MEMBER OF ALL CLUBS
-- ===========================================

-- Get the user ID and add to all clubs
DO $$
DECLARE
    test_user_id UUID;
    membership_count INTEGER;
BEGIN
    -- Get the test user ID
    SELECT id INTO test_user_id FROM users WHERE auth_user_id = '00000000-0000-0000-0000-000000000001';
    
    IF test_user_id IS NOT NULL THEN
        -- Add user as member of all clubs (only if not already a member)
        INSERT INTO book_club_members (club_id, user_id, role, joined_at)
        SELECT 
            bc.id,
            test_user_id,
            'admin',
            NOW()
        FROM book_clubs bc
        WHERE NOT EXISTS (
            SELECT 1 FROM book_club_members bcm 
            WHERE bcm.club_id = bc.id 
            AND bcm.user_id = test_user_id
        );
        
        GET DIAGNOSTICS membership_count = ROW_COUNT;
        RAISE NOTICE 'Added user to % clubs', membership_count;
    ELSE
        RAISE NOTICE 'Test user not found for club memberships';
    END IF;
END $$;

-- ===========================================
-- STEP 6: ADD USER AS MEMBER OF ALL DISCUSSIONS
-- ===========================================

-- Get the user ID and add to all discussions
DO $$
DECLARE
    test_user_id UUID;
    discussion_membership_count INTEGER;
BEGIN
    -- Get the test user ID
    SELECT id INTO test_user_id FROM users WHERE auth_user_id = '00000000-0000-0000-0000-000000000001';
    
    IF test_user_id IS NOT NULL THEN
        -- Add user as member of all discussions (only if not already a member)
        INSERT INTO discussion_members (discussion_id, user_id, role, joined_at)
        SELECT 
            d.id,
            test_user_id,
            'admin',
            NOW()
        FROM discussions d
        WHERE NOT EXISTS (
            SELECT 1 FROM discussion_members dm 
            WHERE dm.discussion_id = d.id 
            AND dm.user_id = test_user_id
        );
        
        GET DIAGNOSTICS discussion_membership_count = ROW_COUNT;
        RAISE NOTICE 'Added user to % discussions', discussion_membership_count;
    ELSE
        RAISE NOTICE 'Test user not found for discussion memberships';
    END IF;
END $$;

-- ===========================================
-- STEP 7: ADD SAMPLE MESSAGES
-- ===========================================

-- Add messages to first club
DO $$
DECLARE
    test_user_id UUID;
    target_club_id UUID;
    target_discussion_id UUID;
    message_exists BOOLEAN;
BEGIN
    -- Get the test user ID
    SELECT id INTO test_user_id FROM users WHERE auth_user_id = '00000000-0000-0000-0000-000000000001';
    
    IF test_user_id IS NOT NULL THEN
        -- Get the fantasy book club ID
        SELECT id INTO target_club_id FROM book_clubs WHERE name = 'Fantasy Book Club' LIMIT 1;
        
        IF target_club_id IS NOT NULL THEN
            -- Check if message already exists
            SELECT EXISTS (
                SELECT 1 FROM book_club_messages 
                WHERE club_id = target_club_id 
                AND user_id = test_user_id 
                AND message = 'Welcome to our fantasy book club!'
            ) INTO message_exists;
            
            IF NOT message_exists THEN
                -- Add message to club
                INSERT INTO book_club_messages (club_id, user_id, message, created_at)
                VALUES (target_club_id, test_user_id, 'Welcome to our fantasy book club!', NOW());
                
                RAISE NOTICE 'Added message to club: %', target_club_id;
            ELSE
                RAISE NOTICE 'Message already exists in club: %', target_club_id;
            END IF;
        END IF;
        
        -- Get the fantasy discussion ID
        SELECT id INTO target_discussion_id FROM discussions WHERE title = 'Best Fantasy Novels' LIMIT 1;
        
        IF target_discussion_id IS NOT NULL THEN
            -- Check if message already exists
            SELECT EXISTS (
                SELECT 1 FROM discussion_messages 
                WHERE discussion_id = target_discussion_id 
                AND user_id = test_user_id 
                AND message = 'I love The Lord of the Rings series!'
            ) INTO message_exists;
            
            IF NOT message_exists THEN
                -- Add message to discussion
                INSERT INTO discussion_messages (discussion_id, user_id, message, created_at)
                VALUES (target_discussion_id, test_user_id, 'I love The Lord of the Rings series!', NOW());
                
                RAISE NOTICE 'Added message to discussion: %', target_discussion_id;
            ELSE
                RAISE NOTICE 'Message already exists in discussion: %', target_discussion_id;
            END IF;
        END IF;
    ELSE
        RAISE NOTICE 'Test user not found for messages';
    END IF;
END $$;

-- ===========================================
-- STEP 8: TEST FUNCTIONS WITH TEST USER
-- ===========================================

DO $$
DECLARE
    test_auth_id UUID := '00000000-0000-0000-0000-000000000001';
    club_count INTEGER := 0;
    discussion_count INTEGER := 0;
    club_record RECORD;
    discussion_record RECORD;
BEGIN
    RAISE NOTICE 'Testing with test user: %', test_auth_id;
    
    -- Test get_book_clubs
    SELECT COUNT(*) INTO club_count FROM get_book_clubs(test_auth_id);
    RAISE NOTICE 'get_book_clubs returned % records', club_count;
    
    -- Show first club
    FOR club_record IN SELECT * FROM get_book_clubs(test_auth_id) LIMIT 1 LOOP
        RAISE NOTICE 'First club: id=%, name=%, creator=%, is_member=%, is_admin=%', 
            club_record.id, club_record.name, club_record.creator_name, club_record.is_member, club_record.is_admin;
    END LOOP;
    
    -- Test get_discussions
    SELECT COUNT(*) INTO discussion_count FROM get_discussions(test_auth_id);
    RAISE NOTICE 'get_discussions returned % records', discussion_count;
    
    -- Show first discussion
    FOR discussion_record IN SELECT * FROM get_discussions(test_auth_id) LIMIT 1 LOOP
        RAISE NOTICE 'First discussion: id=%, title=%, creator=%, is_participant=%', 
            discussion_record.id, discussion_record.title, discussion_record.creator_name, discussion_record.is_participant;
    END LOOP;
END $$;

-- ===========================================
-- STEP 9: FINAL VERIFICATION
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

-- Show the exact data that should be returned
SELECT '=== DATA THAT SHOULD DISPLAY ===' as header;

-- Show clubs with membership info
SELECT 
    bc.id,
    bc.name,
    bc.description,
    u.name as creator_name,
    COUNT(bcm.user_id) as member_count,
    bc.is_public
FROM book_clubs bc
LEFT JOIN users u ON bc.creator_id = u.id
LEFT JOIN book_club_members bcm ON bc.id = bcm.club_id
GROUP BY bc.id, bc.name, bc.description, u.name, bc.is_public
ORDER BY bc.created_at DESC;

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
ORDER BY d.created_at DESC;

SELECT '=== TEST DATA CREATION COMPLETE ===' as header;
SELECT 'Use auth_user_id: 00000000-0000-0000-0000-000000000001 for testing' as note;
