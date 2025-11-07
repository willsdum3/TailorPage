-- Fix/create vote_on_poll function so members can vote without ambiguity

DROP FUNCTION IF EXISTS vote_on_poll(UUID, UUID, INTEGER);

CREATE OR REPLACE FUNCTION vote_on_poll(
    p_auth_user_id UUID,
    p_poll_id UUID,
    p_option_index INTEGER
)
RETURNS TABLE(success BOOLEAN, message TEXT) AS $$
DECLARE
    user_internal_id UUID;
    poll_record RECORD;
    is_member BOOLEAN;
BEGIN
    -- Get current user's internal ID
    user_internal_id := get_user_internal_id(p_auth_user_id);

    IF user_internal_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'User not found';
        RETURN;
    END IF;

    -- Get poll and ensure it exists
    SELECT * INTO poll_record
    FROM book_polls
    WHERE id = p_poll_id;

    IF poll_record IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Poll not found';
        RETURN;
    END IF;

    -- Ensure user is a member of the poll's club
    SELECT EXISTS (
        SELECT 1 FROM book_club_members
        WHERE club_id = poll_record.club_id
          AND user_id = user_internal_id
    ) INTO is_member;

    IF NOT is_member THEN
        RETURN QUERY SELECT FALSE, 'You are not a member of this club';
        RETURN;
    END IF;

    -- Ensure poll is active
    IF poll_record.status <> 'active' THEN
        RETURN QUERY SELECT FALSE, 'Poll is closed';
        RETURN;
    END IF;

    -- Validate option index
    IF poll_record.book_options IS NULL OR array_length(poll_record.book_options, 1) IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Poll has no options';
        RETURN;
    END IF;

    IF p_option_index < 0 OR p_option_index >= array_length(poll_record.book_options, 1) THEN
        RETURN QUERY SELECT FALSE, 'Invalid poll option';
        RETURN;
    END IF;

    -- Remove existing vote (if any)
    DELETE FROM book_votes
    WHERE poll_id = p_poll_id
      AND user_id = user_internal_id;

    -- Insert new vote
    INSERT INTO book_votes (poll_id, user_id, option_index)
    VALUES (p_poll_id, user_internal_id, p_option_index);

    -- Update total vote count
    UPDATE book_polls
    SET total_votes = (
        SELECT COUNT(*)
        FROM book_votes
        WHERE poll_id = p_poll_id
    )
    WHERE id = p_poll_id;

    RETURN QUERY SELECT TRUE, 'Vote recorded successfully';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION vote_on_poll(UUID, UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION vote_on_poll(UUID, UUID, INTEGER) TO anon;

SELECT 'vote_on_poll function created.' AS status;
