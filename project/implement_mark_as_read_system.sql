-- Implement mark as read functionality for friend conversations
-- This will create a simple system to track when users last viewed conversations

-- Create a table to track when users last read conversations
CREATE TABLE IF NOT EXISTS user_conversation_reads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    conversation_id UUID NOT NULL,
    last_read_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, conversation_id)
);

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_user_conversation_reads_user_conversation 
ON user_conversation_reads(user_id, conversation_id);

-- Enable RLS
ALTER TABLE user_conversation_reads ENABLE ROW LEVEL SECURITY;

-- Create RLS policy - users can only see their own read status
CREATE POLICY "Users can view their own conversation reads" ON user_conversation_reads
    FOR SELECT USING (user_id = auth.uid()::uuid);

CREATE POLICY "Users can insert their own conversation reads" ON user_conversation_reads
    FOR INSERT WITH CHECK (user_id = auth.uid()::uuid);

CREATE POLICY "Users can update their own conversation reads" ON user_conversation_reads
    FOR UPDATE USING (user_id = auth.uid()::uuid);

-- Function to mark a conversation as read
CREATE OR REPLACE FUNCTION mark_conversation_as_read(
    p_auth_user_id UUID,
    p_conversation_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_result JSONB;
BEGIN
    -- Get the user ID from auth_user_id
    SELECT users.id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Insert or update the read timestamp
    INSERT INTO user_conversation_reads (user_id, conversation_id, last_read_at)
    VALUES (v_user_id, p_conversation_id, NOW())
    ON CONFLICT (user_id, conversation_id) 
    DO UPDATE SET 
        last_read_at = NOW(),
        updated_at = NOW();
    
    v_result := jsonb_build_object(
        'success', true,
        'message', 'Conversation marked as read',
        'last_read_at', NOW()
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update the get_friend_conversations function to use proper unread count
DROP FUNCTION IF EXISTS get_friend_conversations(UUID);

CREATE OR REPLACE FUNCTION get_friend_conversations(
    p_auth_user_id UUID
) RETURNS TABLE(
    id UUID,
    friend_id UUID,
    friend_name TEXT,
    friend_username TEXT,
    friend_image_url TEXT,
    last_message TEXT,
    last_message_at TIMESTAMP WITH TIME ZONE,
    unread_count INTEGER,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Get the user ID from auth_user_id
    SELECT users.id INTO v_user_id
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Return conversations from friend_requests with proper unread count
    RETURN QUERY
    SELECT DISTINCT
        -- Use the same conversation ID generation as messaging functions
        md5(LEAST(fr.requester_id, fr.target_id)::text || GREATEST(fr.requester_id, fr.target_id)::text)::uuid as id,
        CASE 
            WHEN fr.requester_id = v_user_id THEN fr.target_id 
            ELSE fr.requester_id 
        END as friend_id,
        CASE 
            WHEN fr.requester_id = v_user_id THEN u2.name 
            ELSE u1.name 
        END as friend_name,
        CASE 
            WHEN fr.requester_id = v_user_id THEN u2.username 
            ELSE u1.username 
        END as friend_username,
        CASE 
            WHEN fr.requester_id = v_user_id THEN u2.avatar_url 
            ELSE u1.avatar_url 
        END as friend_image_url,
        COALESCE(
            (SELECT fm.content 
             FROM friend_messages fm 
             WHERE fm.conversation_id = md5(LEAST(fr.requester_id, fr.target_id)::text || GREATEST(fr.requester_id, fr.target_id)::text)::uuid
             ORDER BY fm.created_at DESC 
             LIMIT 1),
            'No messages yet'
        ) as last_message,
        COALESCE(
            (SELECT fm.created_at 
             FROM friend_messages fm 
             WHERE fm.conversation_id = md5(LEAST(fr.requester_id, fr.target_id)::text || GREATEST(fr.requester_id, fr.target_id)::text)::uuid
             ORDER BY fm.created_at DESC 
             LIMIT 1),
            fr.created_at
        ) as last_message_at,
        -- Proper unread count using the read tracking table
        COALESCE(
            (SELECT COUNT(*)::INTEGER 
             FROM friend_messages fm 
             WHERE fm.conversation_id = md5(LEAST(fr.requester_id, fr.target_id)::text || GREATEST(fr.requester_id, fr.target_id)::text)::uuid
             AND fm.sender_id != v_user_id
             AND fm.created_at > COALESCE(
                 (SELECT ucr.last_read_at 
                  FROM user_conversation_reads ucr 
                  WHERE ucr.user_id = v_user_id 
                  AND ucr.conversation_id = md5(LEAST(fr.requester_id, fr.target_id)::text || GREATEST(fr.requester_id, fr.target_id)::text)::uuid),
                 '1970-01-01'::timestamp
             )),
            0
        ) as unread_count,
        fr.created_at
    FROM friend_requests fr
    LEFT JOIN users u1 ON fr.requester_id = u1.id
    LEFT JOIN users u2 ON fr.target_id = u2.id
    WHERE (fr.requester_id = v_user_id OR fr.target_id = v_user_id)
    AND fr.status = 'accepted'
    ORDER BY fr.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
