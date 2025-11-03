-- Fix RLS Policies to Allow Data Display
-- This script updates the RLS policies to allow SELECT operations needed for data display

-- ===========================================
-- FIX BOOK_CLUBS TABLE POLICIES
-- ===========================================

-- Drop all existing policies on book_clubs
DROP POLICY IF EXISTS "Users can view all book clubs" ON book_clubs;
DROP POLICY IF EXISTS "Users can create book clubs" ON book_clubs;
DROP POLICY IF EXISTS "Club creators can update their clubs" ON book_clubs;
DROP POLICY IF EXISTS "Club creators can delete their clubs" ON book_clubs;
DROP POLICY IF EXISTS "Users can update book clubs" ON book_clubs;
DROP POLICY IF EXISTS "Users can delete book clubs" ON book_clubs;

-- Create new policies that allow data to be displayed
CREATE POLICY "Users can view all book clubs" ON book_clubs
    FOR SELECT USING (true);

CREATE POLICY "Users can create book clubs" ON book_clubs
    FOR INSERT WITH CHECK (creator_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Club creators can update their clubs" ON book_clubs
    FOR UPDATE USING (creator_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Club creators can delete their clubs" ON book_clubs
    FOR DELETE USING (creator_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

-- ===========================================
-- FIX DISCUSSIONS TABLE POLICIES
-- ===========================================

-- Drop all existing policies on discussions
DROP POLICY IF EXISTS "Users can view all discussions" ON discussions;
DROP POLICY IF EXISTS "Users can create discussions" ON discussions;
DROP POLICY IF EXISTS "Discussion creators can update their discussions" ON discussions;
DROP POLICY IF EXISTS "Users can update discussions" ON discussions;

-- Create new policies that allow data to be displayed
CREATE POLICY "Users can view all discussions" ON discussions
    FOR SELECT USING (true);

CREATE POLICY "Users can create discussions" ON discussions
    FOR INSERT WITH CHECK (created_by = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Discussion creators can update their discussions" ON discussions
    FOR UPDATE USING (created_by = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

-- ===========================================
-- FIX BOOK_CLUB_MEMBERS TABLE POLICIES
-- ===========================================

-- Drop all existing policies on book_club_members
DROP POLICY IF EXISTS "Users can view club memberships" ON book_club_members;
DROP POLICY IF EXISTS "Users can join clubs" ON book_club_members;
DROP POLICY IF EXISTS "Users can leave clubs" ON book_club_members;
DROP POLICY IF EXISTS "Club admins can manage memberships" ON book_club_members;

-- Create new policies
CREATE POLICY "Users can view club memberships" ON book_club_members
    FOR SELECT USING (true);

CREATE POLICY "Users can join clubs" ON book_club_members
    FOR INSERT WITH CHECK (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can leave clubs" ON book_club_members
    FOR DELETE USING (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

-- ===========================================
-- FIX DISCUSSION_MEMBERS TABLE POLICIES
-- ===========================================

-- Drop all existing policies on discussion_members
DROP POLICY IF EXISTS "Users can view discussion memberships" ON discussion_members;
DROP POLICY IF EXISTS "Users can join discussions" ON discussion_members;
DROP POLICY IF EXISTS "Users can leave discussions" ON discussion_members;

-- Create new policies
CREATE POLICY "Users can view discussion memberships" ON discussion_members
    FOR SELECT USING (true);

CREATE POLICY "Users can join discussions" ON discussion_members
    FOR INSERT WITH CHECK (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can leave discussions" ON discussion_members
    FOR DELETE USING (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

-- ===========================================
-- FIX BOOK_CLUB_MESSAGES TABLE POLICIES
-- ===========================================

-- Drop all existing policies on book_club_messages
DROP POLICY IF EXISTS "Club members can view messages" ON book_club_messages;
DROP POLICY IF EXISTS "Club members can send messages" ON book_club_messages;
DROP POLICY IF EXISTS "Users can delete their own messages" ON book_club_messages;

-- Create new policies that allow viewing
CREATE POLICY "Club members can view messages" ON book_club_messages
    FOR SELECT USING (true);

CREATE POLICY "Club members can send messages" ON book_club_messages
    FOR INSERT WITH CHECK (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can delete their own messages" ON book_club_messages
    FOR DELETE USING (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

-- ===========================================
-- FIX DISCUSSION_MESSAGES TABLE POLICIES
-- ===========================================

-- Drop all existing policies on discussion_messages
DROP POLICY IF EXISTS "Discussion members can view messages" ON discussion_messages;
DROP POLICY IF EXISTS "Discussion members can send messages" ON discussion_messages;
DROP POLICY IF EXISTS "Users can delete their own discussion messages" ON discussion_messages;

-- Create new policies that allow viewing
CREATE POLICY "Discussion members can view messages" ON discussion_messages
    FOR SELECT USING (true);

CREATE POLICY "Discussion members can send messages" ON discussion_messages
    FOR INSERT WITH CHECK (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can delete their own discussion messages" ON discussion_messages
    FOR DELETE USING (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

-- ===========================================
-- VERIFICATION
-- ===========================================

SELECT 
    'RLS Policies Fixed' as status,
    'All SELECT policies now allow public access for data display' as message;

-- Show all RLS policies
SELECT 
    'RLS Policies' as check_type,
    schemaname,
    tablename,
    policyname,
    permissive,
    cmd
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename IN ('book_clubs', 'discussions', 'book_club_members', 'discussion_members', 'book_club_messages', 'discussion_messages')
ORDER BY tablename, policyname;
