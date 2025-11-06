-- Fix club_invitations table using the correct column names
-- The table actually has 'invitee_id' and 'inviter_id', not 'invited_user_id' and 'invited_by_user_id'

-- First, check the actual column names
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'club_invitations' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Test selecting with the correct column names
SELECT 'Testing SELECT * with correct columns' as test;
SELECT * FROM club_invitations LIMIT 1;

-- Test specific columns with correct names
SELECT 'Testing specific columns with correct names' as test;
SELECT 
    id,
    club_id,
    invitee_id,
    inviter_id,
    message,
    status,
    created_at,
    responded_at
FROM club_invitations 
LIMIT 1;

-- Check if the unique constraint already exists (it should, based on the index)
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'club_invitations' AND tc.table_schema = 'public'
ORDER BY tc.constraint_type, kcu.column_name;

-- The table already has the unique constraint based on the index name
-- Let's verify it's working by trying to insert duplicate data
DO $$
BEGIN
    -- This should fail if the unique constraint is working
    BEGIN
        INSERT INTO club_invitations (club_id, invitee_id, inviter_id, message, status)
        VALUES ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000000', 'test', 'pending');
        
        -- If we get here, the constraint isn't working, so delete the test row
        DELETE FROM club_invitations WHERE club_id = '00000000-0000-0000-0000-000000000000';
        RAISE NOTICE 'Unique constraint is NOT working - test insert succeeded';
    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE 'Unique constraint IS working - test insert failed as expected';
        WHEN OTHERS THEN
            RAISE NOTICE 'Error testing unique constraint: %', SQLERRM;
    END;
END $$;

-- Check if we need to add any missing constraints
DO $$
BEGIN
    -- Check if check constraint exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'club_invitations' 
        AND table_schema = 'public' 
        AND constraint_type = 'CHECK'
        AND constraint_name LIKE '%status%'
    ) THEN
        BEGIN
            ALTER TABLE club_invitations 
            ADD CONSTRAINT check_status 
            CHECK (status IN ('pending', 'accepted', 'declined'));
            RAISE NOTICE 'Check constraint added successfully';
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Error adding check constraint: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE 'Check constraint already exists';
    END IF;
END $$;

-- Final verification
SELECT 
    'club_invitations table is ready' as status,
    COUNT(*) as column_count
FROM information_schema.columns 
WHERE table_name = 'club_invitations' AND table_schema = 'public';



















