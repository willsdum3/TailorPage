-- Step 4: Create get_book_club_messages function
CREATE OR REPLACE FUNCTION get_book_club_messages(
    auth_user_id UUID,
    club_id_param UUID
)
RETURNS TABLE (
    id UUID,
    club_id UUID,
    user_id UUID,
    content TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    username TEXT,
    name TEXT,
    avatar_url TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        bcm.id,
        bcm.club_id,
        bcm.user_id,
        bcm.content,
        bcm.created_at,
        u.username,
        u.name,
        u.avatar_url
    FROM book_club_messages bcm
    JOIN users u ON bcm.user_id = u.id
    WHERE bcm.club_id = get_book_club_messages.club_id_param
    ORDER BY bcm.created_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permission for get_book_club_messages
GRANT EXECUTE ON FUNCTION get_book_club_messages(UUID, UUID) TO authenticated;
