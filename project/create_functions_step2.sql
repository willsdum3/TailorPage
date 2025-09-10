-- Step 2: Create get_book_club_members function
CREATE OR REPLACE FUNCTION get_book_club_members(
    auth_user_id UUID,
    club_id_param UUID
)
RETURNS TABLE (
    user_id UUID,
    username TEXT,
    name TEXT,
    avatar_url TEXT,
    role TEXT,
    joined_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id as user_id,
        u.username,
        u.name,
        u.avatar_url,
        cm.role,
        cm.joined_at
    FROM club_memberships cm
    JOIN users u ON cm.user_id = u.id
    WHERE cm.club_id = get_book_club_members.club_id_param
    ORDER BY cm.joined_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permission for get_book_club_members
GRANT EXECUTE ON FUNCTION get_book_club_members(UUID, UUID) TO authenticated;
