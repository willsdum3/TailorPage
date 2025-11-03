-- Debug and Restore Data for Book Clubs and Discussions
-- This script checks what's in the database and fixes data display issues

-- ===========================================
-- STEP 1: CHECK CURRENT DATA STATUS
-- ===========================================

SELECT '=== DATA STATUS CHECK ===' as header;

SELECT 
    'Users' as table_name,
    COUNT(*) as total_records
FROM users
UNION ALL
SELECT 
    'Book Clubs' as table_name,
    COUNT(*) as total_records
FROM book_clubs
UNION ALL
SELECT 
    'Book Club Members' as table_name,
    COUNT(*) as total_records
FROM book_club_members
UNION ALL
SELECT 
    'Discussions' as table_name,
    COUNT(*) as total_records
FROM discussions
UNION ALL
SELECT 
    'Discussion Members' as table_name,
    COUNT(*) as total_records
FROM discussion_members;

-- Check specific book club data
SELECT '=== BOOK CLUBS DATA ===' as header;
SELECT 
    id,
    name,
    description,
    creator_id,
    created_at,
    is_public
FROM book_clubs
LIMIT 10;

-- Check specific discussion data
SELECT '=== DISCUSSIONS DATA ===' as header;
SELECT 
    id,
    title,
    content,
    created_by,
    created_at
FROM discussions
LIMIT 10;

-- Check users
SELECT '=== USERS DATA ===' as header;
SELECT 
    id,
    auth_user_id,
    name,
    username,
    email
FROM users
LIMIT 10;

-- ===========================================
-- STEP 2: CHECK FUNCTION OUTPUT
-- ===========================================

SELECT '=== TESTING FUNCTIONS ===' as header;

-- Get a user to test with
DO $$
DECLARE
    test_auth_user_id UUID;
    test_club_count INTEGER;
    test_discussion_count INTEGER;
    test_user_id UUID;
    test_username TEXT;
BEGIN
    -- Get first user
    SELECT auth_user_id, id, username INTO test_auth_user_id, test_user_id, test_username 
    FROM users LIMIT 1;
    
    IF test_auth_user_id IS NOT NULL THEN
        RAISE NOTICE 'Testing with auth_user_id: %, user_id: %, username: %', test_auth_user_id, test_user_id, test_username;
        
        -- Test get_book_clubs function
        SELECT COUNT(*) INTO test_club_count 
        FROM get_book_clubs(test_auth_user_id);
        
        RAISE NOTICE 'get_book_clubs returned % records', test_club_count;
        
        -- Test get_discussions function
        SELECT COUNT(*) INTO test_discussion_count 
        FROM get_discussions(test_auth_user_id);
        
        RAISE NOTICE 'get_discussions returned % records', test_discussion_count;
    ELSE
        RAISE NOTICE 'No users found - cannot test functions';
    END IF;
END $$;

-- ===========================================
-- STEP 3: ENSURE DATA EXISTS
-- ===========================================

SELECT '=== CREATING SAMPLE DATA IF NEEDED ===' as header;

-- Ensure we have at least one user
DO $$
DECLARE
    user_count INTEGER;
    test_user_id UUID;
    test_auth_id UUID;
BEGIN
    SELECT COUNT(*) INTO user_count FROM users;
    
    IF user_count = 0 THEN
        RAISE NOTICE 'Creating test user';
        
        test_auth_id := gen_random_uuid();
        
        INSERT INTO users (auth_user_id, name, username, email, created_at)
        VALUES (test_auth_id, 'Test User', 'testuser', 'test@example.com', NOW())
        RETURNING id INTO test_user_id;
        
        RAISE NOTICE 'Created user: %', test_user_id;
    END IF;
END $$;

-- Ensure we have book clubs
DO $$
DECLARE
    club_count INTEGER;
    user_id UUID;
    club_id UUID;
BEGIN
    SELECT COUNT(*) INTO club_count FROM book_clubs;
    
    IF club_count = 0 THEN
        RAISE NOTICE 'Creating sample book clubs';
        
        -- Get a user
        SELECT id INTO user_id FROM users LIMIT 1;
        
        IF user_id IS NOT NULL THEN
            -- Create clubs
            INSERT INTO book_clubs (name, description, creator_id, created_at, is_public)
            VALUES 
                ('Science Fiction Fans', 'A club for science fiction enthusiasts', user_id, NOW(), true),
                ('Mystery & Thriller', 'Discuss mystery and thriller novels', user_id, NOW(), true),
                ('Historical Fiction', 'Explore historical fiction novels', user_id, NOW(), true)
            RETURNING id INTO club_id;
            
            RAISE NOTICE 'Created sample book clubs';
            
            -- Add creator as admin member
            INSERT INTO book_club_members (club_id, user_id, role, joined_at)
            SELECT id, user_id, 'admin', NOW()
            FROM book_clubs
            WHERE creator_id = user_id;
            
            RAISE NOTICE 'Added creator as admin member';
        END IF;
    END IF;
END $$;

-- Ensure we have discussions
DO $$
DECLARE
    discussion_count INTEGER;
    user_id UUID;
    discussion_id UUID;
BEGIN
    SELECT COUNT(*) INTO discussion_count FROM discussions;
    
    IF discussion_count = 0 THEN
        RAISE NOTICE 'Creating sample discussions';
        
        -- Get a user
        SELECT id INTO user_id FROM users LIMIT 1;
        
        IF user_id IS NOT NULL THEN
            -- Create discussions
            INSERT INTO discussions (title, content, book_title, book_author, created_by, created_at)
            VALUES 
                ('Neuromancer Discussion', 'Let''s discuss William Gibson''s Neuromancer', 'Neuromancer', 'William Gibson', user_id, NOW()),
                ('Best Mystery Novels', 'What are your favorite mystery novels?', 'Various', 'Various Authors', user_id, NOW()),
                ('Historical Accuracy in Fiction', 'How important is historical accuracy?', 'Various', 'Various Authors', user_id, NOW())
            RETURNING id INTO discussion_id;
            
            RAISE NOTICE 'Created sample discussions';
            
            -- Add creator as member of discussions
            INSERT INTO discussion_members (discussion_id, user_id, role, joined_at)
            SELECT id, user_id, 'admin', NOW()
            FROM discussions
            WHERE created_by = user_id;
            
            RAISE NOTICE 'Added creator as discussion member';
        END IF;
    END IF;
END $$;

-- ===========================================
-- STEP 4: FINAL SUMMARY
-- ===========================================

SELECT '=== FINAL DATA SUMMARY ===' as header;

SELECT 
    'Total Users' as metric,
    COUNT(*) as count
FROM users
UNION ALL
SELECT 
    'Total Book Clubs' as metric,
    COUNT(*) as count
FROM book_clubs
UNION ALL
SELECT 
    'Total Discussions' as metric,
    COUNT(*) as count
FROM discussions;

-- Show all book clubs
SELECT '=== ALL BOOK CLUBS ===' as header;
SELECT 
    id,
    name,
    creator_id,
    (SELECT COUNT(*) FROM book_club_members WHERE club_id = book_clubs.id) as member_count
FROM book_clubs
ORDER BY created_at DESC;

-- Show all discussions
SELECT '=== ALL DISCUSSIONS ===' as header;
SELECT 
    id,
    title,
    created_by,
    (SELECT COUNT(*) FROM discussion_members WHERE discussion_id = discussions.id) as member_count
FROM discussions
ORDER BY created_at DESC;

SELECT '=== DATA RESTORATION COMPLETE ===' as header;
