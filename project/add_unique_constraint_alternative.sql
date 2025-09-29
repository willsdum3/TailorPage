-- Try to add unique constraint with alternative approaches
-- This will help us find a working solution for the unique constraint

-- First, check if the table has any data
SELECT COUNT(*) as row_count FROM club_invitations;

-- Check if there are any duplicate combinations of club_id and invited_user_id
SELECT 
    club_id, 
    invited_user_id, 
    COUNT(*) as duplicate_count
FROM club_invitations 
GROUP BY club_id, invited_user_id 
HAVING COUNT(*) > 1;

-- Try different approaches to add the unique constraint

-- Approach 1: Try to add unique constraint directly
DO $$
BEGIN
    BEGIN
        ALTER TABLE club_invitations 
        ADD CONSTRAINT unique_club_invitation 
        UNIQUE(club_id, invited_user_id);
        RAISE NOTICE 'Unique constraint added successfully with direct approach';
    EXCEPTION
        WHEN duplicate_object THEN
            RAISE NOTICE 'Unique constraint already exists';
        WHEN OTHERS THEN
            RAISE NOTICE 'Error with direct approach: %', SQLERRM;
    END;
END $$;

-- Approach 2: Try to add unique constraint with explicit column references
DO $$
BEGIN
    BEGIN
        ALTER TABLE club_invitations 
        ADD CONSTRAINT unique_club_invitation_alt 
        UNIQUE(club_invitations.club_id, club_invitations.invited_user_id);
        RAISE NOTICE 'Unique constraint added successfully with explicit references';
    EXCEPTION
        WHEN duplicate_object THEN
            RAISE NOTICE 'Unique constraint already exists';
        WHEN OTHERS THEN
            RAISE NOTICE 'Error with explicit references: %', SQLERRM;
    END;
END $$;

-- Approach 3: Try to create a unique index instead
DO $$
BEGIN
    BEGIN
        CREATE UNIQUE INDEX IF NOT EXISTS unique_club_invitation_idx 
        ON club_invitations(club_id, invited_user_id);
        RAISE NOTICE 'Unique index created successfully';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Error creating unique index: %', SQLERRM;
    END;
END $$;

-- Show current constraints and indexes
SELECT 
    'Constraints:' as type,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'club_invitations' AND tc.table_schema = 'public'

UNION ALL

SELECT 
    'Indexes:' as type,
    indexname as constraint_name,
    'INDEX' as constraint_type,
    '' as column_name
FROM pg_indexes 
WHERE tablename = 'club_invitations' AND schemaname = 'public'

ORDER BY type, constraint_name;
