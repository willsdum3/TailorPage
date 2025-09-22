-- Create comprehensive Friends messaging and notifications system
-- This script creates all necessary tables and functions for the Friends system

-- =====================================================
-- STEP 1: CREATE TABLES
-- =====================================================

-- Friend conversations table
CREATE TABLE IF NOT EXISTS friend_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user1_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user2_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure user1_id is always less than user2_id for consistency
    CONSTRAINT check_user_order CHECK (user1_id < user2_id),
    -- Ensure no duplicate conversations between the same users
    CONSTRAINT unique_conversation UNIQUE(user1_id, user2_id)
);

-- Friend messages table
CREATE TABLE IF NOT EXISTS friend_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES friend_conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    message_type VARCHAR(50) DEFAULT 'text' CHECK (message_type IN ('text', 'book_recommendation')),
    
    -- Book recommendation data (JSON)
    book_recommendation JSONB,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_read BOOLEAN DEFAULT FALSE,
    is_edited BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Friend requests/connections table (enhance existing or create new)
CREATE TABLE IF NOT EXISTS friend_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'blocked')),
    message TEXT, -- Optional message with friend request
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Prevent duplicate requests
    CONSTRAINT unique_friend_request UNIQUE(requester_id, target_id)
);

-- Blocked users table
CREATE TABLE IF NOT EXISTS blocked_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    blocker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Prevent duplicate blocks
    CONSTRAINT unique_block UNIQUE(blocker_id, blocked_id)
);

-- Notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN (
        'club_message', 'discussion_message', 'friend_message', 
        'club_invitation', 'friend_request', 'admin_promotion'
    )),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    related_id UUID, -- club_id, discussion_id, friend_id, etc.
    related_name VARCHAR(255), -- club name, discussion title, friend name
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- STEP 2: CREATE INDEXES FOR PERFORMANCE
-- =====================================================

-- Friend conversations indexes
CREATE INDEX IF NOT EXISTS idx_friend_conversations_user1 ON friend_conversations(user1_id);
CREATE INDEX IF NOT EXISTS idx_friend_conversations_user2 ON friend_conversations(user2_id);
CREATE INDEX IF NOT EXISTS idx_friend_conversations_updated ON friend_conversations(updated_at DESC);

-- Friend messages indexes
CREATE INDEX IF NOT EXISTS idx_friend_messages_conversation ON friend_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_friend_messages_sender ON friend_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_friend_messages_created ON friend_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_friend_messages_unread ON friend_messages(conversation_id, is_read) WHERE is_read = FALSE;

-- Friend requests indexes
CREATE INDEX IF NOT EXISTS idx_friend_requests_requester ON friend_requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_friend_requests_target ON friend_requests(target_id);
CREATE INDEX IF NOT EXISTS idx_friend_requests_status ON friend_requests(status);

-- Notifications indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(created_at DESC);

-- =====================================================
-- STEP 3: CREATE TRIGGERS FOR AUTOMATIC UPDATES
-- =====================================================

-- Update friend_conversations.updated_at when messages are added
CREATE OR REPLACE FUNCTION update_conversation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE friend_conversations 
    SET updated_at = NOW() 
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_conversation_timestamp ON friend_messages;
CREATE TRIGGER trigger_update_conversation_timestamp
    AFTER INSERT ON friend_messages
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_timestamp();

-- =====================================================
-- STEP 4: ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE friend_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE friend_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE friend_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocked_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Friend conversations policies
DROP POLICY IF EXISTS "Users can view their own conversations" ON friend_conversations;
CREATE POLICY "Users can view their own conversations" ON friend_conversations
    FOR SELECT USING (
        user1_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()) OR 
        user2_id = (SELECT id FROM users WHERE auth_user_id = auth.uid())
    );

-- Friend messages policies
DROP POLICY IF EXISTS "Users can view messages in their conversations" ON friend_messages;
CREATE POLICY "Users can view messages in their conversations" ON friend_messages
    FOR SELECT USING (
        conversation_id IN (
            SELECT id FROM friend_conversations 
            WHERE user1_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()) OR 
                  user2_id = (SELECT id FROM users WHERE auth_user_id = auth.uid())
        )
    );

DROP POLICY IF EXISTS "Users can send messages in their conversations" ON friend_messages;
CREATE POLICY "Users can send messages in their conversations" ON friend_messages
    FOR INSERT WITH CHECK (
        sender_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()) AND
        conversation_id IN (
            SELECT id FROM friend_conversations 
            WHERE user1_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()) OR 
                  user2_id = (SELECT id FROM users WHERE auth_user_id = auth.uid())
        )
    );

-- Friend requests policies
DROP POLICY IF EXISTS "Users can view their friend requests" ON friend_requests;
CREATE POLICY "Users can view their friend requests" ON friend_requests
    FOR SELECT USING (
        requester_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()) OR 
        target_id = (SELECT id FROM users WHERE auth_user_id = auth.uid())
    );

DROP POLICY IF EXISTS "Users can send friend requests" ON friend_requests;
CREATE POLICY "Users can send friend requests" ON friend_requests
    FOR INSERT WITH CHECK (requester_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

DROP POLICY IF EXISTS "Users can update their friend requests" ON friend_requests;
CREATE POLICY "Users can update their friend requests" ON friend_requests
    FOR UPDATE USING (
        requester_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()) OR 
        target_id = (SELECT id FROM users WHERE auth_user_id = auth.uid())
    );

-- Notifications policies
DROP POLICY IF EXISTS "Users can view their own notifications" ON notifications;
CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT USING (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

DROP POLICY IF EXISTS "Users can update their own notifications" ON notifications;
CREATE POLICY "Users can update their own notifications" ON notifications
    FOR UPDATE USING (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

DROP POLICY IF EXISTS "Users can delete their own notifications" ON notifications;
CREATE POLICY "Users can delete their own notifications" ON notifications
    FOR DELETE USING (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Show created tables
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'friend_conversations', 'friend_messages', 'friend_requests', 
    'blocked_users', 'notifications'
)
ORDER BY table_name;

-- Show indexes
SELECT 
    indexname,
    tablename
FROM pg_indexes 
WHERE schemaname = 'public' 
AND tablename IN (
    'friend_conversations', 'friend_messages', 'friend_requests', 
    'blocked_users', 'notifications'
)
ORDER BY tablename, indexname;
