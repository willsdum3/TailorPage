-- Enable RLS and add policies to club_invitations table
-- Run this AFTER the table is created successfully

-- First, check if the table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'club_invitations' AND table_schema = 'public') THEN
        RAISE NOTICE 'club_invitations table exists - proceeding with RLS setup';
    ELSE
        RAISE NOTICE 'club_invitations table does not exist - cannot enable RLS';
        RETURN;
    END IF;
END $$;

-- Enable RLS
ALTER TABLE club_invitations ENABLE ROW LEVEL SECURITY;

-- Check if public.users table exists before creating policies
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') THEN
        RAISE NOTICE 'public.users table exists - creating RLS policies';
        
        -- Create RLS policies
        DROP POLICY IF EXISTS "Users can view their own invitations" ON club_invitations;
        CREATE POLICY "Users can view their own invitations" ON club_invitations
            FOR SELECT USING (invited_user_id = (SELECT id FROM public.users WHERE auth_user_id = auth.uid()));

        DROP POLICY IF EXISTS "Club admins can view club invitations" ON club_invitations;
        CREATE POLICY "Club admins can view club invitations" ON club_invitations
            FOR SELECT USING (
                EXISTS (
                    SELECT 1 FROM book_club_members bcm
                    WHERE bcm.club_id = club_invitations.club_id
                    AND bcm.user_id = (SELECT id FROM public.users WHERE auth_user_id = auth.uid())
                    AND bcm.role = 'admin'
                )
            );

        DROP POLICY IF EXISTS "Club admins can create invitations" ON club_invitations;
        CREATE POLICY "Club admins can create invitations" ON club_invitations
            FOR INSERT WITH CHECK (
                invited_by_user_id = (SELECT id FROM public.users WHERE auth_user_id = auth.uid())
                AND EXISTS (
                    SELECT 1 FROM book_club_members bcm
                    WHERE bcm.club_id = club_invitations.club_id
                    AND bcm.user_id = (SELECT id FROM public.users WHERE auth_user_id = auth.uid())
                    AND bcm.role = 'admin'
                )
            );

        DROP POLICY IF EXISTS "Users can update their own invitations" ON club_invitations;
        CREATE POLICY "Users can update their own invitations" ON club_invitations
            FOR UPDATE USING (invited_user_id = (SELECT id FROM public.users WHERE auth_user_id = auth.uid()));
            
        RAISE NOTICE 'RLS policies created successfully for club_invitations table';
    ELSE
        RAISE NOTICE 'public.users table does not exist - creating permissive policy';
        
        -- Create a permissive policy if users table doesn't exist
        DROP POLICY IF EXISTS "Allow all operations temporarily" ON club_invitations;
        CREATE POLICY "Allow all operations temporarily" ON club_invitations
            FOR ALL USING (true) WITH CHECK (true);
            
        RAISE NOTICE 'Temporary permissive policy created';
    END IF;
END $$;

-- Verify RLS is enabled
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'club_invitations' AND schemaname = 'public';
