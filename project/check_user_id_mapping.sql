-- Check user ID mapping to understand the issue
-- The console shows user found with ID: ca692e7f-6522-4295-86cd-592d7fd754b5
-- But we're trying to remove friend with ID: 6a551bb7-3323-42ce-971d-ec4f0f4a6f69

-- Check William Dumbili's user record
SELECT 
    id,
    auth_user_id,
    name,
    username
FROM users 
WHERE name = 'William Dumbili' OR username = 'hereistand';

-- Check Kat Slater's user record  
SELECT 
    id,
    auth_user_id,
    name,
    username
FROM users 
WHERE name = 'Kat Slater' OR username = 'katslater';

-- Check the friendship between them
SELECT 
    fr.id,
    fr.requester_id,
    fr.target_id,
    u1.name as requester_name,
    u2.name as target_name,
    fr.status
FROM friend_requests fr
JOIN users u1 ON fr.requester_id = u1.id
JOIN users u2 ON fr.target_id = u2.id
WHERE ((u1.name = 'William Dumbili' AND u2.name = 'Kat Slater') OR 
       (u1.name = 'Kat Slater' AND u2.name = 'William Dumbili'))
AND fr.status = 'accepted';
