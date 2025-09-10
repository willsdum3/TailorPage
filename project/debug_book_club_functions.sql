-- Debug script to check if the book club functions exist and their signatures
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
