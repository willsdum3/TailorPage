-- =====================================================
-- TAILOR MATES STEP-BY-STEP SETUP
-- =====================================================
-- This script creates Tailor Mates tables one by one to avoid conflicts

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- STEP 1: DROP EXISTING TABLES (if they exist)
-- =====================================================

-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS friend_recommendations CASCADE;
DROP TABLE IF EXISTS friend_connections CASCADE;
DROP TABLE IF EXISTS discussion_participants CASCADE;
DROP TABLE IF EXISTS discussion_messages CASCADE;
DROP TABLE IF EXISTS discussions CASCADE;
DROP TABLE IF EXISTS club_memberships CASCADE;
DROP TABLE IF EXISTS book_clubs CASCADE;

-- =====================================================
-- STEP 2: CREATE BOOK CLUBS TABLE
-- =====================================================

CREATE TABLE book_clubs (
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

-- Verify book_clubs table was created
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'book_clubs') THEN
        RAISE NOTICE '✅ book_clubs table created successfully';
    ELSE
        RAISE EXCEPTION '❌ Failed to create book_clubs table';
    END IF;
END $$;

-- =====================================================
-- STEP 3: CREATE CLUB MEMBERSHIPS TABLE
-- =====================================================

CREATE TABLE club_memberships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    club_id UUID NOT NULL REFERENCES book_clubs(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member')),
    UNIQUE(club_id, user_id)
);

-- Verify club_memberships table was created
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'club_memberships') THEN
        RAISE NOTICE '✅ club_memberships table created successfully';
    ELSE
        RAISE EXCEPTION '❌ Failed to create club_memberships table';
    END IF;
END $$;

-- =====================================================
-- STEP 4: CREATE DISCUSSIONS TABLE
-- =====================================================

CREATE TABLE discussions (
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

-- Verify discussions table was created
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'discussions') THEN
        RAISE NOTICE '✅ discussions table created successfully';
    ELSE
        RAISE EXCEPTION '❌ Failed to create discussions table';
    END IF;
END $$;

-- =====================================================
-- STEP 5: CREATE DISCUSSION MESSAGES TABLE
-- =====================================================

CREATE TABLE discussion_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    discussion_id UUID NOT NULL REFERENCES discussions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Verify discussion_messages table was created
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'discussion_messages') THEN
        RAISE NOTICE '✅ discussion_messages table created successfully';
    ELSE
        RAISE EXCEPTION '❌ Failed to create discussion_messages table';
    END IF;
END $$;

-- =====================================================
-- STEP 6: CREATE DISCUSSION PARTICIPANTS TABLE
-- =====================================================

CREATE TABLE discussion_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    discussion_id UUID NOT NULL REFERENCES discussions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_read_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(discussion_id, user_id)
);

-- Verify discussion_participants table was created
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'discussion_participants') THEN
        RAISE NOTICE '✅ discussion_participants table created successfully';
    ELSE
        RAISE EXCEPTION '❌ Failed to create discussion_participants table';
    END IF;
END $$;

-- =====================================================
-- STEP 7: CREATE FRIEND CONNECTIONS TABLE
-- =====================================================

CREATE TABLE friend_connections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    addressee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'blocked')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(requester_id, addressee_id),
    CHECK (requester_id != addressee_id)
);

-- Verify friend_connections table was created
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'friend_connections') THEN
        RAISE NOTICE '✅ friend_connections table created successfully';
    ELSE
        RAISE EXCEPTION '❌ Failed to create friend_connections table';
    END IF;
END $$;

-- =====================================================
-- STEP 8: CREATE FRIEND RECOMMENDATIONS TABLE
-- =====================================================

CREATE TABLE friend_recommendations (
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

-- Verify friend_recommendations table was created
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'friend_recommendations') THEN
        RAISE NOTICE '✅ friend_recommendations table created successfully';
    ELSE
        RAISE EXCEPTION '❌ Failed to create friend_recommendations table';
    END IF;
END $$;

-- =====================================================
-- STEP 9: CREATE INDEXES
-- =====================================================

-- Book Clubs indexes
CREATE INDEX idx_book_clubs_created_by ON book_clubs(created_by);
CREATE INDEX idx_book_clubs_is_public ON book_clubs(is_public);
CREATE INDEX idx_book_clubs_created_at ON book_clubs(created_at DESC);

-- Club Memberships indexes
CREATE INDEX idx_club_memberships_club_id ON club_memberships(club_id);
CREATE INDEX idx_club_memberships_user_id ON club_memberships(user_id);

-- Discussions indexes
CREATE INDEX idx_discussions_created_by ON discussions(created_by);
CREATE INDEX idx_discussions_created_at ON discussions(created_at DESC);

-- Discussion Messages indexes
CREATE INDEX idx_discussion_messages_discussion_id ON discussion_messages(discussion_id);
CREATE INDEX idx_discussion_messages_created_at ON discussion_messages(created_at DESC);

-- Discussion Participants indexes
CREATE INDEX idx_discussion_participants_discussion_id ON discussion_participants(discussion_id);
CREATE INDEX idx_discussion_participants_user_id ON discussion_participants(user_id);

-- Friend Connections indexes
CREATE INDEX idx_friend_connections_requester_id ON friend_connections(requester_id);
CREATE INDEX idx_friend_connections_addressee_id ON friend_connections(addressee_id);
CREATE INDEX idx_friend_connections_status ON friend_connections(status);

-- Friend Recommendations indexes
CREATE INDEX idx_friend_recommendations_user_id ON friend_recommendations(user_id);
CREATE INDEX idx_friend_recommendations_match_score ON friend_recommendations(match_score DESC);
CREATE INDEX idx_friend_recommendations_expires_at ON friend_recommendations(expires_at);

-- =====================================================
-- STEP 10: ENABLE ROW LEVEL SECURITY
-- =====================================================

ALTER TABLE book_clubs ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussions ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussion_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussion_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE friend_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE friend_recommendations ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '🎉 Tailor Mates step-by-step setup completed successfully!';
    RAISE NOTICE 'Created tables: book_clubs, club_memberships, discussions, discussion_messages, discussion_participants, friend_connections, friend_recommendations';
    RAISE NOTICE 'Created indexes for optimal performance';
    RAISE NOTICE 'Enabled Row Level Security on all tables';
    RAISE NOTICE 'Ready for Tailor Mates functions deployment!';
END $$;
