-- Verify that the friend ID exists in the users table
-- The console shows friend ID: baf44ea3-ca65-43a7-8b16-18d16370b697

SELECT 
    id,
    auth_user_id,
    name,
    username,
    email
FROM users 
WHERE id = 'baf44ea3-ca65-43a7-8b16-18d16370b697';

-- Also check if this user has any friend relationships
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
WHERE fr.requester_id = 'baf44ea3-ca65-43a7-8b16-18d16370b697' 
   OR fr.target_id = 'baf44ea3-ca65-43a7-8b16-18d16370b697';
