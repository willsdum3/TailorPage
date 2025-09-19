-- =====================================================
-- TEST FUNCTION DIRECTLY
-- =====================================================
-- Direct test of the get_discussion_messages function

-- First, ensure user is joined to the latest discussion
DO $$
DECLARE
    test_auth_id UUID := 'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID;
    user_uuid UUID;
    discussion_uuid UUID;
BEGIN
    -- Get user ID
    SELECT u.id INTO user_uuid FROM users u WHERE u.auth_user_id = test_auth_id;
    
    -- Get latest discussion ID
    SELECT id INTO discussion_uuid FROM discussions ORDER BY created_at DESC LIMIT 1;
    
    -- Force join user to discussion
    IF user_uuid IS NOT NULL AND discussion_uuid IS NOT NULL THEN
        INSERT INTO discussion_participants (discussion_id, user_id, joined_at)
        VALUES (discussion_uuid, user_uuid, NOW())
        ON CONFLICT (discussion_id, user_id) DO NOTHING;
        
        RAISE NOTICE 'User % joined to discussion %', user_uuid, discussion_uuid;
    END IF;
END $$;

-- Now test the function
SELECT 
    'DIRECT FUNCTION TEST' as test_name,
    get_discussion_messages(
        'ee11bb62-0684-4293-a77a-d385c9a070f9'::UUID,
        (SELECT id FROM discussions ORDER BY created_at DESC LIMIT 1),
        10,
        0
    ) as function_result;
