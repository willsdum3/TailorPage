-- Diagnostic script to check join request functionality

-- Check if club_join_requests table exists
SELECT 
    'Table Check' as check_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'club_join_requests') 
        THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as status;

-- Check if book_clubs has is_public column
SELECT 
    'Column Check' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'book_clubs' AND column_name = 'is_public'
        ) 
        THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as status;

-- Check if join request functions exist
SELECT 
    'Function Check' as check_type,
    routine_name,
    routine_type,
    CASE 
        WHEN routine_name IN ('request_to_join_club', 'get_club_join_requests', 'process_join_request') 
        THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as status
FROM information_schema.routines 
WHERE routine_name IN ('request_to_join_club', 'get_club_join_requests', 'process_join_request') 
AND routine_schema = 'public';

-- Check sample data
SELECT 
    'Sample Data' as check_type,
    COUNT(*) as club_count,
    COUNT(CASE WHEN is_public = FALSE THEN 1 END) as private_clubs
FROM book_clubs;

-- Test the request_to_join_club function if it exists
DO $$
DECLARE
    test_user_id UUID;
    test_club_id UUID;
    test_result RECORD;
BEGIN
    -- Get test data
    SELECT u.auth_user_id INTO test_user_id FROM users u LIMIT 1;
    SELECT bc.id INTO test_club_id FROM book_clubs bc WHERE bc.is_public = FALSE LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_club_id IS NOT NULL THEN
        RAISE NOTICE 'Testing request_to_join_club function...';
        RAISE NOTICE 'User: %, Club: %', test_user_id, test_club_id;
        
        -- Test the function
        BEGIN
            FOR test_result IN 
                SELECT * FROM request_to_join_club(test_user_id, test_club_id, 'Test join request')
            LOOP
                RAISE NOTICE 'Function result: success=%, message=%, requires_approval=%', 
                    test_result.success, test_result.message, test_result.requires_approval;
            END LOOP;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Function error: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE 'No test data available';
    END IF;
END $$;
