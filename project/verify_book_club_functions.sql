-- Verify that book club functions exist and check their signatures
SELECT 
    routine_name,
    routine_type,
    data_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_name IN (
    'get_book_club_details',
    'get_book_club_members', 
    'add_book_club_message',
    'get_book_club_messages'
)
AND routine_schema = 'public'
ORDER BY routine_name;

-- Also check if the book_club_messages table exists
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'book_club_messages'
AND table_schema = 'public'
ORDER BY ordinal_position;
