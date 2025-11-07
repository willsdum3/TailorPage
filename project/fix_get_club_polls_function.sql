-- Fix the get_club_polls function so polls include options and vote info

DROP FUNCTION IF EXISTS get_club_polls(UUID, UUID);

CREATE OR REPLACE FUNCTION get_club_polls(
    p_auth_user_id UUID,
    p_club_id UUID
)
RETURNS TABLE(
    id UUID,
    title TEXT,
    description TEXT,
    options JSONB,
    total_votes INTEGER,
    created_at TIMESTAMP WITH TIME ZONE,
    closes_at TIMESTAMP WITH TIME ZONE,
    created_by UUID,
    created_by_name TEXT,
    status TEXT,
    user_vote INTEGER,
    vote_counts JSONB
) AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    -- Resolve the current user's internal ID
    user_internal_id := get_user_internal_id(p_auth_user_id);

    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;

    -- Ensure the user is a member of the club
    IF NOT EXISTS (
        SELECT 1 FROM book_club_members bcm
        WHERE bcm.club_id = p_club_id
          AND bcm.user_id = user_internal_id
    ) THEN
        RAISE EXCEPTION 'User is not a member of this club';
    END IF;

    RETURN QUERY
    SELECT
        bp.id,
        bp.title,
        bp.description,
        COALESCE(
            (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'option_index', ord - 1,
                        'title', option_json->>'title',
                        'author', option_json->>'author',
                        'coverUrl', option_json->>'coverUrl',
                        'description', option_json->>'description'
                    ) ORDER BY ord
                )
                FROM unnest(COALESCE(bp.book_options, ARRAY[]::TEXT[]))
                     WITH ORDINALITY AS opt(option_text, ord)
                CROSS JOIN LATERAL (option_text::jsonb) AS option_json
            ),
            '[]'::jsonb
        ) AS options,
        COALESCE(bp.total_votes, 0) AS total_votes,
        bp.created_at,
        bp.closes_at,
        bp.created_by,
        COALESCE(creator.name, 'Unknown') AS created_by_name,
        bp.status,
        user_vote_table.option_index AS user_vote,
        COALESCE(vote_counts_table.vote_counts_json, '[]'::jsonb) AS vote_counts
    FROM book_polls bp
    LEFT JOIN users creator ON creator.id = bp.created_by
    LEFT JOIN LATERAL (
        SELECT option_index
        FROM book_votes
        WHERE poll_id = bp.id
          AND user_id = user_internal_id
        LIMIT 1
    ) user_vote_table ON TRUE
    LEFT JOIN LATERAL (
        SELECT jsonb_agg(
            jsonb_build_object(
                'option_index', vc.option_index,
                'vote_count', vc.vote_count
            ) ORDER BY vc.option_index
        ) AS vote_counts_json
        FROM (
            SELECT option_index, COUNT(*) AS vote_count
            FROM book_votes
            WHERE poll_id = bp.id
            GROUP BY option_index
        ) vc
    ) vote_counts_table ON TRUE
    WHERE bp.club_id = p_club_id
    ORDER BY bp.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_club_polls(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_club_polls(UUID, UUID) TO anon;

SELECT 'get_club_polls function updated.' AS status;
