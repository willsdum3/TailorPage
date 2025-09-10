-- Create the book_club_messages table for storing messages within book clubs
-- This table stores messages that members send in book club discussions

CREATE TABLE IF NOT EXISTS book_club_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    club_id UUID NOT NULL REFERENCES book_clubs(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_book_club_messages_club_id ON book_club_messages(club_id);
CREATE INDEX IF NOT EXISTS idx_book_club_messages_user_id ON book_club_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_book_club_messages_created_at ON book_club_messages(created_at DESC);

-- Enable Row Level Security
ALTER TABLE book_club_messages ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Users can only see messages from clubs they are members of
CREATE POLICY "Users can view messages from clubs they are members of" ON book_club_messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM club_memberships 
            WHERE club_memberships.club_id = book_club_messages.club_id 
            AND club_memberships.user_id = auth.uid()::uuid
        )
    );

-- Users can only insert messages if they are members of the club
CREATE POLICY "Users can insert messages if they are club members" ON book_club_messages
    FOR INSERT WITH CHECK (
        user_id = auth.uid()::uuid AND
        EXISTS (
            SELECT 1 FROM club_memberships 
            WHERE club_memberships.club_id = book_club_messages.club_id 
            AND club_memberships.user_id = auth.uid()::uuid
        )
    );

-- Users can only update their own messages
CREATE POLICY "Users can update their own messages" ON book_club_messages
    FOR UPDATE USING (user_id = auth.uid()::uuid);

-- Users can only delete their own messages
CREATE POLICY "Users can delete their own messages" ON book_club_messages
    FOR DELETE USING (user_id = auth.uid()::uuid);
