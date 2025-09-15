-- Add function to toggle book club public/private status
-- This allows admins to change the visibility of their book clubs

CREATE OR REPLACE FUNCTION toggle_book_club_visibility(
    auth_user_id UUID,
    club_id_param UUID,
    is_public_param BOOLEAN
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    user_uuid UUID;
    is_admin BOOLEAN;
BEGIN
    -- Get user UUID
    SELECT u.id INTO user_uuid 
    FROM users u 
    WHERE u.auth_user_id = toggle_book_club_visibility.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RETURN QUERY SELECT false, 'User not found';
        RETURN;
    END IF;
    
    -- Check if user is admin of the club
    SELECT EXISTS(
        SELECT 1 FROM club_memberships 
        WHERE club_id = club_id_param 
        AND user_id = user_uuid
        AND role = 'admin'
    ) INTO is_admin;
    
    IF NOT is_admin THEN
        RETURN QUERY SELECT false, 'Only admins can change club visibility';
        RETURN;
    END IF;
    
    -- Update the club's public/private status
    UPDATE book_clubs 
    SET is_public = is_public_param, updated_at = NOW()
    WHERE id = club_id_param;
    
    IF FOUND THEN
        RETURN QUERY SELECT true, 
            CASE 
                WHEN is_public_param THEN 'Club is now public'
                ELSE 'Club is now private'
            END;
    ELSE
        RETURN QUERY SELECT false, 'Club not found';
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION toggle_book_club_visibility(UUID, UUID, BOOLEAN) TO authenticated;
