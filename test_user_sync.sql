-- Test script to check if user exists in database
-- Replace 'your_clerk_user_id_here' with your actual Clerk user ID

-- Check if user exists
SELECT id, clerk_id, name, email, created_at 
FROM users 
WHERE clerk_id = 'your_clerk_user_id_here';

-- Check total users count
SELECT COUNT(*) as total_users FROM users;

-- Check recent users
SELECT clerk_id, name, email, created_at 
FROM users 
ORDER BY created_at DESC 
LIMIT 5;
