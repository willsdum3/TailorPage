-- Simple test to verify remove_friend function works
-- This will test the function with a non-existent user (should return "User not found")

SELECT remove_friend(
    '00000000-0000-0000-0000-000000000000'::uuid, 
    '00000000-0000-0000-0000-000000000000'::uuid
) as test_result;

-- Expected result: {"success": false, "error": "User not found"}
