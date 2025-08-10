-- Tailor Mates Database Schema
-- Tables for book clubs, discussions, and friend matching

-- Book Clubs table
CREATE TABLE book_clubs (
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
CREATE TABLE club_memberships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    club_id UUID NOT NULL REFERENCES book_clubs(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) DEFAULT 'member' CHECK (role IN ('member', 'moderator', 'admin')),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(club_id, user_id)
);

-- Discussions table
CREATE TABLE discussions (
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
CREATE TABLE discussion_messages (
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
CREATE TABLE discussion_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    discussion_id UUID NOT NULL REFERENCES discussions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_read_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(discussion_id, user_id)
);

-- Friend Connections table
CREATE TABLE friend_connections (
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
CREATE TABLE friend_recommendations (
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

-- Create indexes for better performance
CREATE INDEX idx_book_clubs_created_by ON book_clubs(created_by);
CREATE INDEX idx_book_clubs_personality_traits ON book_clubs USING GIN(personality_traits);
CREATE INDEX idx_book_clubs_tags ON book_clubs USING GIN(tags);
CREATE INDEX idx_book_clubs_is_private ON book_clubs(is_private);
CREATE INDEX idx_book_clubs_created_at ON book_clubs(created_at);

CREATE INDEX idx_club_memberships_club_id ON club_memberships(club_id);
CREATE INDEX idx_club_memberships_user_id ON club_memberships(user_id);
CREATE INDEX idx_club_memberships_role ON club_memberships(role);

CREATE INDEX idx_discussions_created_by ON discussions(created_by);
CREATE INDEX idx_discussions_tags ON discussions USING GIN(tags);
CREATE INDEX idx_discussions_is_active ON discussions(is_active);
CREATE INDEX idx_discussions_created_at ON discussions(created_at);
CREATE INDEX idx_discussions_last_activity ON discussions(last_activity);

CREATE INDEX idx_discussion_messages_discussion_id ON discussion_messages(discussion_id);
CREATE INDEX idx_discussion_messages_user_id ON discussion_messages(user_id);
CREATE INDEX idx_discussion_messages_created_at ON discussion_messages(created_at);

CREATE INDEX idx_discussion_participants_discussion_id ON discussion_participants(discussion_id);
CREATE INDEX idx_discussion_participants_user_id ON discussion_participants(user_id);

CREATE INDEX idx_friend_connections_user_id ON friend_connections(user_id);
CREATE INDEX idx_friend_connections_friend_id ON friend_connections(friend_id);
CREATE INDEX idx_friend_connections_status ON friend_connections(status);
CREATE INDEX idx_friend_connections_match_score ON friend_connections(personality_match_score);

CREATE INDEX idx_friend_recommendations_user_id ON friend_recommendations(user_id);
CREATE INDEX idx_friend_recommendations_match_score ON friend_recommendations(match_score);
CREATE INDEX idx_friend_recommendations_is_viewed ON friend_recommendations(is_viewed);

-- Create triggers for updated_at columns
CREATE TRIGGER update_book_clubs_updated_at BEFORE UPDATE ON book_clubs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_discussions_updated_at BEFORE UPDATE ON discussions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_discussion_messages_updated_at BEFORE UPDATE ON discussion_messages FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_friend_connections_updated_at BEFORE UPDATE ON friend_connections FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create RLS policies for Tailor Mates tables
CREATE POLICY "Enable all access for authenticated users" ON book_clubs FOR ALL USING (true);
CREATE POLICY "Enable all access for authenticated users" ON club_memberships FOR ALL USING (true);
CREATE POLICY "Enable all access for authenticated users" ON discussions FOR ALL USING (true);
CREATE POLICY "Enable all access for authenticated users" ON discussion_messages FOR ALL USING (true);
CREATE POLICY "Enable all access for authenticated users" ON discussion_participants FOR ALL USING (true);
CREATE POLICY "Enable all access for authenticated users" ON friend_connections FOR ALL USING (true);
CREATE POLICY "Enable all access for authenticated users" ON friend_recommendations FOR ALL USING (true);
