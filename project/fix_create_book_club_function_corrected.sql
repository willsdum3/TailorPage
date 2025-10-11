-- Fix the create_book_club function with correct parameter names matching the frontend
-- The frontend sends: auth_user_id, club_name, club_description, current_book_title, current_book_author, max_members, is_public, target_personality_traits, tags, meeting_info

-- Drop the existing function first
DROP FUNCTION IF EXISTS create_book_club(UUID, TEXT, TEXT, TEXT, TEXT, INTEGER, BOOLEAN, TEXT[], TEXT[], TEXT);

-- Create the function with parameter names that match the frontend
CREATE OR REPLACE FUNCTION create_book_club(
    auth_user_id UUID,
    club_name TEXT,
    club_description TEXT,
    current_book_title TEXT DEFAULT NULL,
    current_book_author TEXT DEFAULT NULL,
    max_members INTEGER DEFAULT 20,
    is_public BOOLEAN DEFAULT TRUE,
    target_personality_traits TEXT[] DEFAULT '{}',
    tags TEXT[] DEFAULT '{}',
    meeting_info TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    new_club_id UUID;
    user_internal_id UUID;
BEGIN
    -- Get the internal user ID from auth_user_id
    SELECT id INTO user_internal_id
    FROM users
    WHERE users.auth_user_id = create_book_club.auth_user_id;
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Create the book club
    INSERT INTO book_clubs (
        name,
        description,
        current_book_title,
        current_book_author,
        max_members,
        is_public,
        target_personality_traits,
        tags,
        meeting_info,
        created_by
    ) VALUES (
        club_name,
        club_description,
        current_book_title,
        current_book_author,
        max_members,
        is_public,
        target_personality_traits,
        tags,
        meeting_info,
        user_internal_id
    ) RETURNING id INTO new_club_id;
    
    -- Add the creator as an admin member
    INSERT INTO book_club_members (
        club_id,
        user_id,
        role,
        joined_at
    ) VALUES (
        new_club_id,
        user_internal_id,
        'admin',
        NOW()
    );
    
    RETURN new_club_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the function with sample data using the correct parameter names
SELECT 
    'Test create_book_club Function with Correct Parameters' as check_type,
    create_book_club(
        'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,  -- William Dumbili's auth_user_id
        'Test Club Corrected',
        'A test book club with correct parameters',
        'Test Book',
        'Test Author',
        10,
        TRUE,
        ARRAY['Openness', 'Conscientiousness'],
        ARRAY['Fiction', 'Fantasy'],
        'Weekly meetings'
    ) as new_club_id;

-- Verify the test club was created
SELECT 
    'Verify Test Club Creation' as check_type,
    bc.id,
    bc.name,
    bc.description,
    bc.created_by,
    u.username as creator_username,
    u.name as creator_name
FROM book_clubs bc
JOIN users u ON bc.created_by = u.id
WHERE bc.name = 'Test Club Corrected'
ORDER BY bc.created_at DESC
LIMIT 1;

-- Check if the creator was added as admin member
SELECT 
    'Verify Creator as Admin' as check_type,
    bcm.club_id,
    bcm.user_id,
    bcm.role,
    u.username,
    u.name,
    bc.name as club_name
FROM book_club_members bcm
JOIN users u ON bcm.user_id = u.id
JOIN book_clubs bc ON bcm.club_id = bc.id
WHERE bc.name = 'Test Club Corrected'
ORDER BY bcm.joined_at DESC
LIMIT 1;

-- Clean up the test club
DELETE FROM book_club_members WHERE club_id IN (SELECT id FROM book_clubs WHERE name = 'Test Club Corrected');
DELETE FROM book_clubs WHERE name = 'Test Club Corrected';








