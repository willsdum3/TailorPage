-- Add unique constraint using exact column names from the table
-- This will use the exact column names as they exist in the table

-- First, get the exact column names from the table
DO $$
DECLARE
    column_names TEXT;
    sql_command TEXT;
BEGIN
    -- Get the column names for club_id and invited_user_id
    SELECT string_agg(column_name, ', ' ORDER BY ordinal_position)
    INTO column_names
    FROM information_schema.columns 
    WHERE table_name = 'club_invitations' 
    AND table_schema = 'public'
    AND column_name IN ('club_id', 'invited_user_id');
    
    RAISE NOTICE 'Found columns: %', column_names;
    
    -- Try to add unique constraint using the exact column names
    IF column_names IS NOT NULL THEN
        sql_command := 'ALTER TABLE club_invitations ADD CONSTRAINT unique_club_invitation UNIQUE(' || column_names || ')';
        RAISE NOTICE 'Executing: %', sql_command;
        
        BEGIN
            EXECUTE sql_command;
            RAISE NOTICE 'Unique constraint added successfully';
        EXCEPTION
            WHEN duplicate_object THEN
                RAISE NOTICE 'Unique constraint already exists';
            WHEN OTHERS THEN
                RAISE NOTICE 'Error adding unique constraint: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE 'Could not find the required columns';
    END IF;
END $$;

-- Alternative approach: Try to add unique constraint with explicit table reference
DO $$
BEGIN
    BEGIN
        ALTER TABLE public.club_invitations 
        ADD CONSTRAINT unique_club_invitation_public 
        UNIQUE(public.club_invitations.club_id, public.club_invitations.invited_user_id);
        RAISE NOTICE 'Unique constraint added successfully with explicit table reference';
    EXCEPTION
        WHEN duplicate_object THEN
            RAISE NOTICE 'Unique constraint already exists';
        WHEN OTHERS THEN
            RAISE NOTICE 'Error with explicit table reference: %', SQLERRM;
    END;
END $$;

-- Try to create a unique index instead
DO $$
BEGIN
    BEGIN
        CREATE UNIQUE INDEX IF NOT EXISTS unique_club_invitation_idx 
        ON public.club_invitations(club_id, invited_user_id);
        RAISE NOTICE 'Unique index created successfully';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Error creating unique index: %', SQLERRM;
    END;
END $$;

-- Show current constraints
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'club_invitations' AND tc.table_schema = 'public'
ORDER BY tc.constraint_type, kcu.column_name;




















