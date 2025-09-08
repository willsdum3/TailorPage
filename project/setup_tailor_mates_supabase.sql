-- =====================================================
-- TAILOR MATES SETUP FOR SUPABASE AUTH
-- =====================================================
-- This script creates all Tailor Mates tables and functions for Supabase Auth

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- STEP 1: CREATE TAILOR MATES TABLES
-- =====================================================

-- Book Clubs table
CREATE TABLE IF NOT EXISTS book_clubs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    current_book_title TEXT,
    current_book_author TEXT,
    max_members INTEGER NOT NULL DEFAULT 10 CHECK (max_members >= 5 AND max_members <= 100),
    is_public BOOLEAN NOT NULL DEFAULT true,
    target_personality_traits TEXT[] DEFAULT '{}',
    tags TEXT[] DEFAULT '{}',
    meeting_info TEXT,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Club Memberships table
CREATE TABLE IF NOT EXISTS club_memberships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    club_id UUID NOT NULL REFERENCES book_clubs(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member')),
    UNIQUE(club_id, user_id)
);

-- Discussions table
CREATE TABLE IF NOT EXISTS discussions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    book_title TEXT,
    book_author TEXT,
    tags TEXT[] DEFAULT '{}',
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Discussion Messages table
CREATE TABLE IF NOT EXISTS discussion_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    discussion_id UUID NOT NULL REFERENCES discussions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
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
    requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    addressee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'blocked')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(requester_id, addressee_id),
    CHECK (requester_id != addressee_id)
);

-- Friend Recommendations table
CREATE TABLE IF NOT EXISTS friend_recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recommended_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    match_score DECIMAL(5,2) NOT NULL CHECK (match_score >= 0 AND match_score <= 100),
    match_reasons TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),
    UNIQUE(user_id, recommended_user_id),
    CHECK (user_id != recommended_user_id)
);

-- =====================================================
-- STEP 2: CREATE INDEXES FOR PERFORMANCE
-- =====================================================

-- Book Clubs indexes
CREATE INDEX IF NOT EXISTS idx_book_clubs_created_by ON book_clubs(created_by);
CREATE INDEX IF NOT EXISTS idx_book_clubs_is_public ON book_clubs(is_public);
CREATE INDEX IF NOT EXISTS idx_book_clubs_created_at ON book_clubs(created_at DESC);

-- Club Memberships indexes
CREATE INDEX IF NOT EXISTS idx_club_memberships_club_id ON club_memberships(club_id);
CREATE INDEX IF NOT EXISTS idx_club_memberships_user_id ON club_memberships(user_id);

-- Discussions indexes
CREATE INDEX IF NOT EXISTS idx_discussions_created_by ON discussions(created_by);
CREATE INDEX IF NOT EXISTS idx_discussions_created_at ON discussions(created_at DESC);

-- Discussion Messages indexes
CREATE INDEX IF NOT EXISTS idx_discussion_messages_discussion_id ON discussion_messages(discussion_id);
CREATE INDEX IF NOT EXISTS idx_discussion_messages_created_at ON discussion_messages(created_at DESC);

-- Discussion Participants indexes
CREATE INDEX IF NOT EXISTS idx_discussion_participants_discussion_id ON discussion_participants(discussion_id);
CREATE INDEX IF NOT EXISTS idx_discussion_participants_user_id ON discussion_participants(user_id);

-- Friend Connections indexes
CREATE INDEX IF NOT EXISTS idx_friend_connections_requester_id ON friend_connections(requester_id);
CREATE INDEX IF NOT EXISTS idx_friend_connections_addressee_id ON friend_connections(addressee_id);
CREATE INDEX IF NOT EXISTS idx_friend_connections_status ON friend_connections(status);

-- Friend Recommendations indexes
CREATE INDEX IF NOT EXISTS idx_friend_recommendations_user_id ON friend_recommendations(user_id);
CREATE INDEX IF NOT EXISTS idx_friend_recommendations_match_score ON friend_recommendations(match_score DESC);
CREATE INDEX IF NOT EXISTS idx_friend_recommendations_expires_at ON friend_recommendations(expires_at);

-- =====================================================
-- STEP 3: ENABLE ROW LEVEL SECURITY
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE book_clubs ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussions ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussion_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussion_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE friend_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE friend_recommendations ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- STEP 4: CREATE RLS POLICIES
-- =====================================================

-- Book Clubs policies
CREATE POLICY "Users can view public book clubs" ON book_clubs
    FOR SELECT USING (is_public = true OR created_by = auth.uid()::uuid);

CREATE POLICY "Users can create book clubs" ON book_clubs
    FOR INSERT WITH CHECK (created_by = auth.uid()::uuid);

CREATE POLICY "Users can update their own book clubs" ON book_clubs
    FOR UPDATE USING (created_by = auth.uid()::uuid);

CREATE POLICY "Users can delete their own book clubs" ON book_clubs
    FOR DELETE USING (created_by = auth.uid()::uuid);

-- Club Memberships policies
CREATE POLICY "Users can view club memberships" ON club_memberships
    FOR SELECT USING (true);

CREATE POLICY "Users can join clubs" ON club_memberships
    FOR INSERT WITH CHECK (user_id = auth.uid()::uuid);

CREATE POLICY "Users can leave clubs" ON club_memberships
    FOR DELETE USING (user_id = auth.uid()::uuid);

-- Discussions policies
CREATE POLICY "Users can view discussions" ON discussions
    FOR SELECT USING (true);

CREATE POLICY "Users can create discussions" ON discussions
    FOR INSERT WITH CHECK (created_by = auth.uid()::uuid);

CREATE POLICY "Users can update their own discussions" ON discussions
    FOR UPDATE USING (created_by = auth.uid()::uuid);

CREATE POLICY "Users can delete their own discussions" ON discussions
    FOR DELETE USING (created_by = auth.uid()::uuid);

-- Discussion Messages policies
CREATE POLICY "Users can view discussion messages" ON discussion_messages
    FOR SELECT USING (true);

CREATE POLICY "Users can create discussion messages" ON discussion_messages
    FOR INSERT WITH CHECK (user_id = auth.uid()::uuid);

CREATE POLICY "Users can update their own discussion messages" ON discussion_messages
    FOR UPDATE USING (user_id = auth.uid()::uuid);

CREATE POLICY "Users can delete their own discussion messages" ON discussion_messages
    FOR DELETE USING (user_id = auth.uid()::uuid);

-- Discussion Participants policies
CREATE POLICY "Users can view discussion participants" ON discussion_participants
    FOR SELECT USING (true);

CREATE POLICY "Users can join discussions" ON discussion_participants
    FOR INSERT WITH CHECK (user_id = auth.uid()::uuid);

CREATE POLICY "Users can leave discussions" ON discussion_participants
    FOR DELETE USING (user_id = auth.uid()::uuid);

-- Friend Connections policies
CREATE POLICY "Users can view their friend connections" ON friend_connections
    FOR SELECT USING (requester_id = auth.uid()::uuid OR addressee_id = auth.uid()::uuid);

CREATE POLICY "Users can create friend connections" ON friend_connections
    FOR INSERT WITH CHECK (requester_id = auth.uid()::uuid);

CREATE POLICY "Users can update friend connections they're involved in" ON friend_connections
    FOR UPDATE USING (requester_id = auth.uid()::uuid OR addressee_id = auth.uid()::uuid);

-- Friend Recommendations policies
CREATE POLICY "Users can view their friend recommendations" ON friend_recommendations
    FOR SELECT USING (user_id = auth.uid()::uuid);

CREATE POLICY "Users can create friend recommendations" ON friend_recommendations
    FOR INSERT WITH CHECK (user_id = auth.uid()::uuid);

CREATE POLICY "Users can delete their friend recommendations" ON friend_recommendations
    FOR DELETE USING (user_id = auth.uid()::uuid);

-- =====================================================
-- STEP 5: CREATE HELPER FUNCTIONS
-- =====================================================

-- Function to get user ID from auth_user_id
CREATE OR REPLACE FUNCTION get_user_id_from_auth(auth_user_id UUID)
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
BEGIN
    SELECT id INTO user_uuid
    FROM users
    WHERE auth_user_id = get_user_id_from_auth.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'User not found for auth_user_id: %', auth_user_id;
    END IF;
    
    RETURN user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user has completed personality quiz
CREATE OR REPLACE FUNCTION user_has_personality_profile(auth_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
    profile_exists BOOLEAN;
BEGIN
    user_uuid := get_user_id_from_auth(auth_user_id);
    
    SELECT EXISTS(
        SELECT 1 FROM user_personality_profiles 
        WHERE user_id = user_uuid
    ) INTO profile_exists;
    
    RETURN profile_exists;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 6: CREATE TRIGGERS FOR UPDATED_AT
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER update_book_clubs_updated_at
    BEFORE UPDATE ON book_clubs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_discussions_updated_at
    BEFORE UPDATE ON discussions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_discussion_messages_updated_at
    BEFORE UPDATE ON discussion_messages
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_friend_connections_updated_at
    BEFORE UPDATE ON friend_connections
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'Tailor Mates database setup completed successfully!';
    RAISE NOTICE 'Created tables: book_clubs, club_memberships, discussions, discussion_messages, discussion_participants, friend_connections, friend_recommendations';
    RAISE NOTICE 'Created helper functions: get_user_id_from_auth, user_has_personality_profile';
    RAISE NOTICE 'Enabled Row Level Security on all tables';
    RAISE NOTICE 'Created indexes for optimal performance';
    RAISE NOTICE 'Ready for Tailor Mates functionality!';
END $$;
