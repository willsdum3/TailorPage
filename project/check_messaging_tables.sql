-- Check if the friend_messages table exists and has the correct structure

-- Check if friend_messages table exists
SELECT 
    'TABLE EXISTS CHECK' as info,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'friend_messages';

-- Check the structure of friend_messages table
SELECT 
    'TABLE STRUCTURE' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'friend_messages'
ORDER BY ordinal_position;

-- Check if there are any existing messages
SELECT 
    'EXISTING MESSAGES' as info,
    COUNT(*) as message_count
FROM friend_messages;

-- Check RLS policies on friend_messages
SELECT 
    'RLS POLICIES' as info,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'friend_messages';

-- Check if the table has proper indexes
SELECT 
    'INDEXES' as info,
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'friend_messages';
