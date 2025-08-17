-- Final Fix for Tailor Mates Functions
-- Run this in your Supabase SQL Editor to completely fix the function issues

-- Step 1: Check current function status
SELECT 'Current functions:' as status;
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('get_book_clubs', 'get_discussions', 'get_friend_connections')
ORDER BY routine_name;

-- Step 2: Drop all existing functions to start fresh
DROP FUNCTION IF EXISTS get_book_clubs(TEXT);
DROP FUNCTION IF EXISTS get_discussions(TEXT);
DROP FUNCTION IF EXISTS get_friend_connections(TEXT);
DROP FUNCTION IF EXISTS create_book_club(TEXT, TEXT, TEXT, TEXT, TEXT, INTEGER, TEXT[], TEXT, DATE, BOOLEAN, TEXT[], TEXT);
DROP FUNCTION IF EXISTS create_discussion(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT[], TEXT);
DROP FUNCTION IF EXISTS send_friend_request(TEXT, TEXT);

-- Step 3: Create simplified, working functions
-- Function 1: Get Book Clubs
CREATE OR REPLACE FUNCTION get_book_clubs(user_clerk_id TEXT)
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    current_book_title TEXT,
    current_book_author TEXT,
    member_count INTEGER,
    max_members INTEGER,
    personality_traits TEXT[],
    meeting_time TEXT,
    next_meeting_date DATE,
    is_private BOOLEAN,
    tags TEXT[],
    created_by UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    is_member BOOLEAN,
    user_role TEXT,
    creator_name TEXT
) AS $$
DECLARE
    user_uuid UUID;
BEGIN
    -- Get user UUID
    SELECT id INTO user_uuid FROM users WHERE clerk_id = user_clerk_id;
    
    -- If user not found, return empty result instead of throwing error
    IF user_uuid IS NULL THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT 
        bc.id,
        bc.name,
        bc.description,
        bc.current_book_title,
        bc.current_book_author,
        bc.member_count,
        bc.max_members,
        bc.personality_traits,
        bc.meeting_time,
        bc.next_meeting_date,
        bc.is_private,
        bc.tags,
        bc.created_by,
        bc.created_at,
        COALESCE(cm.user_id IS NOT NULL, false) as is_member,
        COALESCE(cm.role, '') as user_role,
        COALESCE(u.name, 'Unknown') as creator_name
    FROM book_clubs bc
    LEFT JOIN club_memberships cm ON bc.id = cm.club_id AND cm.user_id = user_uuid
    LEFT JOIN users u ON bc.created_by = u.id
    ORDER BY bc.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function 2: Get Discussions
CREATE OR REPLACE FUNCTION get_discussions(user_clerk_id TEXT)
RETURNS TABLE (
    id UUID,
    title TEXT,
    content TEXT,
    book_title TEXT,
    book_author TEXT,
    tags TEXT[],
    creator_id UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    is_participant BOOLEAN,
    participant_count INTEGER,
    last_activity TIMESTAMP WITH TIME ZONE,
    creator_name TEXT
) AS $$
DECLARE
    user_uuid UUID;
BEGIN
    -- Get user UUID
    SELECT id INTO user_uuid FROM users WHERE clerk_id = user_clerk_id;
    
    -- If user not found, return empty result instead of throwing error
    IF user_uuid IS NULL THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT 
        d.id,
        d.title,
        d.content,
        d.book_title,
        d.book_author,
        d.tags,
        d.creator_id,
        d.created_at,
        d.updated_at,
        COALESCE(dp.user_id IS NOT NULL, false) as is_participant,
        COALESCE(participant_counts.count, 0) as participant_count,
        COALESCE(d.updated_at, d.created_at) as last_activity,
        COALESCE(u.name, 'Unknown') as creator_name
    FROM discussions d
    LEFT JOIN discussion_participants dp ON d.id = dp.discussion_id AND dp.user_id = user_uuid
    LEFT JOIN users u ON d.creator_id = u.id
    LEFT JOIN (
        SELECT discussion_id, COUNT(*) as count 
        FROM discussion_participants 
        GROUP BY discussion_id
    ) participant_counts ON d.id = participant_counts.discussion_id
    ORDER BY d.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function 3: Get Friend Connections
CREATE OR REPLACE FUNCTION get_friend_connections(user_clerk_id TEXT)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    friend_id UUID,
    status TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    friend_name TEXT,
    friend_username TEXT,
    personality_match_score DECIMAL
) AS $$
DECLARE
    user_uuid UUID;
BEGIN
    -- Get user UUID
    SELECT id INTO user_uuid FROM users WHERE clerk_id = user_clerk_id;
    
    -- If user not found, return empty result instead of throwing error
    IF user_uuid IS NULL THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT 
        fc.id,
        fc.user_id,
        fc.friend_id,
        fc.status,
        fc.created_at,
        COALESCE(u.name, 'Unknown') as friend_name,
        COALESCE(u.username, '') as friend_username,
        COALESCE(fc.personality_match_score, 0.0) as personality_match_score
    FROM friend_connections fc
    JOIN users u ON fc.friend_id = u.id
    WHERE fc.user_id = user_uuid
    ORDER BY fc.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function 4: Create Book Club
CREATE OR REPLACE FUNCTION create_book_club(
    user_clerk_id TEXT,
    club_name TEXT,
    description TEXT,
    current_book_title TEXT,
    current_book_author TEXT,
    max_members INTEGER,
    personality_traits TEXT[],
    meeting_time TEXT,
    next_meeting_date DATE,
    is_private BOOLEAN,
    tags TEXT[]
)
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
    club_id UUID;
BEGIN
    -- Get user UUID
    SELECT id INTO user_uuid FROM users WHERE clerk_id = user_clerk_id;
    
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'User not found in database. Please try logging out and back in to sync your account.';
    END IF;

    -- Create the book club
    INSERT INTO book_clubs (
        name, description, current_book_title, current_book_author,
        max_members, personality_traits, meeting_time, next_meeting_date,
        is_private, tags, created_by, member_count
    ) VALUES (
        club_name, description, current_book_title, current_book_author,
        max_members, personality_traits, meeting_time, next_meeting_date,
        is_private, tags, user_uuid, 1
    ) RETURNING id INTO club_id;

    -- Add creator as admin member
    INSERT INTO club_memberships (club_id, user_id, role, joined_at)
    VALUES (club_id, user_uuid, 'admin', NOW());

    RETURN club_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function 5: Create Discussion
CREATE OR REPLACE FUNCTION create_discussion(
    user_clerk_id TEXT,
    title TEXT,
    content TEXT,
    book_title TEXT,
    book_author TEXT,
    tags TEXT[]
)
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
    discussion_id UUID;
BEGIN
    -- Get user UUID
    SELECT id INTO user_uuid FROM users WHERE clerk_id = user_clerk_id;
    
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'User not found in database. Please try logging out and back in to sync your account.';
    END IF;

    -- Create the discussion
    INSERT INTO discussions (
        title, content, book_title, book_author, tags, creator_id
    ) VALUES (
        title, content, book_title, book_author, tags, user_uuid
    ) RETURNING id INTO discussion_id;

    -- Add creator as participant
    INSERT INTO discussion_participants (discussion_id, user_id, joined_at)
    VALUES (discussion_id, user_uuid, NOW());

    RETURN discussion_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function 6: Send Friend Request
CREATE OR REPLACE FUNCTION send_friend_request(
    user_clerk_id TEXT,
    friend_username TEXT
)
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
    friend_uuid UUID;
    request_id UUID;
BEGIN
    -- Get user UUID
    SELECT id INTO user_uuid FROM users WHERE clerk_id = user_clerk_id;
    
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'User not found in database. Please try logging out and back in to sync your account.';
    END IF;

    -- Get friend UUID by username
    SELECT id INTO friend_uuid FROM users WHERE username = friend_username;
    
    IF friend_uuid IS NULL THEN
        RAISE EXCEPTION 'User with username % not found.', friend_username;
    END IF;

    IF user_uuid = friend_uuid THEN
        RAISE EXCEPTION 'You cannot send a friend request to yourself.';
    END IF;

    -- Check if request already exists
    IF EXISTS (
        SELECT 1 FROM friend_connections 
        WHERE (user_id = user_uuid AND friend_id = friend_uuid) 
        OR (user_id = friend_uuid AND friend_id = user_uuid)
    ) THEN
        RAISE EXCEPTION 'Friend request or connection already exists.';
    END IF;

    -- Create friend request
    INSERT INTO friend_connections (user_id, friend_id, status)
    VALUES (user_uuid, friend_uuid, 'pending')
    RETURNING id INTO request_id;

    RETURN request_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 4: Verify functions were created
SELECT 'Functions created successfully!' as status;
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('get_book_clubs', 'get_discussions', 'get_friend_connections', 'create_book_club', 'create_discussion', 'send_friend_request')
ORDER BY routine_name;

-- Step 5: Test with a sample user (if any exist)
SELECT 'Testing functions with existing users...' as status;
SELECT clerk_id, name FROM users LIMIT 1;

