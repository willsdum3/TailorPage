-- Simple Data Check for Discussion Issues
-- This will definitely show us what's in the database

-- Check if users table exists and has data
SELECT 'Users Table Check' as check_type, COUNT(*) as user_count FROM users;

-- Check if discussions table exists and has data  
SELECT 'Discussions Table Check' as check_type, COUNT(*) as discussion_count FROM discussions;

-- Check if discussion_messages table exists and has data
SELECT 'Discussion Messages Table Check' as check_type, COUNT(*) as message_count FROM discussion_messages;

-- Check if discussion_members table exists and has data
SELECT 'Discussion Members Table Check' as check_type, COUNT(*) as member_count FROM discussion_members;

-- Show the structure of the users table
SELECT 'Users Table Structure' as check_type, column_name, data_type FROM information_schema.columns WHERE table_name = 'users' AND table_schema = 'public' ORDER BY ordinal_position;

-- Show the structure of the discussion_messages table
SELECT 'Discussion Messages Table Structure' as check_type, column_name, data_type FROM information_schema.columns WHERE table_name = 'discussion_messages' AND table_schema = 'public' ORDER BY ordinal_position;

-- Try to get one user record if any exist
SELECT 'First User Record' as check_type, id, name, username, avatar_url, email FROM users LIMIT 1;

-- Try to get one discussion message if any exist
SELECT 'First Discussion Message' as check_type, dm.id, dm.content, dm.message, dm.user_id, u.name, u.username, u.avatar_url 
FROM discussion_messages dm 
LEFT JOIN users u ON dm.user_id = u.id 
LIMIT 1;
