-- Fix book recommendations and messaging functions
-- This script adds the missing send_book_recommendation function and fixes send_friend_message

-- Drop existing functions to avoid conflicts
DROP FUNCTION IF EXISTS send_book_recommendation(uuid,uuid,text,text,text,text,text);
DROP FUNCTION IF EXISTS send_friend_message(uuid,uuid,text);

-- First, let's fix the send_friend_message function to actually insert messages
CREATE OR REPLACE FUNCTION send_friend_message(
    p_auth_user_id UUID,
    p_friend_id UUID,
    p_content TEXT
) RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_user_name TEXT;
    v_user_username TEXT;
    v_user_avatar_url TEXT;
    v_conversation_id UUID;
    v_message_id UUID;
    v_result JSONB;
BEGIN
    -- Get user details
    SELECT id, name, username, avatar_url INTO v_user_id, v_user_name, v_user_username, v_user_avatar_url
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Create a consistent conversation ID based on the two user IDs
    v_conversation_id := md5(LEAST(v_user_id, p_friend_id)::text || GREATEST(v_user_id, p_friend_id)::text)::uuid;
    
    -- Ensure conversation exists
    INSERT INTO friend_conversations (id, user1_id, user2_id, created_at, updated_at)
    VALUES (v_conversation_id, LEAST(v_user_id, p_friend_id), GREATEST(v_user_id, p_friend_id), NOW(), NOW())
    ON CONFLICT (id) DO NOTHING;
    
    -- Generate a message ID
    v_message_id := gen_random_uuid();
    
    -- Insert the message
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
    
    -- Return success response with message data
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

-- Add the missing send_book_recommendation function
CREATE OR REPLACE FUNCTION send_book_recommendation(
    p_auth_user_id UUID,
    p_friend_id UUID,
    p_book_title TEXT,
    p_book_author TEXT,
    p_description TEXT DEFAULT NULL,
    p_amazon_url TEXT DEFAULT NULL,
    p_cover_image_url TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_user_name TEXT;
    v_user_username TEXT;
    v_user_avatar_url TEXT;
    v_conversation_id UUID;
    v_message_id UUID;
    v_book_data JSONB;
    v_result JSONB;
BEGIN
    -- Get user details
    SELECT id, name, username, avatar_url INTO v_user_id, v_user_name, v_user_username, v_user_avatar_url
    FROM users 
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Create a consistent conversation ID based on the two user IDs
    v_conversation_id := md5(LEAST(v_user_id, p_friend_id)::text || GREATEST(v_user_id, p_friend_id)::text)::uuid;
    
    -- Ensure conversation exists
    INSERT INTO friend_conversations (id, user1_id, user2_id, created_at, updated_at)
    VALUES (v_conversation_id, LEAST(v_user_id, p_friend_id), GREATEST(v_user_id, p_friend_id), NOW(), NOW())
    ON CONFLICT (id) DO NOTHING;
    
    -- Generate a message ID
    v_message_id := gen_random_uuid();
    
    -- Build book recommendation data
    v_book_data := jsonb_build_object(
        'title', p_book_title,
        'author', p_book_author,
        'description', p_description,
        'amazonUrl', p_amazon_url,
        'coverImageUrl', p_cover_image_url
    );
    
    -- Insert the book recommendation message
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
        'Recommended: ' || p_book_title || ' by ' || p_book_author,
        'book_recommendation',
        v_book_data,
        NOW(),
        false
    );
    
    -- Return success response with message data
    v_result := jsonb_build_object(
        'success', true,
        'message', jsonb_build_object(
            'id', v_message_id,
            'conversationId', v_conversation_id,
            'senderId', v_user_id,
            'senderName', v_user_name,
            'senderUsername', v_user_username,
            'senderImageUrl', v_user_avatar_url,
            'content', 'Recommended: ' || p_book_title || ' by ' || p_book_author,
            'messageType', 'book_recommendation',
            'bookRecommendation', v_book_data,
            'createdAt', NOW(),
            'isEdited', false
        )
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the functions
SELECT 'Book recommendation function created successfully' as status;
