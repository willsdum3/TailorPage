-- Restore User Data Complete
-- This script creates multiple test users and ensures the app has data to work with

-- ===========================================
-- STEP 1: CLEAR ALL EXISTING DATA
-- ===========================================

-- Clear all existing data to start fresh
DELETE FROM book_club_messages;
DELETE FROM discussion_messages;
DELETE FROM book_club_members;
DELETE FROM discussion_members;
DELETE FROM book_clubs;
DELETE FROM discussions;
DELETE FROM users;

-- ===========================================
-- STEP 2: CREATE MULTIPLE TEST USERS
-- ===========================================

-- Create multiple test users with different auth_user_ids
INSERT INTO users (auth_user_id, name, username, email, created_at)
VALUES 
    ('00000000-0000-0000-0000-000000000001', 'Test User 1', 'testuser1', 'test1@example.com', NOW()),
    ('00000000-0000-0000-0000-000000000002', 'Test User 2', 'testuser2', 'test2@example.com', NOW()),
    ('00000000-0000-0000-0000-000000000003', 'Test User 3', 'testuser3', 'test3@example.com', NOW()),
    ('00000000-0000-0000-0000-000000000004', 'Test User 4', 'testuser4', 'test4@example.com', NOW()),
    ('00000000-0000-0000-0000-000000000005', 'Test User 5', 'testuser5', 'test5@example.com', NOW());

-- ===========================================
-- STEP 3: CREATE MULTIPLE BOOK CLUBS
-- ===========================================

-- Create book clubs with different creators
DO $$
DECLARE
    user1_id UUID;
    user2_id UUID;
    user3_id UUID;
BEGIN
    -- Get user IDs
    SELECT id INTO user1_id FROM users WHERE auth_user_id = '00000000-0000-0000-0000-000000000001' LIMIT 1;
    SELECT id INTO user2_id FROM users WHERE auth_user_id = '00000000-0000-0000-0000-000000000002' LIMIT 1;
    SELECT id INTO user3_id FROM users WHERE auth_user_id = '00000000-0000-0000-0000-000000000003' LIMIT 1;
    
    -- Create book clubs
    INSERT INTO book_clubs (name, description, creator_id, created_by, created_at, is_public)
    VALUES 
        ('Fantasy Book Club', 'A club for fantasy literature enthusiasts', user1_id, user1_id, NOW(), true),
        ('Mystery Readers', 'Discuss mystery and thriller novels', user1_id, user1_id, NOW(), true),
        ('Sci-Fi Enthusiasts', 'Science fiction book discussions', user2_id, user2_id, NOW(), true),
        ('Classic Literature', 'Exploring timeless classics', user2_id, user2_id, NOW(), true),
        ('Romance Readers', 'For romance novel enthusiasts', user3_id, user3_id, NOW(), true);
    
    RAISE NOTICE 'Created 5 book clubs';
END $$;

-- ===========================================
-- STEP 4: CREATE MULTIPLE DISCUSSIONS
-- ===========================================

-- Create discussions with different creators
DO $$
DECLARE
    user1_id UUID;
    user2_id UUID;
    user3_id UUID;
    user4_id UUID;
    user5_id UUID;
BEGIN
    -- Get user IDs
    SELECT id INTO user1_id FROM users WHERE auth_user_id = '00000000-0000-0000-0000-000000000001' LIMIT 1;
    SELECT id INTO user2_id FROM users WHERE auth_user_id = '00000000-0000-0000-0000-000000000002' LIMIT 1;
    SELECT id INTO user3_id FROM users WHERE auth_user_id = '00000000-0000-0000-0000-000000000003' LIMIT 1;
    SELECT id INTO user4_id FROM users WHERE auth_user_id = '00000000-0000-0000-0000-000000000004' LIMIT 1;
    SELECT id INTO user5_id FROM users WHERE auth_user_id = '00000000-0000-0000-0000-000000000005' LIMIT 1;
    
    -- Create discussions
    INSERT INTO discussions (title, content, book_title, book_author, created_by, created_at)
    VALUES 
        ('Best Fantasy Novels', 'What are your favorite fantasy novels?', 'Various', 'Various Authors', user1_id, NOW()),
        ('Mystery Recommendations', 'Share your favorite mystery books', 'Various', 'Various Authors', user2_id, NOW()),
        ('Sci-Fi Classics', 'Discuss classic science fiction works', 'Various', 'Various Authors', user3_id, NOW()),
        ('Classic Literature Discussion', 'Thoughts on classic literature', 'Various', 'Various Authors', user4_id, NOW()),
        ('Romance Book Reviews', 'Share your favorite romance novels', 'Various', 'Various Authors', user5_id, NOW());
    
    RAISE NOTICE 'Created 5 discussions';
END $$;

-- ===========================================
-- STEP 5: ADD USERS AS MEMBERS OF CLUBS
-- ===========================================

-- Add all users as members of all clubs
DO $$
DECLARE
    membership_count INTEGER;
BEGIN
    -- Add all users to all clubs (only if not already a member)
    INSERT INTO book_club_members (club_id, user_id, role, joined_at)
    SELECT 
        bc.id,
        u.id,
        CASE 
            WHEN bc.creator_id = u.id THEN 'admin'
            ELSE 'member'
        END,
        NOW()
    FROM book_clubs bc
    CROSS JOIN users u
    WHERE NOT EXISTS (
        SELECT 1 FROM book_club_members bcm 
        WHERE bcm.club_id = bc.id 
        AND bcm.user_id = u.id
    );
    
    GET DIAGNOSTICS membership_count = ROW_COUNT;
    RAISE NOTICE 'Added % club memberships', membership_count;
END $$;

-- ===========================================
-- STEP 6: ADD USERS AS MEMBERS OF DISCUSSIONS
-- ===========================================

-- Add all users as members of all discussions
DO $$
DECLARE
    membership_count INTEGER;
BEGIN
    -- Add all users to all discussions (only if not already a member)
    INSERT INTO discussion_members (discussion_id, user_id, role, joined_at)
    SELECT 
        d.id,
        u.id,
        CASE 
            WHEN d.created_by = u.id THEN 'admin'
            ELSE 'member'
        END,
        NOW()
    FROM discussions d
    CROSS JOIN users u
    WHERE NOT EXISTS (
        SELECT 1 FROM discussion_members dm 
        WHERE dm.discussion_id = d.id 
        AND dm.user_id = u.id
    );
    
    GET DIAGNOSTICS membership_count = ROW_COUNT;
    RAISE NOTICE 'Added % discussion memberships', membership_count;
END $$;

-- ===========================================
-- STEP 7: ADD SAMPLE MESSAGES
-- ===========================================

-- Add messages to clubs and discussions
DO $$
DECLARE
    user1_id UUID;
    user2_id UUID;
    user3_id UUID;
    club1_id UUID;
    club2_id UUID;
    discussion1_id UUID;
    discussion2_id UUID;
BEGIN
    -- Get user IDs
    SELECT id INTO user1_id FROM users WHERE auth_user_id = '00000000-0000-0000-0000-000000000001' LIMIT 1;
    SELECT id INTO user2_id FROM users WHERE auth_user_id = '00000000-0000-0000-0000-000000000002' LIMIT 1;
    SELECT id INTO user3_id FROM users WHERE auth_user_id = '00000000-0000-0000-0000-000000000003' LIMIT 1;
    
    -- Get club IDs
    SELECT id INTO club1_id FROM book_clubs WHERE name = 'Fantasy Book Club' LIMIT 1;
    SELECT id INTO club2_id FROM book_clubs WHERE name = 'Mystery Readers' LIMIT 1;
    
    -- Get discussion IDs
    SELECT id INTO discussion1_id FROM discussions WHERE title = 'Best Fantasy Novels' LIMIT 1;
    SELECT id INTO discussion2_id FROM discussions WHERE title = 'Mystery Recommendations' LIMIT 1;
    
    -- Add messages to clubs (only if they don't already exist)
    IF club1_id IS NOT NULL THEN
        INSERT INTO book_club_messages (club_id, user_id, message, created_at)
        SELECT club1_id, user1_id, 'Welcome to our fantasy book club!', NOW()
        WHERE NOT EXISTS (
            SELECT 1 FROM book_club_messages 
            WHERE club_id = club1_id 
            AND user_id = user1_id 
            AND message = 'Welcome to our fantasy book club!'
        );
        
        INSERT INTO book_club_messages (club_id, user_id, message, created_at)
        SELECT club1_id, user2_id, 'I love fantasy novels!', NOW()
        WHERE NOT EXISTS (
            SELECT 1 FROM book_club_messages 
            WHERE club_id = club1_id 
            AND user_id = user2_id 
            AND message = 'I love fantasy novels!'
        );
        
        INSERT INTO book_club_messages (club_id, user_id, message, created_at)
        SELECT club1_id, user3_id, 'What are we reading next?', NOW()
        WHERE NOT EXISTS (
            SELECT 1 FROM book_club_messages 
            WHERE club_id = club1_id 
            AND user_id = user3_id 
            AND message = 'What are we reading next?'
        );
    END IF;
    
    IF club2_id IS NOT NULL THEN
        INSERT INTO book_club_messages (club_id, user_id, message, created_at)
        SELECT club2_id, user1_id, 'Welcome to our mystery book club!', NOW()
        WHERE NOT EXISTS (
            SELECT 1 FROM book_club_messages 
            WHERE club_id = club2_id 
            AND user_id = user1_id 
            AND message = 'Welcome to our mystery book club!'
        );
        
        INSERT INTO book_club_messages (club_id, user_id, message, created_at)
        SELECT club2_id, user2_id, 'I love mystery novels!', NOW()
        WHERE NOT EXISTS (
            SELECT 1 FROM book_club_messages 
            WHERE club_id = club2_id 
            AND user_id = user2_id 
            AND message = 'I love mystery novels!'
        );
        
        INSERT INTO book_club_messages (club_id, user_id, message, created_at)
        SELECT club2_id, user3_id, 'What mystery should we read?', NOW()
        WHERE NOT EXISTS (
            SELECT 1 FROM book_club_messages 
            WHERE club_id = club2_id 
            AND user_id = user3_id 
            AND message = 'What mystery should we read?'
        );
    END IF;
    
    -- Add messages to discussions (only if they don't already exist)
    IF discussion1_id IS NOT NULL THEN
        INSERT INTO discussion_messages (discussion_id, user_id, message, created_at)
        SELECT discussion1_id, user1_id, 'I love The Lord of the Rings series!', NOW()
        WHERE NOT EXISTS (
            SELECT 1 FROM discussion_messages 
            WHERE discussion_id = discussion1_id 
            AND user_id = user1_id 
            AND message = 'I love The Lord of the Rings series!'
        );
        
        INSERT INTO discussion_messages (discussion_id, user_id, message, created_at)
        SELECT discussion1_id, user2_id, 'Game of Thrones is amazing!', NOW()
        WHERE NOT EXISTS (
            SELECT 1 FROM discussion_messages 
            WHERE discussion_id = discussion1_id 
            AND user_id = user2_id 
            AND message = 'Game of Thrones is amazing!'
        );
        
        INSERT INTO discussion_messages (discussion_id, user_id, message, created_at)
        SELECT discussion1_id, user3_id, 'What about The Wheel of Time?', NOW()
        WHERE NOT EXISTS (
            SELECT 1 FROM discussion_messages 
            WHERE discussion_id = discussion1_id 
            AND user_id = user3_id 
            AND message = 'What about The Wheel of Time?'
        );
    END IF;
    
    IF discussion2_id IS NOT NULL THEN
        INSERT INTO discussion_messages (discussion_id, user_id, message, created_at)
        SELECT discussion2_id, user1_id, 'I recommend Agatha Christie!', NOW()
        WHERE NOT EXISTS (
            SELECT 1 FROM discussion_messages 
            WHERE discussion_id = discussion2_id 
            AND user_id = user1_id 
            AND message = 'I recommend Agatha Christie!'
        );
        
        INSERT INTO discussion_messages (discussion_id, user_id, message, created_at)
        SELECT discussion2_id, user2_id, 'Sherlock Holmes is a must-read!', NOW()
        WHERE NOT EXISTS (
            SELECT 1 FROM discussion_messages 
            WHERE discussion_id = discussion2_id 
            AND user_id = user2_id 
            AND message = 'Sherlock Holmes is a must-read!'
        );
        
        INSERT INTO discussion_messages (discussion_id, user_id, message, created_at)
        SELECT discussion2_id, user3_id, 'What about modern mystery novels?', NOW()
        WHERE NOT EXISTS (
            SELECT 1 FROM discussion_messages 
            WHERE discussion_id = discussion2_id 
            AND user_id = user3_id 
            AND message = 'What about modern mystery novels?'
        );
    END IF;
    
    RAISE NOTICE 'Added sample messages to clubs and discussions';
END $$;

-- ===========================================
-- STEP 8: TEST FUNCTIONS WITH ALL USERS
-- ===========================================

-- Test functions with all users
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

-- Show all users with their auth_user_ids
SELECT '=== ALL TEST USERS ===' as header;
SELECT 
    auth_user_id,
    name,
    username,
    email
FROM users
ORDER BY created_at;

-- Show sample data that should be returned
SELECT '=== SAMPLE CLUBS ===' as header;
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
ORDER BY bc.created_at DESC;

SELECT '=== SAMPLE DISCUSSIONS ===' as header;
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

SELECT '=== USER DATA RESTORATION COMPLETE ===' as header;
SELECT 'Use any of these auth_user_ids for testing:' as note;
SELECT '00000000-0000-0000-0000-000000000001 (Test User 1)' as user1;
SELECT '00000000-0000-0000-0000-000000000002 (Test User 2)' as user2;
SELECT '00000000-0000-0000-0000-000000000003 (Test User 3)' as user3;
SELECT '00000000-0000-0000-0000-000000000004 (Test User 4)' as user4;
SELECT '00000000-0000-0000-0000-000000000005 (Test User 5)' as user5;
