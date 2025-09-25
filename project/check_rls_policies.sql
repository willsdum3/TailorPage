-- Check RLS policies that might affect the remove_friend_by_internal_id function
-- This will help us understand if RLS is causing the function to fail

-- Check if RLS is enabled on relevant tables
SELECT 
    'RLS Status' as check_type,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename IN ('users', 'friend_requests', 'friend_conversations', 'friend_messages')
ORDER BY tablename;

-- Check RLS policies on users table
SELECT 
    'Users RLS Policies' as check_type,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'users'
ORDER BY policyname;

-- Check RLS policies on friend_requests table
SELECT 
    'Friend Requests RLS Policies' as check_type,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'friend_requests'
ORDER BY policyname;

-- Check RLS policies on friend_conversations table
SELECT 
    'Friend Conversations RLS Policies' as check_type,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'friend_conversations'
ORDER BY policyname;

-- Check RLS policies on friend_messages table
SELECT 
    'Friend Messages RLS Policies' as check_type,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'friend_messages'
ORDER BY policyname;
