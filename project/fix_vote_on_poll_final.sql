-- Final fix for vote_on_poll function
-- This version properly handles the string-to-JSONB conversion issue

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
    poll_options_raw TEXT; -- Raw options as they come from DB
    poll_options_jsonb JSONB; -- Converted to JSONB
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
    
    -- Get poll status and options as TEXT first
    SELECT status, options::TEXT INTO poll_status, poll_options_raw
    FROM book_club_polls 
    WHERE id = poll_id_param;
    
    -- Check if poll is active
    IF poll_status IS NULL OR poll_status != 'active' THEN
        RETURN QUERY SELECT false, 'Poll is not active';
        RETURN;
    END IF;
    
    -- Check if options exist
    IF poll_options_raw IS NULL OR poll_options_raw = '' THEN
        RETURN QUERY SELECT false, 'Poll has no options';
        RETURN;
    END IF;
    
    -- Convert options to JSONB and validate
    BEGIN
        poll_options_jsonb := poll_options_raw::JSONB;
        
        -- Check if it's an array
        IF jsonb_typeof(poll_options_jsonb) != 'array' THEN
            RETURN QUERY SELECT false, 'Poll options are not in array format. Type: ' || jsonb_typeof(poll_options_jsonb);
            RETURN;
        END IF;
        
        -- Get array length
        option_count := jsonb_array_length(poll_options_jsonb);
        
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT false, 'Poll options are not in valid JSON array format: ' || SQLERRM;
        RETURN;
    END;
    
    -- Check if option index is valid
    IF option_index < 0 OR option_index >= option_count THEN
        RETURN QUERY SELECT false, 'Invalid option selected. Valid range: 0 to ' || (option_count - 1);
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
