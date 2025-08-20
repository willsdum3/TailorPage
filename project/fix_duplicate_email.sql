-- Fix duplicate email issue
-- This script handles the case where an email exists but with a different clerk_id

-- Step 1: Check for duplicate emails
SELECT email, COUNT(*) as count, array_agg(clerk_id) as clerk_ids
FROM users 
GROUP BY email 
HAVING COUNT(*) > 1;

-- Step 2: Show all users with the problematic email
SELECT id, clerk_id, name, email, created_at, updated_at
FROM users 
WHERE email = 'williamdumbili3@gmail.com'
ORDER BY created_at;

-- Step 3: Option A: Remove the older duplicate (uncomment if you want to delete)
-- DELETE FROM users 
-- WHERE email = 'williamdumbili3@gmail.com' 
-- AND id NOT IN (
--   SELECT MAX(id) 
--   FROM users 
--   WHERE email = 'williamdumbili3@gmail.com'
-- );

-- Step 3: Option B: Update the email to make it unique (safer option)
-- UPDATE users 
-- SET email = email || '_old_' || id
-- WHERE email = 'williamdumbili3@gmail.com' 
-- AND id NOT IN (
--   SELECT MAX(id) 
--   FROM users 
--   WHERE email = 'williamdumbili3@gmail.com'
-- );

-- Step 4: Verify the fix
SELECT email, COUNT(*) as count
FROM users 
GROUP BY email 
HAVING COUNT(*) > 1;

-- Step 5: Show final state
SELECT id, clerk_id, name, email, created_at
FROM users 
WHERE email LIKE '%williamdumbili3%'
ORDER BY created_at;
