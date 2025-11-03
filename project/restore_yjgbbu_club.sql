-- Restore the yjgbbu club that was accidentally deleted during testing

-- Check if the club still exists
SELECT 
    'Check if yjgbbu exists' as check_type,
    COUNT(*) as count
FROM book_clubs
WHERE name = 'yjgbbu';

-- Recreate the yjgbbu club if it was deleted
DO $$
DECLARE
    tracey_user_id UUID;
    new_club_id UUID;
BEGIN
    -- Get Tracey Beaker's internal user ID (she was the admin)
    SELECT id INTO tracey_user_id
    FROM users
    WHERE username = 'vaseline22';
    
    IF tracey_user_id IS NULL THEN
        RAISE NOTICE 'Tracey Beaker not found, cannot recreate club';
        RETURN;
    END IF;
    
    -- Check if the club already exists
    IF NOT EXISTS (SELECT 1 FROM book_clubs WHERE name = 'yjgbbu') THEN
        -- Recreate the book club
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
            created_by,
            created_at
        ) VALUES (
            'yjgbbu',
            '














