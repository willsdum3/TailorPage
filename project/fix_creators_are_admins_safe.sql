-- Safely ensure club creators are automatically added as admins
-- This script handles null creator_id values and invalid references

-- First, let's check the current state
DO $$
DECLARE
    club_count INTEGER;
    valid_creator_count INTEGER;
    null_creator_count INTEGER;
    invalid_creator_count INTEGER;
    creator_member_count INTEGER;
    admin_member_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO club_count FROM book_clubs;
    SELECT COUNT(*) INTO valid_creator_count FROM book_clubs bc
    JOIN users u ON bc.creator_id = u.id;
    SELECT COUNT(*) INTO null_creator_count FROM book_clubs WHERE creator_id IS NULL;
    SELECT COUNT(*) INTO invalid_creator_count FROM book_clubs bc
    LEFT JOIN users u ON bc.creator_id = u.id
    WHERE bc.creator_id IS NOT NULL AND u.id IS NULL;
    SELECT COUNT(*) INTO creator_member_count FROM book_clubs bc
    JOIN book_club_members bcm ON bc.id = bcm.club_id AND bc.creator_id = bcm.user_id;
    SELECT COUNT(*) INTO admin_member_count FROM book_club_members WHERE role = 'admin';
    
    RAISE NOTICE 'Current state:';
    RAISE NOTICE 'Total clubs: %', club_count;
    RAISE NOTICE 'Clubs with valid creators: %', valid_creator_count;
    RAISE NOTICE 'Clubs with null creators: %', null_creator_count;
    RAISE NOTICE 'Clubs with invalid creators: %', invalid_creator_count;
    RAISE NOTICE 'Clubs where creator is a member: %', creator_member_count;
    RAISE NOTICE 'Total admin members: %', admin_member_count;
END $$;

-- Only add club creators as admin members if they have valid creator_id values
INSERT INTO book_club_members (club_id, user_id, role, joined_at)
SELECT 
    bc.id as club_id,
    bc.creator_id as user_id,
    'admin' as role,
    bc.created_at as joined_at
FROM book_clubs bc
JOIN users u ON bc.creator_id = u.id  -- Only join with valid users
WHERE NOT EXISTS (
    SELECT 1 FROM book_club_members bcm
    WHERE bcm.club_id = bc.id 
    AND bcm.user_id = bc.creator_id
);

-- Update existing creator members to have admin role (only for valid creators)
UPDATE book_club_members 
SET role = 'admin'
WHERE user_id IN (
    SELECT bc.creator_id 
    FROM book_clubs bc 
    JOIN users u ON bc.creator_id = u.id  -- Only update for valid creators
    WHERE bc.creator_id = book_club_members.user_id
    AND bc.id = book_club_members.club_id
)
AND role != 'admin';

-- Check the updated state
DO $$
DECLARE
    club_count INTEGER;
    valid_creator_count INTEGER;
    null_creator_count INTEGER;
    invalid_creator_count INTEGER;
    creator_member_count INTEGER;
    admin_member_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO club_count FROM book_clubs;
    SELECT COUNT(*) INTO valid_creator_count FROM book_clubs bc
    JOIN users u ON bc.creator_id = u.id;
    SELECT COUNT(*) INTO null_creator_count FROM book_clubs WHERE creator_id IS NULL;
    SELECT COUNT(*) INTO invalid_creator_count FROM book_clubs bc
    LEFT JOIN users u ON bc.creator_id = u.id
    WHERE bc.creator_id IS NOT NULL AND u.id IS NULL;
    SELECT COUNT(*) INTO creator_member_count FROM book_clubs bc
    JOIN book_club_members bcm ON bc.id = bcm.club_id AND bc.creator_id = bcm.user_id;
    SELECT COUNT(*) INTO admin_member_count FROM book_club_members WHERE role = 'admin';
    
    RAISE NOTICE 'Updated state:';
    RAISE NOTICE 'Total clubs: %', club_count;
    RAISE NOTICE 'Clubs with valid creators: %', valid_creator_count;
    RAISE NOTICE 'Clubs with null creators: %', null_creator_count;
    RAISE NOTICE 'Clubs with invalid creators: %', invalid_creator_count;
    RAISE NOTICE 'Clubs where creator is a member: %', creator_member_count;
    RAISE NOTICE 'Total admin members: %', admin_member_count;
END $$;

-- Create a safer trigger that only adds creators as admin members if they have valid creator_id
CREATE OR REPLACE FUNCTION add_creator_as_admin_safe()
RETURNS TRIGGER AS $$
BEGIN
    -- Only add the creator as an admin member if creator_id is not null and exists in users table
    IF NEW.creator_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM users u WHERE u.id = NEW.creator_id
    ) THEN
        INSERT INTO book_club_members (club_id, user_id, role, joined_at)
        VALUES (NEW.id, NEW.creator_id, 'admin', NEW.created_at);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_add_creator_as_admin ON book_clubs;
DROP TRIGGER IF EXISTS trigger_add_creator_as_admin_safe ON book_clubs;

-- Create the safer trigger
CREATE TRIGGER trigger_add_creator_as_admin_safe
    AFTER INSERT ON book_clubs
    FOR EACH ROW
    EXECUTE FUNCTION add_creator_as_admin_safe();

-- Test the trigger by checking if it exists
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_add_creator_as_admin_safe';

-- Show any clubs that still have invalid creator_id values
SELECT 
    'clubs_with_invalid_creators' as check_type,
    bc.id as club_id,
    bc.name as club_name,
    bc.creator_id,
    bc.created_at
FROM book_clubs bc
LEFT JOIN users u ON bc.creator_id = u.id
WHERE bc.creator_id IS NOT NULL AND u.id IS NULL
ORDER BY bc.created_at;














