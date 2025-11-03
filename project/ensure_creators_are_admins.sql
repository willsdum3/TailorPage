-- Ensure club creators are automatically added as admins
-- This script fixes the issue where club creators might not be recognized as admins

-- First, let's check the current state
DO $$
DECLARE
    club_count INTEGER;
    creator_member_count INTEGER;
    admin_member_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO club_count FROM book_clubs;
    SELECT COUNT(*) INTO creator_member_count FROM book_clubs bc
    JOIN book_club_members bcm ON bc.id = bcm.club_id AND bc.creator_id = bcm.user_id;
    SELECT COUNT(*) INTO admin_member_count FROM book_club_members WHERE role = 'admin';
    
    RAISE NOTICE 'Current state:';
    RAISE NOTICE 'Total clubs: %', club_count;
    RAISE NOTICE 'Clubs where creator is a member: %', creator_member_count;
    RAISE NOTICE 'Total admin members: %', admin_member_count;
END $$;

-- Add club creators as admin members if they're not already members
INSERT INTO book_club_members (club_id, user_id, role, joined_at)
SELECT 
    bc.id as club_id,
    bc.creator_id as user_id,
    'admin' as role,
    bc.created_at as joined_at
FROM book_clubs bc
WHERE NOT EXISTS (
    SELECT 1 FROM book_club_members bcm
    WHERE bcm.club_id = bc.id 
    AND bcm.user_id = bc.creator_id
);

-- Update existing creator members to have admin role
UPDATE book_club_members 
SET role = 'admin'
WHERE user_id IN (
    SELECT bc.creator_id 
    FROM book_clubs bc 
    WHERE bc.creator_id = book_club_members.user_id
    AND bc.id = book_club_members.club_id
)
AND role != 'admin';

-- Check the updated state
DO $$
DECLARE
    club_count INTEGER;
    creator_member_count INTEGER;
    admin_member_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO club_count FROM book_clubs;
    SELECT COUNT(*) INTO creator_member_count FROM book_clubs bc
    JOIN book_club_members bcm ON bc.id = bcm.club_id AND bc.creator_id = bcm.user_id;
    SELECT COUNT(*) INTO admin_member_count FROM book_club_members WHERE role = 'admin';
    
    RAISE NOTICE 'Updated state:';
    RAISE NOTICE 'Total clubs: %', club_count;
    RAISE NOTICE 'Clubs where creator is a member: %', creator_member_count;
    RAISE NOTICE 'Total admin members: %', admin_member_count;
END $$;

-- Create a trigger to automatically add creators as admin members when new clubs are created
CREATE OR REPLACE FUNCTION add_creator_as_admin()
RETURNS TRIGGER AS $$
BEGIN
    -- Add the creator as an admin member
    INSERT INTO book_club_members (club_id, user_id, role, joined_at)
    VALUES (NEW.id, NEW.creator_id, 'admin', NEW.created_at);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_add_creator_as_admin ON book_clubs;

-- Create the trigger
CREATE TRIGGER trigger_add_creator_as_admin
    AFTER INSERT ON book_clubs
    FOR EACH ROW
    EXECUTE FUNCTION add_creator_as_admin();

-- Test the trigger by checking if it exists
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_add_creator_as_admin';














