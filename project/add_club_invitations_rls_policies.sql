-- Add proper RLS policies to club_invitations table
-- Run this AFTER the table is created and you've confirmed the users table structure

-- First, remove the temporary policy
DROP POLICY IF EXISTS "Allow all operations temporarily" ON club_invitations;

-- Check if users table exists and has the expected structure
DO $$
BEGIN
    -- Only create policies if users table exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
        
        -- Create proper RLS policies
        DROP POLICY IF EXISTS "Users can view their own invitations" ON club_invitations;
        CREATE POLICY "Users can view their own invitations" ON club_invitations
            FOR SELECT USING (invited_user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

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
                invited_by_user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid())
                AND EXISTS (
                    SELECT 1 FROM book_club_members bcm
                    WHERE bcm.club_id = club_invitations.club_id
                    AND bcm.user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid())
                    AND bcm.role = 'admin'
                )
            );

        DROP POLICY IF EXISTS "Users can update their own invitations" ON club_invitations;
        CREATE POLICY "Users can update their own invitations" ON club_invitations
            FOR UPDATE USING (invited_user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));
            
        RAISE NOTICE 'RLS policies created successfully for club_invitations table';
    ELSE
        RAISE NOTICE 'Users table does not exist. RLS policies not created.';
    END IF;
END $$;





















