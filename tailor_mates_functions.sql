-- Tailor Mates Supabase Functions
-- Functions for book clubs, discussions, and friend matching

-- Drop existing functions if they exist
DROP FUNCTION IF EXISTS create_book_club(TEXT, TEXT, TEXT, TEXT, TEXT, INTEGER, TEXT[], TEXT, DATE, BOOLEAN, TEXT[]);
DROP FUNCTION IF EXISTS get_book_clubs(TEXT);
DROP FUNCTION IF EXISTS join_book_club(TEXT, UUID);
DROP FUNCTION IF EXISTS leave_book_club(TEXT, UUID);
DROP FUNCTION IF EXISTS create_discussion(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT[]);
DROP FUNCTION IF EXISTS get_discussions(TEXT);
DROP FUNCTION IF EXISTS join_discussion(TEXT, UUID);
DROP FUNCTION IF EXISTS leave_discussion(TEXT, UUID);
DROP FUNCTION IF EXISTS add_discussion_message(TEXT, UUID, TEXT);
DROP FUNCTION IF EXISTS get_discussion_messages(UUID);
DROP FUNCTION IF EXISTS send_friend_request(TEXT, TEXT);
DROP FUNCTION IF EXISTS accept_friend_request(TEXT, TEXT);
DROP FUNCTION IF EXISTS reject_friend_request(TEXT, TEXT);
DROP FUNCTION IF EXISTS get_friend_connections(TEXT);
DROP FUNCTION IF EXISTS get_friend_recommendations(TEXT);
DROP FUNCTION IF EXISTS generate_friend_recommendations(TEXT);
DROP FUNCTION IF EXISTS calculate_personality_match(UUID, UUID);

-- Function to create a new book club
CREATE OR REPLACE FUNCTION create_book_club(
    user_clerk_id TEXT,
    club_name TEXT,
    club_description TEXT,
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
    club_uuid UUID;
BEGIN
    -- Get user UUID
    SELECT id INTO user_uuid FROM users WHERE clerk_id = user_clerk_id;
    
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;

    -- Create the book club
    INSERT INTO book_clubs (
        name, description, current_book_title, current_book_author,
        max_members, personality_traits, meeting_time, next_meeting_date,
        is_private, tags, created_by
    ) VALUES (
        club_name, club_description, current_book_title, current_book_author,
        max_members, personality_traits, meeting_time, next_meeting_date,
        is_private, tags, user_uuid
    ) RETURNING id INTO club_uuid;

    -- Add creator as admin member
    INSERT INTO club_memberships (club_id, user_id, role) 
    VALUES (club_uuid, user_uuid, 'admin');

    -- Update member count
    UPDATE book_clubs SET member_count = 1 WHERE id = club_uuid;

    RETURN club_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get book clubs (with membership status for current user)
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
        COALESCE(cm.id IS NOT NULL, FALSE) as is_member,
        COALESCE(cm.role, 'none') as user_role,
        u.name as creator_name
    FROM book_clubs bc
    LEFT JOIN club_memberships cm ON bc.id = cm.club_id AND cm.user_id = user_uuid
    LEFT JOIN users u ON bc.created_by = u.id
    WHERE bc.is_private = FALSE OR cm.id IS NOT NULL
    ORDER BY bc.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to join a book club
CREATE OR REPLACE FUNCTION join_book_club(user_clerk_id TEXT, club_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
    current_members INTEGER;
    max_members INTEGER;
BEGIN
    -- Get user UUID
    SELECT id INTO user_uuid FROM users WHERE clerk_id = user_clerk_id;
    
    IF user_uuid IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Check if club exists and has space
    SELECT member_count, max_members INTO current_members, max_members 
    FROM book_clubs WHERE id = club_id;
    
    IF current_members >= max_members THEN
        RETURN FALSE;
    END IF;

    -- Add membership (ignore if already exists)
    INSERT INTO club_memberships (club_id, user_id) 
    VALUES (club_id, user_uuid)
    ON CONFLICT (club_id, user_id) DO NOTHING;

    -- Update member count
    UPDATE book_clubs 
    SET member_count = (SELECT COUNT(*) FROM club_memberships WHERE club_id = club_id AND is_active = TRUE)
    WHERE id = club_id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to leave a book club
CREATE OR REPLACE FUNCTION leave_book_club(user_clerk_id TEXT, club_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
BEGIN
    -- Get user UUID
    SELECT id INTO user_uuid FROM users WHERE clerk_id = user_clerk_id;
    
    IF user_uuid IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Remove membership
    DELETE FROM club_memberships WHERE club_id = club_id AND user_id = user_uuid;

    -- Update member count
    UPDATE book_clubs 
    SET member_count = (SELECT COUNT(*) FROM club_memberships WHERE club_id = club_id AND is_active = TRUE)
    WHERE id = club_id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create a new discussion
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
    discussion_uuid UUID;
BEGIN
    -- Get user UUID
    SELECT id INTO user_uuid FROM users WHERE clerk_id = user_clerk_id;
    
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;

    -- Create the discussion
    INSERT INTO discussions (
        title, content, book_title, book_author, tags, created_by
    ) VALUES (
        title, content, book_title, book_author, tags, user_uuid
    ) RETURNING id INTO discussion_uuid;

    -- Add creator as participant
    INSERT INTO discussion_participants (discussion_id, user_id) 
    VALUES (discussion_uuid, user_uuid);

    -- Update participant count
    UPDATE discussions SET participant_count = 1 WHERE id = discussion_uuid;

    RETURN discussion_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get discussions
CREATE OR REPLACE FUNCTION get_discussions(user_clerk_id TEXT)
RETURNS TABLE (
    id UUID,
    title TEXT,
    content TEXT,
    book_title TEXT,
    book_author TEXT,
    tags TEXT[],
    created_by UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    participant_count INTEGER,
    last_activity TIMESTAMP WITH TIME ZONE,
    is_participant BOOLEAN,
    creator_name TEXT
) AS $$
DECLARE
    user_uuid UUID;
BEGIN
    -- Get user UUID
    SELECT id INTO user_uuid FROM users WHERE clerk_id = user_clerk_id;
    
    RETURN QUERY
    SELECT 
        d.id,
        d.title,
        d.content,
        d.book_title,
        d.book_author,
        d.tags,
        d.created_by,
        d.created_at,
        d.participant_count,
        d.last_activity,
        COALESCE(dp.id IS NOT NULL, FALSE) as is_participant,
        u.name as creator_name
    FROM discussions d
    LEFT JOIN discussion_participants dp ON d.id = dp.discussion_id AND dp.user_id = user_uuid
    LEFT JOIN users u ON d.created_by = u.id
    WHERE d.is_active = TRUE
    ORDER BY d.last_activity DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to join a discussion
CREATE OR REPLACE FUNCTION join_discussion(user_clerk_id TEXT, discussion_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
BEGIN
    -- Get user UUID
    SELECT id INTO user_uuid FROM users WHERE clerk_id = user_clerk_id;
    
    IF user_uuid IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Add participant (ignore if already exists)
    INSERT INTO discussion_participants (discussion_id, user_id) 
    VALUES (discussion_id, user_uuid)
    ON CONFLICT (discussion_id, user_id) DO NOTHING;

    -- Update participant count
    UPDATE discussions 
    SET participant_count = (SELECT COUNT(*) FROM discussion_participants WHERE discussion_id = discussion_id),
        last_activity = NOW()
    WHERE id = discussion_id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to add a message to a discussion
CREATE OR REPLACE FUNCTION add_discussion_message(
    user_clerk_id TEXT,
    discussion_id UUID,
    message_content TEXT
)
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
    message_uuid UUID;
BEGIN
    -- Get user UUID
    SELECT id INTO user_uuid FROM users WHERE clerk_id = user_clerk_id;
    
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;

    -- Add message
    INSERT INTO discussion_messages (discussion_id, user_id, content) 
    VALUES (discussion_id, user_uuid, message_content)
    RETURNING id INTO message_uuid;

    -- Update discussion last activity
    UPDATE discussions 
    SET last_activity = NOW()
    WHERE id = discussion_id;

    -- Update participant's last read time
    UPDATE discussion_participants 
    SET last_read_at = NOW()
    WHERE discussion_id = discussion_id AND user_id = user_uuid;

    RETURN message_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get discussion messages
CREATE OR REPLACE FUNCTION get_discussion_messages(discussion_id UUID)
RETURNS TABLE (
    id UUID,
    content TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    user_id UUID,
    user_name TEXT,
    user_image_url TEXT,
    is_edited BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dm.id,
        dm.content,
        dm.created_at,
        dm.user_id,
        u.name,
        u.image_url,
        dm.is_edited
    FROM discussion_messages dm
    JOIN users u ON dm.user_id = u.id
    WHERE dm.discussion_id = discussion_id
    ORDER BY dm.created_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate personality match score between two users
CREATE OR REPLACE FUNCTION calculate_personality_match(user1_id UUID, user2_id UUID)
RETURNS DECIMAL(3,2) AS $$
DECLARE
    profile1 RECORD;
    profile2 RECORD;
    total_diff DECIMAL(10,2) := 0;
    trait_count INTEGER := 0;
    match_score DECIMAL(3,2);
BEGIN
    -- Get personality profiles
    SELECT * INTO profile1 FROM user_personality_profiles WHERE user_id = user1_id;
    SELECT * INTO profile2 FROM user_personality_profiles WHERE user_id = user2_id;
    
    IF profile1 IS NULL OR profile2 IS NULL THEN
        RETURN 0.0;
    END IF;

    -- Calculate differences for each trait (normalized to 0-1 scale)
    total_diff := total_diff + ABS(profile1.openness - profile2.openness) / 20.0;
    total_diff := total_diff + ABS(profile1.conscientiousness - profile2.conscientiousness) / 20.0;
    total_diff := total_diff + ABS(profile1.extraversion - profile2.extraversion) / 20.0;
    total_diff := total_diff + ABS(profile1.agreeableness - profile2.agreeableness) / 20.0;
    total_diff := total_diff + ABS(profile1.emotional_stability - profile2.emotional_stability) / 20.0;
    total_diff := total_diff + ABS(profile1.rational_thinking - profile2.rational_thinking) / 20.0;
    total_diff := total_diff + ABS(profile1.core_values - profile2.core_values) / 20.0;
    total_diff := total_diff + ABS(profile1.lifestyle - profile2.lifestyle) / 20.0;
    total_diff := total_diff + ABS(profile1.social_style - profile2.social_style) / 20.0;
    total_diff := total_diff + ABS(profile1.self_expression - profile2.self_expression) / 20.0;
    
    trait_count := 10;

    -- Convert to similarity score (0-1, where 1 is perfect match)
    match_score := 1.0 - (total_diff / trait_count);
    
    RETURN GREATEST(0.0, LEAST(1.0, match_score));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to send a friend request
CREATE OR REPLACE FUNCTION send_friend_request(user_clerk_id TEXT, friend_clerk_id TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
    friend_uuid UUID;
    match_score DECIMAL(3,2);
BEGIN
    -- Get user UUIDs
    SELECT id INTO user_uuid FROM users WHERE clerk_id = user_clerk_id;
    SELECT id INTO friend_uuid FROM users WHERE clerk_id = friend_clerk_id;
    
    IF user_uuid IS NULL OR friend_uuid IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Calculate personality match score
    match_score := calculate_personality_match(user_uuid, friend_uuid);

    -- Create friend connection
    INSERT INTO friend_connections (user_id, friend_id, personality_match_score) 
    VALUES (user_uuid, friend_uuid, match_score)
    ON CONFLICT (user_id, friend_id) DO NOTHING;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to accept a friend request
CREATE OR REPLACE FUNCTION accept_friend_request(user_clerk_id TEXT, friend_clerk_id TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
    friend_uuid UUID;
BEGIN
    -- Get user UUIDs
    SELECT id INTO user_uuid FROM users WHERE clerk_id = user_clerk_id;
    SELECT id INTO friend_uuid FROM users WHERE clerk_id = friend_clerk_id;
    
    IF user_uuid IS NULL OR friend_uuid IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Update friend connection status
    UPDATE friend_connections 
    SET status = 'accepted', updated_at = NOW()
    WHERE (user_id = friend_uuid AND friend_id = user_uuid) 
       OR (user_id = user_uuid AND friend_id = friend_uuid);

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get friend connections
CREATE OR REPLACE FUNCTION get_friend_connections(user_clerk_id TEXT)
RETURNS TABLE (
    id UUID,
    friend_id UUID,
    friend_name TEXT,
    friend_username TEXT,
    friend_image_url TEXT,
    status TEXT,
    personality_match_score DECIMAL(3,2),
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    user_uuid UUID;
BEGIN
    -- Get user UUID
    SELECT id INTO user_uuid FROM users WHERE clerk_id = user_clerk_id;
    
    RETURN QUERY
    SELECT 
        fc.id,
        CASE 
            WHEN fc.user_id = user_uuid THEN fc.friend_id
            ELSE fc.user_id
        END as friend_id,
        u.name as friend_name,
        u.username as friend_username,
        u.image_url as friend_image_url,
        fc.status,
        fc.personality_match_score,
        fc.created_at
    FROM friend_connections fc
    JOIN users u ON (fc.user_id = user_uuid AND u.id = fc.friend_id) 
                 OR (fc.friend_id = user_uuid AND u.id = fc.user_id)
    ORDER BY fc.updated_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to generate friend recommendations
CREATE OR REPLACE FUNCTION generate_friend_recommendations(user_clerk_id TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
    match_score DECIMAL(3,2);
    match_reasons TEXT[];
BEGIN
    -- Get user UUID
    SELECT id INTO user_uuid FROM users WHERE clerk_id = user_clerk_id;
    
    IF user_uuid IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Clear existing recommendations
    DELETE FROM friend_recommendations WHERE user_id = user_uuid;

    -- Generate new recommendations for users with personality profiles
    -- who are not already friends or have pending requests
    INSERT INTO friend_recommendations (user_id, recommended_user_id, match_score, match_reasons)
    SELECT 
        user_uuid,
        upp.user_id,
        calculate_personality_match(user_uuid, upp.user_id),
        ARRAY[
            CASE WHEN ABS(up1.openness - upp.openness) <= 2 THEN 'Similar openness to new experiences' END,
            CASE WHEN ABS(up1.extraversion - upp.extraversion) <= 2 THEN 'Similar social energy levels' END,
            CASE WHEN ABS(up1.agreeableness - upp.agreeableness) <= 2 THEN 'Similar interpersonal style' END,
            CASE WHEN ABS(up1.conscientiousness - upp.conscientiousness) <= 2 THEN 'Similar organizational preferences' END,
            CASE WHEN ABS(up1.emotional_stability - upp.emotional_stability) <= 2 THEN 'Similar emotional patterns' END
        ]
    FROM user_personality_profiles upp
    JOIN user_personality_profiles up1 ON up1.user_id = user_uuid
    WHERE upp.user_id != user_uuid
    AND NOT EXISTS (
        SELECT 1 FROM friend_connections fc 
        WHERE (fc.user_id = user_uuid AND fc.friend_id = upp.user_id)
           OR (fc.user_id = upp.user_id AND fc.friend_id = user_uuid)
    )
    AND calculate_personality_match(user_uuid, upp.user_id) >= 0.7
    ORDER BY calculate_personality_match(user_uuid, upp.user_id) DESC
    LIMIT 10;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get friend recommendations
CREATE OR REPLACE FUNCTION get_friend_recommendations(user_clerk_id TEXT)
RETURNS TABLE (
    id UUID,
    recommended_user_id UUID,
    recommended_user_name TEXT,
    recommended_user_username TEXT,
    recommended_user_image_url TEXT,
    match_score DECIMAL(3,2),
    match_reasons TEXT[],
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    user_uuid UUID;
BEGIN
    -- Get user UUID
    SELECT id INTO user_uuid FROM users WHERE clerk_id = user_clerk_id;
    
    RETURN QUERY
    SELECT 
        fr.id,
        fr.recommended_user_id,
        u.name as recommended_user_name,
        u.username as recommended_user_username,
        u.image_url as recommended_user_image_url,
        fr.match_score,
        fr.match_reasons,
        fr.created_at
    FROM friend_recommendations fr
    JOIN users u ON fr.recommended_user_id = u.id
    WHERE fr.user_id = user_uuid
    ORDER BY fr.match_score DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
