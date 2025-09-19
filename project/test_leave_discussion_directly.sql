-- =====================================================
-- TEST LEAVE DISCUSSION DIRECTLY
-- =====================================================
-- Direct test of leave_discussion function

-- Test the function directly and show detailed results
SELECT 
    'LEAVE FUNCTION TEST' as test_name,
    leave_discussion(
        'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,
        (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1)
    ) as leave_result;

-- Check if the function actually exists with correct signature
SELECT 
    'FUNCTION EXISTS CHECK' as test_name,
    r.routine_name,
    string_agg(p.parameter_name || ' ' || p.data_type, ', ' ORDER BY p.ordinal_position) as parameters
FROM information_schema.routines r
LEFT JOIN information_schema.parameters p ON r.specific_name = p.specific_name 
    AND p.parameter_mode = 'IN'
WHERE r.routine_schema = 'public' 
AND r.routine_name = 'leave_discussion'
AND r.routine_type = 'FUNCTION'
GROUP BY r.routine_name, r.specific_name;
