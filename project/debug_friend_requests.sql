-- Debug script to check friend requests data
-- Run this to see what's in the friend_connections table

-- 1. Check all friend connections
SELECT 
    'All Friend Connections' as check_type,
    fc.id,
    fc.user_id as requester_internal_id,
    fc.friend_id as recipient_internal_id,
    fc.status,
    fc.created_at,
    requester.name as requester_name,
    requester.username as requester_username,
    requester.auth_user_id as requester_auth_id,
    recipient.name as recipient_name,
    recipient.username as recipient_username,
    recipient.auth_user_id as recipient_auth_id
FROM friend_connections fc
LEFT JOIN users requester ON fc.user_id = requester.id
LEFT JOIN users recipient ON fc.friend_id = recipient.id
ORDER BY fc.created_at DESC;

-- 2. Check pending friend connections
SELECT 
    'Pending Friend Connections' as check_type,
    fc.id,
    fc.user_id as requester_internal_id,
    fc.friend_id as recipient_internal_id,
    fc.status,
    fc.created_at,
    requester.name as requester_name,
    requester.username as requester_username,
    requester.auth_user_id as requester_auth_id,
    recipient.name as recipient_name,
    recipient.username as recipient_username,
    recipient.auth_user_id as recipient_auth_id
FROM friend_connections fc
LEFT JOIN users requester ON fc.user_id = requester.id
LEFT JOIN users recipient ON fc.friend_id = recipient.id
WHERE fc.status = 'pending'
ORDER BY fc.created_at DESC;

-- 3. Check for a specific user (replace with your auth_user_id)
-- Replace 'ee11bb62-0684-4293-a77a-d385c9a070f9' with the actual auth_user_id
SELECT 
    'Pending Requests for Specific User' as check_type,
    fc.id,
    fc.user_id as requester_internal_id,
    fc.friend_id as recipient_internal_id,
    fc.status,
    fc.created_at,
    requester.name as requester_name,
    requester.username as requester_username,
    requester.auth_user_id as requester_auth_id,
    recipient.name as recipient_name,
    recipient.username as recipient_username,
    recipient.auth_user_id as recipient_auth_id,
    get_user_internal_id('ee11bb62-0684-4293-a77a-d385c9a070f9') as current_user_internal_id
FROM friend_connections fc
LEFT JOIN users requester ON fc.user_id = requester.id
LEFT JOIN users recipient ON fc.friend_id = recipient.id
WHERE fc.status = 'pending'
  AND fc.friend_id = get_user_internal_id('ee11bb62-0684-4293-a77a-d385c9a070f9')
ORDER BY fc.created_at DESC;

-- 4. Test the get_friend_requests function directly
SELECT 
    'Function Test' as check_type,
    *
FROM get_friend_requests('ee11bb62-0684-4293-a77a-d385c9a070f9');

-- 5. Check if get_user_internal_id is working
SELECT 
    'User Internal ID Check' as check_type,
    'ee11bb62-0684-4293-a77a-d385c9a070f9' as auth_user_id,
    get_user_internal_id('ee11bb62-0684-4293-a77a-d385c9a070f9') as internal_id,
    u.id as direct_lookup_id,
    u.name,
    u.username
FROM users u
WHERE u.auth_user_id = 'ee11bb62-0684-4293-a77a-d385c9a070f9';

