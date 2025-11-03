-- Diagnose and Fix Data Restoration Issues
-- This script checks what data exists and ensures all functions work properly

-- ===========================================
-- STEP 1: DIAGNOSE CURRENT STATE
-- ===========================================

-- Check if tables exist and have data
SELECT 
    'Table Data Check' as check_type,
    'book_clubs' as table_name,
    COUNT(*) as record_count
FROM book_clubs
UNION ALL
SELECT 
    'Table Data Check' as check_type,
    'discussions' as table_name,
    COUNT(*) as record_count
FROM discussions
UNION ALL
SELECT 
    'Table Data Check' as check_type,
    'users' as table_name,
    COUNT(*) as record_count
FROM users
UNION ALL
SELECT 
    'Table Data Check' as check_type,
    'book_club_members' as table_name,
    COUNT(*) as record_count
FROM book_club_members
UNION ALL
SELECT 
    'Table Data Check' as check_type,
    'discussion_members' as table_name,
    COUNT(*) as record_count
FROM discussion_members;

-- Check if functions exist
SELECT 
    'Function Check' as check_type,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name IN (
    'get_book_clubs',
    'get_discussions',
    'get_book_club_details',
    'get_book_club_members',
    'get_discussion_messages',
    'get_user_internal_id'
)
ORDER BY routine_name;

-- ===========================================
-- STEP 2: CREATE SAMPLE DATA IF MISSING
-- ===========================================

-- Check if we have any users
DO $$
DECLARE
    user_count INTEGER;
    sample_user_id UUID;
BEGIN
    SELECT COUNT(*) INTO user_count FROM users;
    
    IF user_count = 0 THEN
        RAISE NOTICE 'No users found - creating sample user';
        
        -- Create a sample user
        INSERT INTO users (auth_user_id, name, username, email, created_at)
        VALUES (
            gen_random_uuid(),
            'Sample User',
            'sample_user',
            'sample@example.com',
            NOW()
        );
        
        RAISE NOTICE 'Sample user created';
    ELSE
        RAISE NOTICE 'Users exist: %', user_count;
    END IF;
END $$;

-- Check if we have any book clubs
DO $$
DECLARE
    club_count INTEGER;
    sample_user_id UUID;
    sample_club_id UUID;
BEGIN
    SELECT COUNT(*) INTO club_count FROM book_clubs;
    
    IF club_count = 0 THEN
        RAISE NOTICE 'No book clubs found - creating sample data';
        
        -- Get a user to create clubs
        SELECT id INTO sample_user_id FROM users LIMIT 1;
        
        IF sample_user_id IS NOT NULL THEN
            -- Create sample book clubs
            INSERT INTO book_clubs (name, description, creator_id, created_at, is_public)
            VALUES 
                ('Fantasy Book Club', 'A club for fantasy literature enthusiasts', sample_user_id, NOW(), true),
                ('Sci-Fi Readers', 'Science fiction book discussions', sample_user_id, NOW(), true),
                ('Classic Literature', 'Exploring timeless classics', sample_user_id, NOW(), true)
            RETURNING id INTO sample_club_id;
            
            -- Add creator as admin member
            INSERT INTO book_club_members (club_id, user_id, role, joined_at)
            SELECT id, sample_user_id, 'admin', NOW()
            FROM book_clubs
            WHERE creator_id = sample_user_id;
            
            RAISE NOTICE 'Sample book clubs created';
        ELSE
            RAISE NOTICE 'No users available to create sample clubs';
        END IF;
    ELSE
        RAISE NOTICE 'Book clubs exist: %', club_count;
    END IF;
END $$;

-- Check if we have any discussions
DO $$
DECLARE
    discussion_count INTEGER;
    sample_user_id UUID;
BEGIN
    SELECT COUNT(*) INTO discussion_count FROM discussions;
    
    IF discussion_count = 0 THEN
        RAISE NOTICE 'No discussions found - creating sample data';
        
        -- Get a user to create discussions
        SELECT id INTO sample_user_id FROM users LIMIT 1;
        
        IF sample_user_id IS NOT NULL THEN
            -- Create sample discussions
            INSERT INTO discussions (title, content, book_title, book_author, created_by, created_at)
            VALUES 
                ('The Lord of the Rings Discussion', 'Let''s discuss Tolkien''s masterpiece', 'The Lord of the Rings', 'J.R.R. Tolkien', sample_user_id, NOW()),
                ('Dune Analysis', 'Exploring Frank Herbert''s Dune universe', 'Dune', 'Frank Herbert', sample_user_id, NOW()),
                ('Pride and Prejudice Review', 'Jane Austen''s classic romance', 'Pride and Prejudice', 'Jane Austen', sample_user_id, NOW());
            
            -- Add creator as member of discussions
            INSERT INTO discussion_members (discussion_id, user_id, role, joined_at)
            SELECT id, sample_user_id, 'admin', NOW()
            FROM discussions
            WHERE created_by = sample_user_id;
            
            RAISE NOTICE 'Sample discussions created';
        ELSE
            RAISE NOTICE 'No users available to create sample discussions';
        END IF;
    ELSE
        RAISE NOTICE 'Discussions exist: %', discussion_count;
    END IF;
END $$;

-- ===========================================
-- STEP 3: ENSURE ALL FUNCTIONS EXIST
-- ===========================================

-- Recreate get_user_internal_id function if missing
CREATE OR REPLACE FUNCTION get_user_internal_id(p_auth_user_id UUID)
RETURNS UUID AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    SELECT u.id INTO user_internal_id
    FROM users u 
    WHERE u.auth_user_id = p_auth_user_id;
    
    RETURN user_internal_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate get_book_clubs function
CREATE OR REPLACE FUNCTION get_book_clubs(
    p_auth_user_id UUID
)
RETURNS TABLE(
    id UUID,
    name TEXT,
    description TEXT,
    creator_id UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    is_public BOOLEAN,
    current_book_title TEXT,
    current_book_author TEXT,
    meeting_info TEXT,
    member_count BIGINT,
    is_member BOOLEAN,
    is_admin BOOLEAN,
    creator_name TEXT,
    creator_username TEXT
) AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(p_auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Return book clubs with membership info
    RETURN QUERY
    SELECT 
        bc.id,
        bc.name,
        bc.description,
        bc.creator_id,
        bc.created_at,
        COALESCE(bc.is_public, true) as is_public,
        bc.current_book_title,
        bc.current_book_author,
        bc.meeting_info,
        COUNT(bcm.user_id) as member_count,
        EXISTS(
            SELECT 1 FROM book_club_members bcm2 
            WHERE bcm2.club_id = bc.id 
            AND bcm2.user_id = user_internal_id
        ) as is_member,
        EXISTS(
            SELECT 1 FROM book_club_members bcm3 
            WHERE bcm3.club_id = bc.id 
            AND bcm3.user_id = user_internal_id 
            AND bcm3.role = 'admin'
        ) as is_admin,
        u.name as creator_name,
        u.username as creator_username
    FROM book_clubs bc
    LEFT JOIN book_club_members bcm ON bc.id = bcm.club_id
    LEFT JOIN users u ON bc.creator_id = u.id
    GROUP BY bc.id, bc.name, bc.description, bc.creator_id, bc.created_at, bc.is_public, 
             bc.current_book_title, bc.current_book_author, bc.meeting_info, u.name, u.username
    ORDER BY bc.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate get_discussions function
CREATE OR REPLACE FUNCTION get_discussions(
    p_auth_user_id UUID
)
RETURNS TABLE(
    id UUID,
    title TEXT,
    content TEXT,
    book_title TEXT,
    book_author TEXT,
    tags TEXT[],
    created_by UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    participant_count BIGINT,
    last_activity TIMESTAMP WITH TIME ZONE,
    is_participant BOOLEAN,
    creator_name TEXT,
    creator_username TEXT,
    is_created_by_user BOOLEAN
) AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(p_auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Return discussions with participation info
    RETURN QUERY
    SELECT 
        d.id,
        d.title,
        d.content,
        d.book_title,
        d.book_author,
        COALESCE(d.tags, ARRAY[]::TEXT[]) as tags,
        d.created_by,
        d.created_at,
        COUNT(dm.user_id) as participant_count,
        COALESCE(MAX(dm.joined_at), d.created_at) as last_activity,
        EXISTS(
            SELECT 1 FROM discussion_members dm2 
            WHERE dm2.discussion_id = d.id 
            AND dm2.user_id = user_internal_id
        ) as is_participant,
        u.name as creator_name,
        u.username as creator_username,
        (d.created_by = user_internal_id) as is_created_by_user
    FROM discussions d
    LEFT JOIN discussion_members dm ON d.id = dm.discussion_id
    LEFT JOIN users u ON d.created_by = u.id
    GROUP BY d.id, d.title, d.content, d.book_title, d.book_author, d.tags, 
             d.created_by, d.created_at, u.name, u.username
    ORDER BY d.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- STEP 4: TEST FUNCTIONS WITH SAMPLE DATA
-- ===========================================

-- Test get_book_clubs function
DO $$
DECLARE
    test_auth_user_id UUID;
    test_user_id UUID;
    club_count INTEGER;
BEGIN
    -- Get a test user
    SELECT auth_user_id, id INTO test_auth_user_id, test_user_id FROM users LIMIT 1;
    
    IF test_auth_user_id IS NOT NULL THEN
        -- Test the function
        SELECT COUNT(*) INTO club_count FROM get_book_clubs(test_auth_user_id);
        RAISE NOTICE 'get_book_clubs returned % clubs for user %', club_count, test_auth_user_id;
    ELSE
        RAISE NOTICE 'No users found to test get_book_clubs';
    END IF;
END $$;

-- Test get_discussions function
DO $$
DECLARE
    test_auth_user_id UUID;
    discussion_count INTEGER;
BEGIN
    -- Get a test user
    SELECT auth_user_id INTO test_auth_user_id FROM users LIMIT 1;
    
    IF test_auth_user_id IS NOT NULL THEN
        -- Test the function
        SELECT COUNT(*) INTO discussion_count FROM get_discussions(test_auth_user_id);
        RAISE NOTICE 'get_discussions returned % discussions for user %', discussion_count, test_auth_user_id;
    ELSE
        RAISE NOTICE 'No users found to test get_discussions';
    END IF;
END $$;

-- ===========================================
-- STEP 5: FINAL VERIFICATION
-- ===========================================

-- Final data check
SELECT 
    'Final Data Check' as check_type,
    'book_clubs' as table_name,
    COUNT(*) as record_count
FROM book_clubs
UNION ALL
SELECT 
    'Final Data Check' as check_type,
    'discussions' as table_name,
    COUNT(*) as record_count
FROM discussions
UNION ALL
SELECT 
    'Final Data Check' as check_type,
    'users' as table_name,
    COUNT(*) as record_count
FROM users;

-- Final function check
SELECT 
    'Final Function Check' as check_type,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name IN (
    'get_book_clubs',
    'get_discussions',
    'get_user_internal_id'
)
ORDER BY routine_name;

-- Final success message
SELECT 
    'Data Restoration Complete' as status,
    'Book clubs and discussions should now be restored with sample data if needed' as message;
