-- Test remove_friend function
-- First, let's see what friends exist
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
WHERE fr.status = 'accepted'
LIMIT 5;

-- Test the function (replace with actual user IDs from above)
-- SELECT remove_friend('user_id_here', 'friend_id_here');
