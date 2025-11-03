-- Check existing personality function
SELECT '=== CHECKING EXISTING PERSONALITY FUNCTION ===' as header;

-- Get the function definition
SELECT 
    routine_name,
    routine_definition
FROM information_schema.routines 
WHERE routine_name = 'get_user_personality_profile' 
AND routine_schema = 'public';

-- Check if user_personality_profiles table exists
SELECT 
    'user_personality_profiles' as table_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_personality_profiles' AND table_schema = 'public') 
        THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as status;

-- Check what columns exist in user_personality_profiles if it exists
SELECT 
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'user_personality_profiles' 
AND table_schema = 'public'
ORDER BY ordinal_position;
