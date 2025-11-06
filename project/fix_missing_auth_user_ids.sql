-- Fix missing auth_user_id values for users
-- This script helps identify and fix users who don't have auth_user_id set

-- 1. Show all users without auth_user_id
SELECT 
    'USERS WITHOUT auth_user_id' as section,
    u.id as internal_id,
    u.username,
    u.name,
    u.email,
    u.created_at
FROM users u
WHERE u.auth_user_id IS NULL
ORDER BY u.created_at DESC;

-- 2. If you know the Supabase auth user IDs for these users, update them here
-- Replace the placeholders with actual values from Supabase Auth
-- 
-- Example:
-- UPDATE users 
-- SET auth_user_id = 'actual-supabase-auth-user-id-here'
-- WHERE id = 'bc0eb657-aaf9-483d-a988-c68f79b135f9'  -- user_8e84fd62
--   AND auth_user_id IS NULL;
--
-- UPDATE users 
-- SET auth_user_id = 'actual-supabase-auth-user-id-here'
-- WHERE id = '88b4421f-b441-40fe-8484-03596348fa90'  -- user_74194ae3
--   AND auth_user_id IS NULL;

-- 3. Alternative: Create a function to sync auth_user_id from Supabase Auth
-- This would require access to auth.users table which may not be available
-- But if you have access, you can use this pattern:
--
-- UPDATE users u
-- SET auth_user_id = au.id
-- FROM auth.users au
-- WHERE u.email = au.email
--   AND u.auth_user_id IS NULL;

-- 4. For now, show what needs to be done manually
SELECT 
    'MANUAL FIX REQUIRED' as section,
    u.id as internal_id,
    u.username,
    u.email,
    'Go to Supabase Auth > Users and find the user with email: ' || COALESCE(u.email, 'NO EMAIL') || 
    ' Then update this user record with: UPDATE users SET auth_user_id = ''<supabase-auth-id>'' WHERE id = ''' || u.id || ''';' as instruction
FROM users u
WHERE u.id IN (
    'bc0eb657-aaf9-483d-a988-c68f79b135f9',  -- user_8e84fd62
    '88b4421f-b441-40fe-8484-03596348fa90'   -- user_74194ae3
)
AND u.auth_user_id IS NULL;

