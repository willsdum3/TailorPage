-- Fix the ambiguous created_at column reference in get_discussions function
-- This resolves the "column reference 'created_at' is ambiguous" error

-- Drop and recreate the get_discussions function with explicit column references
DROP FUNCTION IF EXISTS get_discussions(UUID);

CREATE OR REPLACE FUNCTION get_discussions(auth_user_id UUID)
RETURNS TABLE (
    id UUID,
    title TEXT,
    content TEXT,
    book_title TEXT,
    book_author TEXT,
    tags TEXT[],
    created_by UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    message_count BIGINT,
    participant_count BIGINT,
    is_participant BOOLEAN,
    last_message_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    user_uuid UUID;
BEGIN
    -- Get user UUID from auth_user_id
    SELECT u.id INTO user_uuid 
    FROM users u 
    WHERE u.auth_user_id = get_discussions.auth_user_id;
    
    -- If user not found, return empty result
    IF user_uuid IS NULL THEN
        RETURN;
    END IF;
    
    RETURN QUERY
    SELECT 
        d.id,
        d.title,
        d.content,
        d.book_title,
        d.book_author,
        d.tags,
        d.created_by,
        d.created_at,
        d.updated_at,
        COALESCE(dm.message_count, 0) as message_count,
        COALESCE(dp.participant_count, 0) as participant_count,
        CASE WHEN dp.is_participant THEN true ELSE false END as is_participant,
        COALESCE(dm.last_message_at, d.created_at) as last_message_at
    FROM discussions d
    LEFT JOIN (
        SELECT 
            discussion_id,
            COUNT(*) as message_count,
            MAX(discussion_messages.created_at) as last_message_at
        FROM discussion_messages 
        GROUP BY discussion_id
    ) dm ON d.id = dm.discussion_id
    LEFT JOIN (
        SELECT 
            discussion_id,
            COUNT(*) as participant_count,
            bool_or(user_id = user_uuid) as is_participant
        FROM discussion_participants 
        GROUP BY discussion_id
    ) dp ON d.id = dp.discussion_id
    ORDER BY COALESCE(dm.last_message_at, d.created_at) DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_discussions(UUID) TO authenticated;
