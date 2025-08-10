-- Tailor Mates Complete Setup Script
-- Run this in your Supabase SQL Editor to set up the entire Tailor Mates feature

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- TAILOR MATES DATABASE SCHEMA
-- ============================================================================

-- Book Clubs table
CREATE TABLE IF NOT EXISTS book_clubs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    current_book_title VARCHAR(500),
    current_book_author VARCHAR(255),
    member_count INTEGER DEFAULT 0,
    max_members INTEGER DEFAULT 20,
    personality_traits TEXT[], -- Array of personality traits the club targets
    meeting_time VARCHAR(100), -- e.g., "Every Tuesday 7 PM"
    next_meeting_date DATE,
    is_private BOOLEAN DEFAULT FALSE,
    tags TEXT[], -- Array of genre/topic tags
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_member_count CHECK (member_count >= 0 AND member_count <= max_members),
    CONSTRAINT valid_max_members CHECK (max_members > 0 AND max_members <= 100),
    CONSTRAINT valid_club_name CHECK (LENGTH(TRIM(name)) > 0)
);

-- Club Memberships table
CREATE TABLE IF NOT EXISTS club_memberships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    club_id UUID NOT NULL REFERENCES book_clubs(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) DEFAULT 'member' CHECK (role IN ('member', 'moderator', 'admin')),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(club_id, user_id)
);

-- Discussions table
CREATE TABLE IF NOT EXISTS discussions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(500) NOT NULL,
    content TEXT NOT NULL,
    book_title VARCHAR(500),
    book_author VARCHAR(255),
    tags TEXT[], -- Array of discussion tags
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    participant_count INTEGER DEFAULT 0,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_discussion_title CHECK (LENGTH(TRIM(title)) > 0)
);

-- Discussion Messages table
CREATE TABLE IF NOT EXISTS discussion_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    discussion_id UUID NOT NULL REFERENCES discussions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_edited BOOLEAN DEFAULT FALSE,
    CONSTRAINT valid_message_content CHECK (LENGTH(TRIM(content)) > 0)
);

-- Discussion Participants table
CREATE TABLE IF NOT EXISTS discussion_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    discussion_id UUID NOT NULL REFERENCES discussions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_read_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(discussion_id, user_id)
);

-- Friend Connections table
CREATE TABLE IF NOT EXISTS friend_connections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    friend_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
    personality_match_score DECIMAL(3,2) CHECK (personality_match_score >= 0 AND personality_match_score <= 1),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, friend_id),
    CONSTRAINT different_users CHECK (user_id != friend_id)
);

-- Friend Recommendations table (for suggesting potential friends)
CREATE TABLE IF NOT EXISTS friend_recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recommended_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    match_score DECIMAL(3,2) NOT NULL CHECK (match_score >= 0 AND match_score <= 1),
    match_reasons TEXT[], -- Array of reasons why they match
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_viewed BOOLEAN DEFAULT FALSE,
    UNIQUE(user_id, recommended_user_id),
    CONSTRAINT different_users CHECK (user_id != recommended_user_id)
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Book Clubs indexes
CREATE INDEX IF NOT EXISTS idx_book_clubs_created_by ON book_clubs(created_by);
CREATE INDEX IF NOT EXISTS idx_book_clubs_personality_traits ON book_clubs USING GIN(personality_traits);
CREATE INDEX IF NOT EXISTS idx_book_clubs_tags ON book_clubs USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_book_clubs_is_private ON book_clubs(is_private);
CREATE INDEX IF NOT EXISTS idx_book_clubs_created_at ON book_clubs(created_at);

-- Club Memberships indexes
CREATE INDEX IF NOT EXISTS idx_club_memberships_club_id ON club_memberships(club_id);
CREATE INDEX IF NOT EXISTS idx_club_memberships_user_id ON club_memberships(user_id);
CREATE INDEX IF NOT EXISTS idx_club_memberships_role ON club_memberships(role);

-- Discussions indexes
CREATE INDEX IF NOT EXISTS idx_discussions_created_by ON discussions(created_by);
CREATE INDEX IF NOT EXISTS idx_discussions_tags ON discussions USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_discussions_is_active ON discussions(is_active);
CREATE INDEX IF NOT EXISTS idx_discussions_created_at ON discussions(created_at);
CREATE INDEX IF NOT EXISTS idx_discussions_last_activity ON discussions(last_activity);

-- Discussion Messages indexes
CREATE INDEX IF NOT EXISTS idx_discussion_messages_discussion_id ON discussion_messages(discussion_id);
CREATE INDEX IF NOT EXISTS idx_discussion_messages_user_id ON discussion_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_discussion_messages_created_at ON discussion_messages(created_at);

-- Discussion Participants indexes
CREATE INDEX IF NOT EXISTS idx_discussion_participants_discussion_id ON discussion_participants(discussion_id);
CREATE INDEX IF NOT EXISTS idx_discussion_participants_user_id ON discussion_participants(user_id);

-- Friend Connections indexes
CREATE INDEX IF NOT EXISTS idx_friend_connections_user_id ON friend_connections(user_id);
CREATE INDEX IF NOT EXISTS idx_friend_connections_friend_id ON friend_connections(friend_id);
CREATE INDEX IF NOT EXISTS idx_friend_connections_status ON friend_connections(status);
CREATE INDEX IF NOT EXISTS idx_friend_connections_match_score ON friend_connections(personality_match_score);

-- Friend Recommendations indexes
CREATE INDEX IF NOT EXISTS idx_friend_recommendations_user_id ON friend_recommendations(user_id);
CREATE INDEX IF NOT EXISTS idx_friend_recommendations_match_score ON friend_recommendations(match_score);
CREATE INDEX IF NOT EXISTS idx_friend_recommendations_is_viewed ON friend_recommendations(is_viewed);

-- ============================================================================
-- TRIGGERS FOR UPDATED_AT COLUMNS
-- ============================================================================

-- Create or replace the update_updated_at_column function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at columns
DROP TRIGGER IF EXISTS update_book_clubs_updated_at ON book_clubs;
CREATE TRIGGER update_book_clubs_updated_at BEFORE UPDATE ON book_clubs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_discussions_updated_at ON discussions;
CREATE TRIGGER update_discussions_updated_at BEFORE UPDATE ON discussions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_discussion_messages_updated_at ON discussion_messages;
CREATE TRIGGER update_discussion_messages_updated_at BEFORE UPDATE ON discussion_messages FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_friend_connections_updated_at ON friend_connections;
CREATE TRIGGER update_friend_connections_updated_at BEFORE UPDATE ON friend_connections FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE book_clubs ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussions ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussion_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussion_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE friend_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE friend_recommendations ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for Tailor Mates tables
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON book_clubs;
CREATE POLICY "Enable all access for authenticated users" ON book_clubs FOR ALL USING (true);

DROP POLICY IF EXISTS "Enable all access for authenticated users" ON club_memberships;
CREATE POLICY "Enable all access for authenticated users" ON club_memberships FOR ALL USING (true);

DROP POLICY IF EXISTS "Enable all access for authenticated users" ON discussions;
CREATE POLICY "Enable all access for authenticated users" ON discussions FOR ALL USING (true);

DROP POLICY IF EXISTS "Enable all access for authenticated users" ON discussion_messages;
CREATE POLICY "Enable all access for authenticated users" ON discussion_messages FOR ALL USING (true);

DROP POLICY IF EXISTS "Enable all access for authenticated users" ON discussion_participants;
CREATE POLICY "Enable all access for authenticated users" ON discussion_participants FOR ALL USING (true);

DROP POLICY IF EXISTS "Enable all access for authenticated users" ON friend_connections;
CREATE POLICY "Enable all access for authenticated users" ON friend_connections FOR ALL USING (true);

DROP POLICY IF EXISTS "Enable all access for authenticated users" ON friend_recommendations;
CREATE POLICY "Enable all access for authenticated users" ON friend_recommendations FOR ALL USING (true);

-- ============================================================================
-- TAILOR MATES FUNCTIONS
-- ============================================================================

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

-- ============================================================================
-- SAMPLE DATA (OPTIONAL - FOR TESTING)
-- ============================================================================

-- Insert sample book clubs (only if you want to test with sample data)
-- Uncomment the following section if you want to add sample data

/*
INSERT INTO book_clubs (name, description, current_book_title, current_book_author, max_members, personality_traits, meeting_time, next_meeting_date, is_private, tags, created_by) VALUES
('Fantasy Enthusiasts', 'A club for lovers of fantasy and magical realism. We explore worlds beyond imagination.', 'Fourth Wing', 'Rebecca Yarros', 20, ARRAY['Openness', 'Extraversion'], 'Every Tuesday 7 PM', CURRENT_DATE + INTERVAL '2 days', false, ARRAY['Fantasy', 'Romance', 'Adventure'], (SELECT id FROM users LIMIT 1)),
('Thriller Seekers', 'For those who love psychological thrillers and suspense. We dive deep into the human psyche.', 'The Silent Patient', 'Alex Michaelides', 15, ARRAY['Conscientiousness', 'Emotional Stability'], 'Every Thursday 8 PM', CURRENT_DATE + INTERVAL '4 days', false, ARRAY['Thriller', 'Psychological', 'Mystery'], (SELECT id FROM users LIMIT 1)),
('Self-Development Circle', 'Focused on personal growth and self-improvement books. Let''s grow together!', 'Atomic Habits', 'James Clear', 25, ARRAY['Conscientiousness', 'Agreeableness'], 'Every Sunday 6 PM', CURRENT_DATE + INTERVAL '7 days', false, ARRAY['Self-Help', 'Personal Growth', 'Psychology'], (SELECT id FROM users LIMIT 1));
*/

-- ============================================================================
-- COMPLETION MESSAGE
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE 'Tailor Mates setup completed successfully!';
    RAISE NOTICE 'Database schema, functions, and policies have been created.';
    RAISE NOTICE 'You can now use the Tailor Mates feature in your application.';
END $$;
