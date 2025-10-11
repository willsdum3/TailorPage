-- Check what tables exist in the database
-- This will help us understand the current database structure

-- List all tables in the public schema
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- Check if specific tables exist
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') 
        THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as users_table_status;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'book_clubs') 
        THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as book_clubs_table_status;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'book_club_members') 
        THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as book_club_members_table_status;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'club_invitations') 
        THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as club_invitations_table_status;



