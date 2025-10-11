-- Add constraints to club_invitations table one by one
-- This will help us identify which constraint is causing the issue

-- First, verify the table exists and show its current structure
SELECT 
    'club_invitations table exists' as status,
    COUNT(*) as column_count
FROM information_schema.columns 
WHERE table_name = 'club_invitations' AND table_schema = 'public';

-- Show current table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'club_invitations' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Step 1: Try to add the check constraint
DO $$
BEGIN
    BEGIN
        ALTER TABLE club_invitations 
        ADD CONSTRAINT check_status 
        CHECK (status IN ('pending', 'accepted', 'declined'));
        RAISE NOTICE 'Check constraint added successfully';
    EXCEPTION
        WHEN duplicate_object THEN
            RAISE NOTICE 'Check constraint already exists';
        WHEN OTHERS THEN
            RAISE NOTICE 'Error adding check constraint: %', SQLERRM;
    END;
END $$;

-- Step 2: Try to add the unique constraint
DO $$
BEGIN
    BEGIN
        ALTER TABLE club_invitations 
        ADD CONSTRAINT unique_club_invitation 
        UNIQUE(club_id, invited_user_id);
        RAISE NOTICE 'Unique constraint added successfully';
    EXCEPTION
        WHEN duplicate_object THEN
            RAISE NOTICE 'Unique constraint already exists';
        WHEN OTHERS THEN
            RAISE NOTICE 'Error adding unique constraint: %', SQLERRM;
    END;
END $$;

-- Step 3: Try to add indexes one by one
DO $$
BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_club_invitations_club_id ON club_invitations(club_id);
        RAISE NOTICE 'Index on club_id added successfully';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Error adding index on club_id: %', SQLERRM;
    END;
END $$;

DO $$
BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_club_invitations_invited_user_id ON club_invitations(invited_user_id);
        RAISE NOTICE 'Index on invited_user_id added successfully';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Error adding index on invited_user_id: %', SQLERRM;
    END;
END $$;

DO $$
BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_club_invitations_status ON club_invitations(status);
        RAISE NOTICE 'Index on status added successfully';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Error adding index on status: %', SQLERRM;
    END;
END $$;

-- Show final table structure with constraints
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'club_invitations' AND tc.table_schema = 'public'
ORDER BY tc.constraint_type, kcu.column_name;








