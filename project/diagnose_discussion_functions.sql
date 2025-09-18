-- =====================================================
-- DIAGNOSE DISCUSSION FUNCTIONS ISSUES
-- =====================================================
-- This script will identify and fix discussion function problems

-- Check what discussion functions actually exist
SELECT 
    'Discussion Functions' as info,
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_name ILIKE '%discussion%'
AND routine_schema = 'public'
ORDER BY routine_name;

-- Check if discussion tables exist
SELECT 
    'Discussion Tables' as info,
    table_name
FROM information_schema.tables 
WHERE table_name ILIKE '%discussion%'
AND table_schema = 'public'
ORDER BY table_name;

-- Check discussion table structure
SELECT 
    'Discussions Table Structure' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'discussions'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check discussion_messages table structure
SELECT 
    'Discussion Messages Table Structure' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'discussion_messages'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check discussion_participants table structure
SELECT 
    'Discussion Participants Table Structure' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'discussion_participants'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Test if we can query the tables directly
SELECT 'Current Discussions Count' as info, COUNT(*) as count FROM discussions;
SELECT 'Current Messages Count' as info, COUNT(*) as count FROM discussion_messages;
SELECT 'Current Participants Count' as info, COUNT(*) as count FROM discussion_participants;

-- Show sample data if any exists
SELECT 
    'Sample Discussions' as info,
    id,
    title,
    created_by,
    created_at
FROM discussions 
LIMIT 5;

-- Check if helper functions exist
DO $$
BEGIN
    -- Test if get_user_id_from_auth function exists
    BEGIN
        PERFORM get_user_id_from_auth('00000000-0000-0000-0000-000000000000'::UUID);
        RAISE NOTICE '✅ get_user_id_from_auth function exists';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '❌ get_user_id_from_auth function missing or broken: %', SQLERRM;
    END;
END $$;
