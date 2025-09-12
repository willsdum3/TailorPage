-- Create tables for book club polls
-- This enables book selection polls and other voting features

-- Create book_club_polls table
CREATE TABLE IF NOT EXISTS book_club_polls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES book_clubs(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    poll_type TEXT NOT NULL DEFAULT 'book_selection', -- 'book_selection', 'meeting_time', 'other'
    status TEXT NOT NULL DEFAULT 'active', -- 'active', 'closed', 'cancelled'
    options JSONB NOT NULL, -- Array of poll options with book details
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    closes_at TIMESTAMP WITH TIME ZONE
);

-- Create book_club_poll_votes table
CREATE TABLE IF NOT EXISTS book_club_poll_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poll_id UUID NOT NULL REFERENCES book_club_polls(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    option_index INTEGER NOT NULL, -- Index of the selected option in the options array
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(poll_id, user_id) -- One vote per user per poll
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_book_club_polls_club_id ON book_club_polls(club_id);
CREATE INDEX IF NOT EXISTS idx_book_club_polls_created_by ON book_club_polls(created_by);
CREATE INDEX IF NOT EXISTS idx_book_club_polls_status ON book_club_polls(status);
CREATE INDEX IF NOT EXISTS idx_book_club_poll_votes_poll_id ON book_club_poll_votes(poll_id);
CREATE INDEX IF NOT EXISTS idx_book_club_poll_votes_user_id ON book_club_poll_votes(user_id);

-- Enable RLS
ALTER TABLE book_club_polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE book_club_poll_votes ENABLE ROW LEVEL SECURITY;

-- RLS Policies for book_club_polls
CREATE POLICY "Users can view polls for clubs they are members of" ON book_club_polls
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM club_memberships cm
            JOIN users u ON cm.user_id = u.id
            WHERE cm.club_id = book_club_polls.club_id
            AND u.auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can create polls for their clubs" ON book_club_polls
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM club_memberships cm
            JOIN users u ON cm.user_id = u.id
            WHERE cm.club_id = book_club_polls.club_id
            AND u.auth_user_id = auth.uid()
            AND cm.role = 'admin'
        )
    );

CREATE POLICY "Admins can update polls for their clubs" ON book_club_polls
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM club_memberships cm
            JOIN users u ON cm.user_id = u.id
            WHERE cm.club_id = book_club_polls.club_id
            AND u.auth_user_id = auth.uid()
            AND cm.role = 'admin'
        )
    );

-- RLS Policies for book_club_poll_votes
CREATE POLICY "Users can view votes for polls they can see" ON book_club_poll_votes
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM book_club_polls bp
            JOIN club_memberships cm ON bp.club_id = cm.club_id
            JOIN users u ON cm.user_id = u.id
            WHERE bp.id = book_club_poll_votes.poll_id
            AND u.auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can vote on polls for clubs they are members of" ON book_club_poll_votes
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM book_club_polls bp
            JOIN club_memberships cm ON bp.club_id = cm.club_id
            JOIN users u ON cm.user_id = u.id
            WHERE bp.id = book_club_poll_votes.poll_id
            AND u.auth_user_id = auth.uid()
            AND bp.status = 'active'
        )
    );

CREATE POLICY "Users can update their own votes" ON book_club_poll_votes
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM users u
            WHERE u.id = book_club_poll_votes.user_id
            AND u.auth_user_id = auth.uid()
        )
    );
