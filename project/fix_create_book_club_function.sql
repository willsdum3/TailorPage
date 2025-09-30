-- Fix the create_book_club function that's failing with "record new has no field user_role"
-- This addresses users not being able to create book clubs

-- First, let's check if the function exists and what it expects
SELECT 
    'Function Existence Check' as check_type,
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name = 'create_book_club';

-- Let's also check the function parameters
SELECT 
    'Function Parameters Check' as check_type,
    parameter_name,
    data_type,
    parameter_mode
FROM information_schema.parameters 
WHERE specific_schema = 'public'
AND specific_name IN (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_schema = 'public' 
    AND routine_name = 'create_book_club'
)
ORDER BY ordinal_position;

-- Drop the existing function first to avoid conflicts
DROP FUNCTION IF EXISTS create_book_club(UUID, TEXT, TEXT, TEXT, TEXT, INTEGER, BOOLEAN, TEXT[], TEXT[], TEXT);

-- Create the function with correct parameters (matching what the frontend sends)
CREATE OR REPLACE FUNCTION create_book_club(
    auth_user_id UUID,
    name_param TEXT,
    description_param TEXT,
    current_book_title_param TEXT DEFAULT NULL,
    current_book_author_param TEXT DEFAULT NULL,
    max_members_param INTEGER DEFAULT 20,
    is_public_param BOOLEAN DEFAULT TRUE,
    target_personality_traits_param TEXT[] DEFAULT '{}',
    tags_param TEXT[] DEFAULT '{}',
    meeting_info_param TEXT DEFAULT NULL
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
        name_param,
        description_param,
        current_book_title_param,
        current_book_author_param,
        max_members_param,
        is_public_param,
        target_personality_traits_param,
        tags_param,
        meeting_info_param,
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

-- Test the function with sample data
SELECT 
    'Test create_book_club Function' as check_type,
    create_book_club(
        'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,  -- William Dumbili's auth_user_id
        'Test Club',
        'A test book club',
        'Test Book',
        'Test Author',
        10,
        TRUE,
        ARRAY['Openness', 'Conscientiousness'],
        ARRAY['Fiction', 'Fantasy'],
        'Weekly meetings'
    ) as new_club_id;

-- Let's also check what the frontend is actually sending
-- The frontend calls: create_book_club(auth_user_id, name, description, currentBookTitle, currentBookAuthor, maxMembers, isPublic, targetPersonalityTraits, tags, meetingInfo)

-- Verify the function works by checking if the test club was created
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
WHERE bc.name = 'Test Club'
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
WHERE bc.name = 'Test Club'
ORDER BY bcm.joined_at DESC
LIMIT 1;

-- Clean up the test club
DELETE FROM book_club_members WHERE club_id IN (SELECT id FROM book_clubs WHERE name = 'Test Club');
DELETE FROM book_clubs WHERE name = 'Test Club';
