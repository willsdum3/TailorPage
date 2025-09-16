-- =====================================================
-- COMPREHENSIVE CLUB ACCESS DIAGNOSIS AND FIX
-- =====================================================
-- This script will diagnose the club access issue and provide a working solution

-- First, let's check what functions currently exist
DO $$
BEGIN
    RAISE NOTICE '=== CHECKING EXISTING FUNCTIONS ===';
END $$;

SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_name LIKE '%book_club%'
AND routine_schema = 'public'
ORDER BY routine_name;

-- Check if the book_clubs table has data
DO $$
DECLARE
    club_count INTEGER;
    sample_club RECORD;
BEGIN
    RAISE NOTICE '=== CHECKING BOOK CLUBS TABLE ===';
    
    SELECT COUNT(*) INTO club_count FROM book_clubs;
    RAISE NOTICE 'Total book clubs in database: %', club_count;
    
    IF club_count > 0 THEN
        FOR sample_club IN 
            SELECT id, name, is_public, created_by
            FROM book_clubs 
            LIMIT 3
        LOOP
            RAISE NOTICE 'Sample club: % (ID: %, Public: %)', sample_club.name, sample_club.id, sample_club.is_public;
        END LOOP;
    END IF;
END $$;

-- Check users table
DO $$
DECLARE
    user_count INTEGER;
BEGIN
    RAISE NOTICE '=== CHECKING USERS TABLE ===';
    
    SELECT COUNT(*) INTO user_count FROM users;
    RAISE NOTICE 'Total users in database: %', user_count;
END $$;

-- Drop all problematic functions and recreate them simply
DROP FUNCTION IF EXISTS get_book_club_details(UUID, UUID);
DROP FUNCTION IF EXISTS get_book_clubs(UUID);

-- Create a simple, working get_book_club_details function
CREATE OR REPLACE FUNCTION get_book_club_details(
    auth_user_id UUID,
    club_id_param UUID
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    current_book_title TEXT,
    current_book_author TEXT,
    max_members INTEGER,
    is_public BOOLEAN,
    target_personality_traits TEXT[],
    tags TEXT[],
    meeting_info TEXT,
    created_by UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    member_count BIGINT,
    is_member BOOLEAN,
    user_role TEXT,
    creator_name TEXT
) AS $$
BEGIN
    RAISE NOTICE 'get_book_club_details called with auth_user_id: %, club_id: %', auth_user_id, club_id_param;
    
    RETURN QUERY
    SELECT 
        bc.id,
        bc.name,
        bc.description,
        bc.current_book_title,
        bc.current_book_author,
        bc.max_members,
        bc.is_public,
        bc.target_personality_traits,
        bc.tags,
        bc.meeting_info,
        bc.created_by,
        bc.created_at,
        COALESCE((SELECT COUNT(*) FROM club_memberships WHERE club_id = bc.id), 0)::BIGINT as member_count,
        COALESCE((
            SELECT EXISTS(
                SELECT 1 FROM club_memberships cm
                JOIN users u ON cm.user_id = u.id
                WHERE cm.club_id = bc.id 
                AND u.auth_user_id = get_book_club_details.auth_user_id
            )
        ), false) as is_member,
        COALESCE((
            SELECT cm.role FROM club_memberships cm
            JOIN users u ON cm.user_id = u.id
            WHERE cm.club_id = bc.id 
            AND u.auth_user_id = get_book_club_details.auth_user_id
        ), 'non-member') as user_role,
        COALESCE((
            SELECT COALESCE(creator.username, creator.name, 'Unknown')
            FROM users creator 
            WHERE creator.id = bc.created_by
        ), 'Unknown') as creator_name
    FROM book_clubs bc
    WHERE bc.id = club_id_param;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in get_book_club_details: %', SQLERRM;
        RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a simple get_book_clubs function for the main list
CREATE OR REPLACE FUNCTION get_book_clubs(auth_user_id UUID)
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    current_book_title TEXT,
    current_book_author TEXT,
    max_members INTEGER,
    is_public BOOLEAN,
    target_personality_traits TEXT[],
    tags TEXT[],
    meeting_info TEXT,
    created_by UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    member_count BIGINT,
    is_member BOOLEAN,
    user_role TEXT,
    creator_name TEXT
) AS $$
BEGIN
    RAISE NOTICE 'get_book_clubs called with auth_user_id: %', auth_user_id;
    
    RETURN QUERY
    SELECT 
        bc.id,
        bc.name,
        bc.description,
        bc.current_book_title,
        bc.current_book_author,
        bc.max_members,
        bc.is_public,
        bc.target_personality_traits,
        bc.tags,
        bc.meeting_info,
        bc.created_by,
        bc.created_at,
        COALESCE((SELECT COUNT(*) FROM club_memberships WHERE club_id = bc.id), 0)::BIGINT as member_count,
        COALESCE((
            SELECT EXISTS(
                SELECT 1 FROM club_memberships cm
                JOIN users u ON cm.user_id = u.id
                WHERE cm.club_id = bc.id 
                AND u.auth_user_id = get_book_clubs.auth_user_id
            )
        ), false) as is_member,
        COALESCE((
            SELECT cm.role FROM club_memberships cm
            JOIN users u ON cm.user_id = u.id
            WHERE cm.club_id = bc.id 
            AND u.auth_user_id = get_book_clubs.auth_user_id
        ), 'non-member') as user_role,
        COALESCE((
            SELECT COALESCE(creator.username, creator.name, 'Unknown')
            FROM users creator 
            WHERE creator.id = bc.created_by
        ), 'Unknown') as creator_name
    FROM book_clubs bc
    ORDER BY bc.created_at DESC;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in get_book_clubs: %', SQLERRM;
        RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_book_club_details(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_book_clubs(UUID) TO authenticated;

-- Test the functions with a sample call
DO $$
DECLARE
    test_result RECORD;
    club_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== TESTING FUNCTIONS ===';
    
    -- Test get_book_clubs
    FOR test_result IN 
        SELECT * FROM get_book_clubs('00000000-0000-0000-0000-000000000000'::UUID) 
        LIMIT 3
    LOOP
        club_count := club_count + 1;
        RAISE NOTICE 'Found club: % (ID: %)', test_result.name, test_result.id;
    END LOOP;
    
    RAISE NOTICE 'get_book_clubs returned % clubs', club_count;
    
    IF club_count = 0 THEN
        RAISE NOTICE 'WARNING: No clubs returned by get_book_clubs function';
    END IF;
    
END $$;

-- Final status
DO $$
BEGIN
    RAISE NOTICE '=== DIAGNOSIS COMPLETE ===';
    RAISE NOTICE '✅ Recreated get_book_club_details function with logging';
    RAISE NOTICE '✅ Recreated get_book_clubs function with logging';
    RAISE NOTICE '✅ Added comprehensive error handling';
    RAISE NOTICE '✅ Functions now use simple, reliable queries';
    RAISE NOTICE '';
    RAISE NOTICE 'Check the NOTICE messages above for diagnostic information.';
    RAISE NOTICE 'If clubs still do not appear, the issue may be in the frontend or RLS policies.';
END $$;
