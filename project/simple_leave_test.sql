-- =====================================================
-- SIMPLE LEAVE TEST
-- =====================================================
-- Test leave function with clear results

-- Test the leave function and catch any errors
DO $$
DECLARE
    william_auth_id UUID := 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID;
    test_discussion_id UUID;
    leave_result BOOLEAN;
    error_occurred BOOLEAN := false;
BEGIN
    -- Get discussion ID
    SELECT id INTO test_discussion_id FROM discussions ORDER BY created_at DESC LIMIT 1;
    
    RAISE NOTICE '=== TESTING LEAVE FUNCTION ===';
    RAISE NOTICE 'William auth_user_id: %', william_auth_id;
    RAISE NOTICE 'Discussion ID: %', test_discussion_id;
    
    -- Test the function and catch any errors
    BEGIN
        SELECT leave_discussion(william_auth_id, test_discussion_id) INTO leave_result;
        RAISE NOTICE 'Leave function returned: %', leave_result;
        
        IF leave_result = true THEN
            RAISE NOTICE '✅ SUCCESS: William can leave the discussion';
        ELSE
            RAISE NOTICE '❌ FAILED: Function returned false - checking why...';
            
            -- Check if William is actually the creator
            IF EXISTS(
                SELECT 1 FROM discussions d
                JOIN users u ON d.created_by = u.id
                WHERE d.id = test_discussion_id 
                AND u.auth_user_id = william_auth_id
            ) THEN
                RAISE NOTICE 'Reason: William IS the creator of this discussion';
            ELSE
                RAISE NOTICE 'Reason: Unknown - William is not creator but function still returned false';
            END IF;
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '❌ ERROR in leave_discussion function: %', SQLERRM;
            error_occurred := true;
    END;
    
    IF error_occurred THEN
        RAISE NOTICE '❌ Function call failed with error';
    END IF;
END $$;

-- Show this as a table result too
SELECT 
    'FUNCTION CALL RESULT' as test_type,
    CASE 
        WHEN leave_discussion(
            'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,
            (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)
        ) = true THEN 'SUCCESS - Can leave'
        ELSE 'FAILED - Cannot leave'
    END as result;
