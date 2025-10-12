-- Create Poll Tables if Missing
-- Ensure book_selection_polls and poll_options tables exist

-- Create book_selection_polls table if it doesn't exist
CREATE TABLE IF NOT EXISTS book_selection_polls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES book_clubs(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    closes_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create poll_options table if it doesn't exist
CREATE TABLE IF NOT EXISTS poll_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poll_id UUID NOT NULL REFERENCES book_selection_polls(id) ON DELETE CASCADE,
    option_index INTEGER NOT NULL,
    title TEXT NOT NULL,
    author TEXT NOT NULL,
    cover_url TEXT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(poll_id, option_index)
);

-- Create poll_votes table if it doesn't exist
CREATE TABLE IF NOT EXISTS poll_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poll_id UUID NOT NULL REFERENCES book_selection_polls(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    option_index INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(poll_id, user_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_book_selection_polls_club_id ON book_selection_polls(club_id);
CREATE INDEX IF NOT EXISTS idx_book_selection_polls_created_by ON book_selection_polls(created_by);
CREATE INDEX IF NOT EXISTS idx_poll_options_poll_id ON poll_options(poll_id);
CREATE INDEX IF NOT EXISTS idx_poll_votes_poll_id ON poll_votes(poll_id);
CREATE INDEX IF NOT EXISTS idx_poll_votes_user_id ON poll_votes(user_id);

-- Enable RLS on all tables
ALTER TABLE book_selection_polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE poll_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE poll_votes ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for book_selection_polls
DROP POLICY IF EXISTS "Users can view polls for clubs they belong to" ON book_selection_polls;
CREATE POLICY "Users can view polls for clubs they belong to" ON book_selection_polls
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM book_club_members bcm
            WHERE bcm.club_id = book_selection_polls.club_id
            AND bcm.user_id = get_user_internal_id(auth.uid())
        )
    );

DROP POLICY IF EXISTS "Admins can create polls" ON book_selection_polls;
CREATE POLICY "Admins can create polls" ON book_selection_polls
    FOR INSERT WITH CHECK (
        created_by = get_user_internal_id(auth.uid()) AND (
            EXISTS (
                SELECT 1 FROM book_clubs bc
                WHERE bc.id = club_id AND bc.created_by = get_user_internal_id(auth.uid())
            ) OR EXISTS (
                SELECT 1 FROM book_club_members bcm
                WHERE bcm.club_id = book_selection_polls.club_id
                AND bcm.user_id = get_user_internal_id(auth.uid())
                AND bcm.role = 'admin'
            )
        )
    );

-- Create RLS policies for poll_options
DROP POLICY IF EXISTS "Users can view poll options" ON poll_options;
CREATE POLICY "Users can view poll options" ON poll_options
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM book_selection_polls bsp
            JOIN book_club_members bcm ON bcm.club_id = bsp.club_id
            WHERE bsp.id = poll_options.poll_id
            AND bcm.user_id = get_user_internal_id(auth.uid())
        )
    );

DROP POLICY IF EXISTS "System can create poll options" ON poll_options;
CREATE POLICY "System can create poll options" ON poll_options
    FOR INSERT WITH CHECK (true);

-- Create RLS policies for poll_votes
DROP POLICY IF EXISTS "Users can view their own votes" ON poll_votes;
CREATE POLICY "Users can view their own votes" ON poll_votes
    FOR SELECT USING (user_id = get_user_internal_id(auth.uid()));

DROP POLICY IF EXISTS "Users can vote on polls for clubs they belong to" ON poll_votes;
CREATE POLICY "Users can vote on polls for clubs they belong to" ON poll_votes
    FOR INSERT WITH CHECK (
        user_id = get_user_internal_id(auth.uid()) AND
        EXISTS (
            SELECT 1 FROM book_selection_polls bsp
            JOIN book_club_members bcm ON bcm.club_id = bsp.club_id
            WHERE bsp.id = poll_votes.poll_id
            AND bcm.user_id = get_user_internal_id(auth.uid())
        )
    );

-- Show table creation status
SELECT 
    'Poll Tables Status' as check_type,
    table_name,
    CASE 
        WHEN table_name IN ('book_selection_polls', 'poll_options', 'poll_votes') 
        THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('book_selection_polls', 'poll_options', 'poll_votes')
ORDER BY table_name;
