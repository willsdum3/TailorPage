-- Debug script to check the club_memberships table structure
-- This will help us understand what columns exist

-- Check the structure of club_memberships table
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'club_memberships' 
ORDER BY ordinal_position;

-- Check if club_memberships table exists and has data
SELECT COUNT(*) as total_memberships FROM club_memberships;

-- Show sample data from club_memberships
SELECT * FROM club_memberships LIMIT 5;
