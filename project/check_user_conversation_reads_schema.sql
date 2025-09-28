-- Check the schema of user_conversation_reads table
SELECT 
    'user_conversation_reads Schema' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_conversation_reads' 
AND table_schema = 'public'
ORDER BY ordinal_position;
