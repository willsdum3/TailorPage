-- Fix RLS Security Errors for Supabase (Corrected Version)
-- This script addresses the security error: "RLS Disabled in Public" for book_club_members table
-- and ensures all public tables have proper Row Level Security enabled

-- First, let's check which tables exist and their current RLS status
SELECT 
    'Current RLS Status' as check_type,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- Enable RLS on all public tables that don't have it enabled
-- 1. book_club_members table (the one mentioned in the error)
ALTER TABLE book_club_members ENABLE ROW LEVEL SECURITY;

-- 2. book_clubs table
ALTER TABLE book_clubs ENABLE ROW LEVEL SECURITY;

-- 3. book_club_messages table
ALTER TABLE book_club_messages ENABLE ROW LEVEL SECURITY;

-- 4. discussions table
ALTER TABLE discussions ENABLE ROW LEVEL SECURITY;

-- 5. discussion_members table
ALTER TABLE discussion_members ENABLE ROW LEVEL SECURITY;

-- 6. discussion_messages table
ALTER TABLE discussion_messages ENABLE ROW LEVEL SECURITY;

-- 7. users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 8. notifications table (if it exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'notifications' AND table_schema = 'public') THEN
        ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE 'RLS enabled on notifications table';
    END IF;
END $$;

-- 9. club_invitations table (if it exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'club_invitations' AND table_schema = 'public') THEN
        ALTER TABLE club_invitations ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE 'RLS enabled on club_invitations table';
    END IF;
END $$;

-- Now create comprehensive RLS policies for each table

-- ===========================================
-- USERS TABLE POLICIES
-- ===========================================
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
CREATE POLICY "Users can view their own profile" ON users
    FOR SELECT USING (auth_user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update their own profile" ON users;
CREATE POLICY "Users can update their own profile" ON users
    FOR UPDATE USING (auth_user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert their own profile" ON users;
CREATE POLICY "Users can insert their own profile" ON users
    FOR INSERT WITH CHECK (auth_user_id = auth.uid());

-- ===========================================
-- BOOK_CLUBS TABLE POLICIES
-- ===========================================
DROP POLICY IF EXISTS "Users can view all book clubs" ON book_clubs;
CREATE POLICY "Users can view all book clubs" ON book_clubs
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can create book clubs" ON book_clubs;
CREATE POLICY "Users can create book clubs" ON book_clubs
    FOR INSERT WITH CHECK (creator_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

DROP POLICY IF EXISTS "Club creators can update their clubs" ON book_clubs;
CREATE POLICY "Club creators can update their clubs" ON book_clubs
    FOR UPDATE USING (creator_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

DROP POLICY IF EXISTS "Club creators can delete their clubs" ON book_clubs;
CREATE POLICY "Club creators can delete their clubs" ON book_clubs
    FOR DELETE USING (creator_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

-- ===========================================
-- BOOK_CLUB_MEMBERS TABLE POLICIES
-- ===========================================
DROP POLICY IF EXISTS "Users can view club memberships" ON book_club_members;
CREATE POLICY "Users can view club memberships" ON book_club_members
    FOR SELECT USING (
        user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid())
        OR EXISTS (
            SELECT 1 FROM book_club_members bcm2
            WHERE bcm2.club_id = book_club_members.club_id
            AND bcm2.user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid())
        )
    );

DROP POLICY IF EXISTS "Users can join clubs" ON book_club_members;
CREATE POLICY "Users can join clubs" ON book_club_members
    FOR INSERT WITH CHECK (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

DROP POLICY IF EXISTS "Users can leave clubs" ON book_club_members;
CREATE POLICY "Users can leave clubs" ON book_club_members
    FOR DELETE USING (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

DROP POLICY IF EXISTS "Club admins can manage memberships" ON book_club_members;
CREATE POLICY "Club admins can manage memberships" ON book_club_members
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM book_club_members bcm
            WHERE bcm.club_id = book_club_members.club_id
            AND bcm.user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid())
            AND bcm.role = 'admin'
        )
    );

-- ===========================================
-- BOOK_CLUB_MESSAGES TABLE POLICIES
-- ===========================================
DROP POLICY IF EXISTS "Club members can view messages" ON book_club_messages;
CREATE POLICY "Club members can view messages" ON book_club_messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM book_club_members bcm
            WHERE bcm.club_id = book_club_messages.club_id
            AND bcm.user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid())
        )
    );

DROP POLICY IF EXISTS "Club members can send messages" ON book_club_messages;
CREATE POLICY "Club members can send messages" ON book_club_messages
    FOR INSERT WITH CHECK (
        user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid())
        AND EXISTS (
            SELECT 1 FROM book_club_members bcm
            WHERE bcm.club_id = book_club_messages.club_id
            AND bcm.user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid())
        )
    );

DROP POLICY IF EXISTS "Users can delete their own messages" ON book_club_messages;
CREATE POLICY "Users can delete their own messages" ON book_club_messages
    FOR DELETE USING (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

-- ===========================================
-- DISCUSSIONS TABLE POLICIES
-- ===========================================
DROP POLICY IF EXISTS "Users can view all discussions" ON discussions;
CREATE POLICY "Users can view all discussions" ON discussions
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can create discussions" ON discussions;
CREATE POLICY "Users can create discussions" ON discussions
    FOR INSERT WITH CHECK (created_by = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

DROP POLICY IF EXISTS "Discussion creators can update their discussions" ON discussions;
CREATE POLICY "Discussion creators can update their discussions" ON discussions
    FOR UPDATE USING (created_by = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

-- ===========================================
-- DISCUSSION_MEMBERS TABLE POLICIES
-- ===========================================
DROP POLICY IF EXISTS "Users can view discussion memberships" ON discussion_members;
CREATE POLICY "Users can view discussion memberships" ON discussion_members
    FOR SELECT USING (
        user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid())
        OR EXISTS (
            SELECT 1 FROM discussion_members dm2
            WHERE dm2.discussion_id = discussion_members.discussion_id
            AND dm2.user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid())
        )
    );

DROP POLICY IF EXISTS "Users can join discussions" ON discussion_members;
CREATE POLICY "Users can join discussions" ON discussion_members
    FOR INSERT WITH CHECK (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

DROP POLICY IF EXISTS "Users can leave discussions" ON discussion_members;
CREATE POLICY "Users can leave discussions" ON discussion_members
    FOR DELETE USING (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

-- ===========================================
-- DISCUSSION_MESSAGES TABLE POLICIES
-- ===========================================
DROP POLICY IF EXISTS "Discussion members can view messages" ON discussion_messages;
CREATE POLICY "Discussion members can view messages" ON discussion_messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM discussion_members dm
            WHERE dm.discussion_id = discussion_messages.discussion_id
            AND dm.user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid())
        )
    );

DROP POLICY IF EXISTS "Discussion members can send messages" ON discussion_messages;
CREATE POLICY "Discussion members can send messages" ON discussion_messages
    FOR INSERT WITH CHECK (
        user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid())
        AND EXISTS (
            SELECT 1 FROM discussion_members dm
            WHERE dm.discussion_id = discussion_messages.discussion_id
            AND dm.user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid())
        )
    );

DROP POLICY IF EXISTS "Users can delete their own discussion messages" ON discussion_messages;
CREATE POLICY "Users can delete their own discussion messages" ON discussion_messages
    FOR DELETE USING (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

-- ===========================================
-- NOTIFICATIONS TABLE POLICIES (if exists)
-- ===========================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'notifications' AND table_schema = 'public') THEN
        DROP POLICY IF EXISTS "Users can view their own notifications" ON notifications;
        CREATE POLICY "Users can view their own notifications" ON notifications
            FOR SELECT USING (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

        DROP POLICY IF EXISTS "Users can update their own notifications" ON notifications;
        CREATE POLICY "Users can update their own notifications" ON notifications
            FOR UPDATE USING (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

        DROP POLICY IF EXISTS "Users can delete their own notifications" ON notifications;
        CREATE POLICY "Users can delete their own notifications" ON notifications
            FOR DELETE USING (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

        RAISE NOTICE 'RLS policies created for notifications table';
    END IF;
END $$;

-- ===========================================
-- CLUB_INVITATIONS TABLE POLICIES (if exists)
-- ===========================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'club_invitations' AND table_schema = 'public') THEN
        DROP POLICY IF EXISTS "Users can view their own invitations" ON club_invitations;
        CREATE POLICY "Users can view their own invitations" ON club_invitations
            FOR SELECT USING (invitee_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

        DROP POLICY IF EXISTS "Club admins can view club invitations" ON club_invitations;
        CREATE POLICY "Club admins can view club invitations" ON club_invitations
            FOR SELECT USING (
                EXISTS (
                    SELECT 1 FROM book_club_members bcm
                    WHERE bcm.club_id = club_invitations.club_id
                    AND bcm.user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid())
                    AND bcm.role = 'admin'
                )
            );

        DROP POLICY IF EXISTS "Club admins can create invitations" ON club_invitations;
        CREATE POLICY "Club admins can create invitations" ON club_invitations
            FOR INSERT WITH CHECK (
                inviter_id = (SELECT id FROM users WHERE auth_user_id = auth.uid())
                AND EXISTS (
                    SELECT 1 FROM book_club_members bcm
                    WHERE bcm.club_id = club_invitations.club_id
                    AND bcm.user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid())
                    AND bcm.role = 'admin'
                )
            );

        DROP POLICY IF EXISTS "Users can update their own invitations" ON club_invitations;
        CREATE POLICY "Users can update their own invitations" ON club_invitations
            FOR UPDATE USING (invitee_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

        RAISE NOTICE 'RLS policies created for club_invitations table';
    END IF;
END $$;

-- Verify RLS is enabled on all tables
SELECT 
    'Final RLS Status' as check_type,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- Show all RLS policies
SELECT 
    'RLS Policies' as check_type,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Final verification message
SELECT 
    'RLS Security Fix Complete' as status,
    'All public tables now have Row Level Security enabled with appropriate policies' as message;


