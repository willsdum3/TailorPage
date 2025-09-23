-- Fix the foreign key constraint issue in friend_messages table
-- This script addresses the conversation_id foreign key constraint violation

-- First, let's check the current table structure and constraints
SELECT 
    'FOREIGN KEY CONSTRAINTS' as info,
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name = 'friend_messages';

-- Check if friend_conversations table exists and has data
SELECT 
    'FRIEND_CONVERSATIONS TABLE' as info,
    COUNT(*) as conversation_count
FROM friend_conversations;

-- Check the structure of friend_conversations table
SELECT 
    'FRIEND_CONVERSATIONS STRUCTURE' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'friend_conversations'
ORDER BY ordinal_position;

-- Option 1: Drop the foreign key constraint (if we want to use MD5-generated conversation IDs)
-- Uncomment the following lines if you want to remove the constraint:
/*
ALTER TABLE friend_messages 
DROP CONSTRAINT IF EXISTS friend_messages_conversation_id_fkey;
*/

-- Option 2: Create a function that ensures conversation exists before sending message
-- This is the recommended approach - it will create the conversation if it doesn't exist

CREATE OR REPLACE FUNCTION ensure_conversation_exists(
    p_user1_id UUID,
    p_user2_id UUID
) RETURNS UUID AS $$
DECLARE
    v_conversation_id UUID;
    v_user1_id UUID;
    v_user2_id UUID;
BEGIN
    -- Ensure consistent ordering (user1_id < user2_id)
    v_user1_id := LEAST(p_user1_id, p_user2_id);
    v_user2_id := GREATEST(p_user1_id, p_user2_id);
    
    -- Generate consistent conversation ID
    v_conversation_id := md5(v_user1_id::text || v_user2_id::text)::uuid;
    
    -- Check if conversation exists, if not create it
    INSERT INTO friend_conversations (
        id,
        user1_id,
        user2_id,
        created_at,
        updated_at
    ) VALUES (
        v_conversation_id,
        v_user1_id,
        v_user2_id,
        NOW(),
        NOW()
    ) ON CONFLICT (id) DO NOTHING;
    
    RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update the send_friend_message function to use this helper
DROP FUNCTION IF EXISTS send_friend_message(UUID, UUID, TEXT);

CREATE OR REPLACE FUNCTION send_friend_message(
    p_auth_user_id UUID,
    p_friend_id UUID,
    p_content TEXT
) RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_message_id UUID;
    v_conversation_id UUID;
    v_user_name TEXT;
    v_user_username TEXT;
    v_user_avatar_url TEXT;
    v_result JSONB;
BEGIN
    -- Get the user ID from auth_user_id
    SELECT users.id, users.name, users.username, users.avatar_url 
    INTO v_user_id, v_user_name, v_user_username, v_user_avatar_url
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Ensure conversation exists and get its ID
    v_conversation_id := ensure_conversation_exists(v_user_id, p_friend_id);
    
    -- Generate a message ID
    v_message_id := gen_random_uuid();
    
    -- Insert the message into the database
    INSERT INTO friend_messages (
        id,
        conversation_id,
        sender_id,
        content,
        message_type,
        book_recommendation,
        created_at,
        is_edited
    ) VALUES (
        v_message_id,
        v_conversation_id,
        v_user_id,
        p_content,
        'text',
        NULL,
        NOW(),
        false
    );
    
    -- Return success response with the message data
    v_result := jsonb_build_object(
        'success', true,
        'message', jsonb_build_object(
            'id', v_message_id,
            'conversationId', v_conversation_id,
            'senderId', v_user_id,
            'senderName', v_user_name,
            'senderUsername', v_user_username,
            'senderImageUrl', v_user_avatar_url,
            'content', p_content,
            'messageType', 'text',
            'bookRecommendation', NULL,
            'createdAt', NOW(),
            'isEdited', false
        )
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
