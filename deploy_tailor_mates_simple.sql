-- Tailor Mates Complete Deployment Script
-- Run this entire script in your Supabase SQL Editor

-- ========================================
-- SCHEMA CREATION
-- ========================================

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

-- ========================================
-- INDEXES
-- ========================================

-- Book Clubs indexes
CREATE INDEX IF NOT EXISTS idx_book_clubs_created_by ON book_clubs(created_by);
CREATE INDEX IF NOT EXISTS idx_book_clubs_created_at ON book_clubs(created_at);
CREATE INDEX IF NOT EXISTS idx_book_clubs_personality_traits ON book_clubs USING GIN(personality_traits);
CREATE INDEX IF NOT EXISTS idx_book_clubs_tags ON book_clubs USING GIN(tags);

-- Club Memberships indexes
CREATE INDEX IF NOT EXISTS idx_club_memberships_club_id ON club_memberships(club_id);
CREATE INDEX IF NOT EXISTS idx_club_memberships_user_id ON club_memberships(user_id);
CREATE INDEX IF NOT EXISTS idx_club_memberships_active ON club_memberships(is_active);

-- Discussions indexes
CREATE INDEX IF NOT EXISTS idx_discussions_created_by ON discussions(created_by);
CREATE INDEX IF NOT EXISTS idx_discussions_created_at ON discussions(created_at);
CREATE INDEX IF NOT EXISTS idx_discussions_active ON discussions(is_active);
CREATE INDEX IF NOT EXISTS idx_discussions_tags ON discussions USING GIN(tags);

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

-- Friend Recommendations indexes
CREATE INDEX IF NOT EXISTS idx_friend_recommendations_user_id ON friend_recommendations(user_id);
CREATE INDEX IF NOT EXISTS idx_friend_recommendations_match_score ON friend_recommendations(match_score);

-- ========================================
-- FUNCTIONS
-- ========================================

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
        COALESCE(cm.user_id IS NOT NULL, FALSE) as is_member,
        COALESCE(cm.role, '') as user_role,
        u.name as creator_name
    FROM book_clubs bc
    LEFT JOIN club_memberships cm ON bc.id = cm.club_id AND cm.user_id = user_uuid
    LEFT JOIN users u ON bc.created_by = u.id
    WHERE bc.is_private = FALSE OR cm.user_id IS NOT NULL
    ORDER BY bc.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to join a book club
CREATE OR REPLACE FUNCTION join_book_club(user_clerk_id TEXT, club_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
    existing_membership UUID;
    current_member_count INTEGER;
    max_member_count INTEGER;
BEGIN
    -- Get user UUID
    SELECT id INTO user_uuid FROM users WHERE clerk_id = user_clerk_id;
    
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;

    -- Check if already a member
    SELECT id INTO existing_membership FROM club_memberships 
    WHERE club_id = join_book_club.club_id AND user_id = user_uuid;
    
    IF existing_membership IS NOT NULL THEN
        RETURN FALSE; -- Already a member
    END IF;

    -- Check if club is full
    SELECT member_count, max_members INTO current_member_count, max_member_count 
    FROM book_clubs WHERE id = join_book_club.club_id;
    
    IF current_member_count >= max_member_count THEN
        RAISE EXCEPTION 'Club is full';
    END IF;

    -- Add membership
    INSERT INTO club_memberships (club_id, user_id) 
    VALUES (join_book_club.club_id, user_uuid);

    -- Update member count
    UPDATE book_clubs SET member_count = member_count + 1 
    WHERE id = join_book_club.club_id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to leave a book club
CREATE OR REPLACE FUNCTION leave_book_club(user_clerk_id TEXT, club_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
    membership_id UUID;
BEGIN
    -- Get user UUID
    SELECT id INTO user_uuid FROM users WHERE clerk_id = user_clerk_id;
    
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;

    -- Check if user is a member
    SELECT id INTO membership_id FROM club_memberships 
    WHERE club_id = leave_book_club.club_id AND user_id = user_uuid;
    
    IF membership_id IS NULL THEN
        RETURN FALSE; -- Not a member
    END IF;

    -- Remove membership
    DELETE FROM club_memberships WHERE id = membership_id;

    -- Update member count
    UPDATE book_clubs SET member_count = member_count - 1 
    WHERE id = leave_book_club.club_id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create a discussion
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
        COALESCE(dp.user_id IS NOT NULL, FALSE) as is_participant,
        u.name as creator_name
    FROM discussions d
    LEFT JOIN discussion_participants dp ON d.id = dp.discussion_id AND dp.user_id = user_uuid
    LEFT JOIN users u ON d.created_by = u.id
    WHERE d.is_active = TRUE
    ORDER BY d.last_activity DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to send friend request
CREATE OR REPLACE FUNCTION send_friend_request(user_clerk_id TEXT, friend_clerk_id TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
    friend_uuid UUID;
    existing_connection UUID;
BEGIN
    -- Get user UUIDs
    SELECT id INTO user_uuid FROM users WHERE clerk_id = user_clerk_id;
    SELECT id INTO friend_uuid FROM users WHERE clerk_id = friend_clerk_id;
    
    IF user_uuid IS NULL OR friend_uuid IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;

    IF user_uuid = friend_uuid THEN
        RAISE EXCEPTION 'Cannot send friend request to yourself';
    END IF;

    -- Check if connection already exists
    SELECT id INTO existing_connection FROM friend_connections 
    WHERE (user_id = user_uuid AND friend_id = friend_uuid) 
       OR (user_id = friend_uuid AND friend_id = user_uuid);
    
    IF existing_connection IS NOT NULL THEN
        RETURN FALSE; -- Connection already exists
    END IF;

    -- Create friend request
    INSERT INTO friend_connections (user_id, friend_id, status) 
    VALUES (user_uuid, friend_uuid, 'pending');

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to accept friend request
CREATE OR REPLACE FUNCTION accept_friend_request(user_clerk_id TEXT, friend_clerk_id TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
    friend_uuid UUID;
    connection_id UUID;
BEGIN
    -- Get user UUIDs
    SELECT id INTO user_uuid FROM users WHERE clerk_id = user_clerk_id;
    SELECT id INTO friend_uuid FROM users WHERE clerk_id = friend_clerk_id;
    
    IF user_uuid IS NULL OR friend_uuid IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;

    -- Find the pending request
    SELECT id INTO connection_id FROM friend_connections 
    WHERE friend_id = user_uuid AND user_id = friend_uuid AND status = 'pending';
    
    IF connection_id IS NULL THEN
        RETURN FALSE; -- No pending request found
    END IF;

    -- Accept the request
    UPDATE friend_connections SET status = 'accepted', updated_at = NOW() 
    WHERE id = connection_id;

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
        fc.status,
        fc.personality_match_score,
        fc.created_at
    FROM friend_connections fc
    JOIN users u ON (fc.user_id = user_uuid AND fc.friend_id = u.id) 
                 OR (fc.friend_id = user_uuid AND fc.user_id = u.id)
    ORDER BY fc.updated_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get friend recommendations
CREATE OR REPLACE FUNCTION get_friend_recommendations(user_clerk_id TEXT)
RETURNS TABLE (
    id UUID,
    recommended_user_id UUID,
    recommended_user_name TEXT,
    recommended_user_username TEXT,
    match_score DECIMAL(3,2),
    match_reasons TEXT[]
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
        fr.match_score,
        fr.match_reasons
    FROM friend_recommendations fr
    JOIN users u ON fr.recommended_user_id = u.id
    WHERE fr.user_id = user_uuid AND fr.is_viewed = FALSE
    ORDER BY fr.match_score DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to generate friend recommendations (simplified version)
CREATE OR REPLACE FUNCTION generate_friend_recommendations(user_clerk_id TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
BEGIN
    -- Get user UUID
    SELECT id INTO user_uuid FROM users WHERE clerk_id = user_clerk_id;
    
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;

    -- Clear existing recommendations
    DELETE FROM friend_recommendations WHERE user_id = user_uuid;

    -- Generate simple recommendations (random users, excluding existing friends)
    INSERT INTO friend_recommendations (user_id, recommended_user_id, match_score, match_reasons)
    SELECT 
        user_uuid,
        u.id,
        (RANDOM() * 0.4 + 0.6)::DECIMAL(3,2), -- Random score between 0.6 and 1.0
        ARRAY['Similar reading interests', 'Compatible personality traits']
    FROM users u
    WHERE u.id != user_uuid
    AND u.id NOT IN (
        SELECT friend_id FROM friend_connections WHERE user_id = user_uuid
        UNION
        SELECT user_id FROM friend_connections WHERE friend_id = user_uuid
    )
    AND u.id NOT IN (
        SELECT recommended_user_id FROM friend_recommendations WHERE user_id = user_uuid
    )
    LIMIT 10;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ========================================

-- Enable RLS on all tables
ALTER TABLE book_clubs ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussions ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussion_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussion_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE friend_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE friend_recommendations ENABLE ROW LEVEL SECURITY;

-- Book clubs policies
CREATE POLICY "Users can view public book clubs" ON book_clubs
    FOR SELECT USING (is_private = FALSE);

CREATE POLICY "Club members can view private clubs" ON book_clubs
    FOR SELECT USING (
        is_private = TRUE AND 
        EXISTS (
            SELECT 1 FROM club_memberships cm 
            WHERE cm.club_id = book_clubs.id 
            AND cm.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create book clubs" ON book_clubs
    FOR INSERT WITH CHECK (
        created_by = auth.uid()
    );

CREATE POLICY "Club admins can update their clubs" ON book_clubs
    FOR UPDATE USING (
        created_by = auth.uid()
    );

-- Club memberships policies
CREATE POLICY "Users can view their memberships" ON club_memberships
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can join clubs" ON club_memberships
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can leave clubs" ON club_memberships
    FOR DELETE USING (user_id = auth.uid());

-- Discussions policies
CREATE POLICY "Users can view discussions" ON discussions
    FOR SELECT USING (is_active = TRUE);

CREATE POLICY "Users can create discussions" ON discussions
    FOR INSERT WITH CHECK (created_by = auth.uid());

-- Discussion messages policies
CREATE POLICY "Users can view messages in discussions they participate in" ON discussion_messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM discussion_participants dp 
            WHERE dp.discussion_id = discussion_messages.discussion_id 
            AND dp.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can add messages to discussions they participate in" ON discussion_messages
    FOR INSERT WITH CHECK (
        user_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM discussion_participants dp 
            WHERE dp.discussion_id = discussion_messages.discussion_id 
            AND dp.user_id = auth.uid()
        )
    );

-- Discussion participants policies
CREATE POLICY "Users can view participants in discussions they participate in" ON discussion_participants
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM discussion_participants dp2 
            WHERE dp2.discussion_id = discussion_participants.discussion_id 
            AND dp2.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can join discussions" ON discussion_participants
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Friend connections policies
CREATE POLICY "Users can view their friend connections" ON friend_connections
    FOR SELECT USING (user_id = auth.uid() OR friend_id = auth.uid());

CREATE POLICY "Users can create friend connections" ON friend_connections
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their friend connections" ON friend_connections
    FOR UPDATE USING (user_id = auth.uid() OR friend_id = auth.uid());

-- Friend recommendations policies
CREATE POLICY "Users can view their recommendations" ON friend_recommendations
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "System can create recommendations" ON friend_recommendations
    FOR INSERT WITH CHECK (true);

-- ========================================
-- DEPLOYMENT COMPLETE
-- ========================================

-- Success message
SELECT 'Tailor Mates deployment completed successfully!' as status;

