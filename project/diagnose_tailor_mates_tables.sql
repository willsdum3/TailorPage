-- =====================================================
-- DIAGNOSE TAILOR MATES TABLES
-- =====================================================
-- This script helps diagnose issues with Tailor Mates table creation

-- Check if book_clubs table exists and its structure
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'book_clubs' 
ORDER BY ordinal_position;

-- Check if all Tailor Mates tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN (
    'book_clubs', 
    'club_memberships', 
    'discussions', 
    'discussion_messages', 
    'discussion_participants', 
    'friend_connections', 
    'friend_recommendations'
  )
ORDER BY table_name;

-- Check for any errors in the last few operations
SELECT * FROM pg_stat_activity WHERE state = 'active';

-- Check if users table exists (required for foreign keys)
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name = 'users';
