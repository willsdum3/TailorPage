-- Step 3: Create add_book_club_message function
CREATE OR REPLACE FUNCTION add_book_club_message(
    auth_user_id UUID,
    club_id_param UUID,
    content_param TEXT
)
RETURNS TABLE (
    id UUID,
    club_id UUID,
    user_id UUID,
    content TEXT,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    user_uuid UUID;
    new_message_id UUID;
BEGIN
    -- Get user UUID
    SELECT u.id INTO user_uuid 
    FROM users u 
    WHERE u.auth_user_id = add_book_club_message.auth_user_id;
    
    -- If user not found, return empty
    IF user_uuid IS NULL THEN
        RETURN;
    END IF;
    
    -- Insert message
    INSERT INTO book_club_messages (club_id, user_id, content)
    VALUES (add_book_club_message.club_id_param, user_uuid, add_book_club_message.content_param)
    RETURNING book_club_messages.id INTO new_message_id;
    
    -- Return the new message
    RETURN QUERY
    SELECT 
        bcm.id,
        bcm.club_id,
        bcm.user_id,
        bcm.content,
        bcm.created_at
    FROM book_club_messages bcm
    WHERE bcm.id = new_message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permission for add_book_club_message
GRANT EXECUTE ON FUNCTION add_book_club_message(UUID, UUID, TEXT) TO authenticated;
