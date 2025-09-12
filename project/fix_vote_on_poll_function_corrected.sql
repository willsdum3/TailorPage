-- Fix the vote_on_poll function to handle JSON string options properly
-- The issue is that options might be stored as a JSON string instead of JSONB array
-- Also fix the boolean comparison issue with status field

CREATE OR REPLACE FUNCTION vote_on_poll(
    auth_user_id UUID,
    poll_id_param UUID,
    option_index INTEGER
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    user_uuid UUID;
    poll_exists BOOLEAN;
    poll_status TEXT;
    poll_options JSONB;
    option_count INTEGER;
BEGIN
    -- Get user UUID
    SELECT u.id INTO user_uuid 
    FROM users u 
    WHERE u.auth_user_id = vote_on_poll.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RETURN QUERY SELECT false, 'User not found';
        RETURN;
    END IF;
    
    -- Check if poll exists and get status and options
    SELECT EXISTS(SELECT 1 FROM book_club_polls WHERE id = poll_id_param) INTO poll_exists;
    IF NOT poll_exists THEN
        RETURN QUERY SELECT false, 'Poll not found';
        RETURN;
    END IF;
    
    -- Get poll status and options
    SELECT status, options INTO poll_status, poll_options
    FROM book_club_polls 
    WHERE id = poll_id_param;
    
    -- Check if poll is active (status is a string, not boolean)
    IF poll_status IS NULL OR poll_status != 'active' THEN
        RETURN QUERY SELECT false, 'Poll is not active';
        RETURN;
    END IF;
    
    -- Handle options - they might be stored as JSON string or JSONB
    IF poll_options IS NULL THEN
        RETURN QUERY SELECT false, 'Poll has no options';
        RETURN;
    END IF;
    
    -- Convert to JSONB if it's a string, or use as-is if it's already JSONB
    IF jsonb_typeof(poll_options) = 'string' THEN
        poll_options := poll_options::text::jsonb;
    END IF;
    
    -- Check if it's an array
    IF jsonb_typeof(poll_options) != 'array' THEN
        RETURN QUERY SELECT false, 'Poll options are not in array format';
        RETURN;
    END IF;
    
    -- Get option count
    option_count := jsonb_array_length(poll_options);
    
    -- Check if option index is valid
    IF option_index < 0 OR option_index >= option_count THEN
        RETURN QUERY SELECT false, 'Invalid option selected';
        RETURN;
    END IF;
    
    -- Insert or update vote
    INSERT INTO book_club_poll_votes (poll_id, user_id, option_index)
    VALUES (poll_id_param, user_uuid, option_index)
    ON CONFLICT (poll_id, user_id)
    DO UPDATE SET option_index = EXCLUDED.option_index, created_at = NOW();
    
    RETURN QUERY SELECT true, 'Vote recorded successfully';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION vote_on_poll(UUID, UUID, INTEGER) TO authenticated;
