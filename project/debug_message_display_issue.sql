-- =====================================================
-- DEBUG MESSAGE DISPLAY ISSUE
-- =====================================================
-- Check exactly what get_discussion_messages returns and format

-- Test 1: Check what our function actually returns
SELECT 
    'FUNCTION RETURN TEST' as test_name,
    get_discussion_messages(
        'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,
        (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1),
        10,
        0
    ) as raw_result;

-- Test 2: Check the JSON structure in detail
WITH function_result AS (
    SELECT get_discussion_messages(
        'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,
        (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1),
        10,
        0
    ) as result
)
SELECT 
    'JSON STRUCTURE TEST' as test_name,
    CASE 
        WHEN result IS NULL THEN 'NULL result'
        WHEN result::TEXT = '[]' THEN 'Empty array'
        WHEN result::TEXT = 'null' THEN 'null value'
        ELSE 'Has data: ' || LEFT(result::TEXT, 100) || '...'
    END as analysis,
    json_typeof(result) as json_type,
    CASE 
        WHEN json_typeof(result) = 'array' THEN json_array_length(result)
        ELSE NULL
    END as array_length
FROM function_result;

-- Test 3: Check if user is actually a participant
SELECT 
    'PARTICIPATION STATUS' as test_name,
    CASE 
        WHEN dp.user_id IS NOT NULL THEN 'User IS participant'
        ELSE 'User is NOT participant'
    END as status,
    d.title as discussion_title
FROM discussions d
LEFT JOIN discussion_participants dp ON d.id = dp.discussion_id
LEFT JOIN users u ON dp.user_id = u.id AND u.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID
WHERE d.id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1);

-- Test 4: Check discussion_messages table structure first
SELECT 
    'DISCUSSION_MESSAGES COLUMNS' as test_name,
    string_agg(column_name, ', ' ORDER BY ordinal_position) as columns
FROM information_schema.columns 
WHERE table_name = 'discussion_messages' 
AND table_schema = 'public';

-- Test 5: Check actual messages in database with proper formatting
SELECT 
    'DATABASE MESSAGES' as test_name,
    json_agg(
        json_build_object(
            'id', dm.id::TEXT,
            'content', dm.content,
            'createdAt', dm.created_at::TEXT,
            'userId', dm.user_id::TEXT,
            'userName', COALESCE(u.name, u.username, 'Unknown'),
            'userImageUrl', NULL,
            'isEdited', false
        )
        ORDER BY dm.created_at ASC
    ) as expected_format
FROM discussion_messages dm
JOIN users u ON dm.user_id = u.id
WHERE dm.discussion_id = (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1);

-- Test 6: Compare with book club message format
SELECT 
    'BOOK CLUB MESSAGE FORMAT' as test_name,
    json_agg(
        json_build_object(
            'id', bcm.id::TEXT,
            'content', bcm.content,
            'createdAt', bcm.created_at::TEXT,
            'userId', bcm.user_id::TEXT,
            'userName', COALESCE(u.name, u.username, 'Unknown'),
            'userImageUrl', NULL
        )
        ORDER BY bcm.created_at ASC
    ) as book_club_format
FROM book_club_messages bcm
JOIN users u ON bcm.user_id = u.id
WHERE bcm.club_id = (SELECT id FROM book_clubs ORDER BY created_at DESC LIMIT 1)
LIMIT 3;
