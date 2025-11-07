-- Fix/create create_book_selection_poll function so admins can create polls

DROP FUNCTION IF EXISTS create_book_selection_poll(
    UUID,
    UUID,
    TEXT,
    TEXT,
    JSONB,
    TIMESTAMP WITH TIME ZONE
);

CREATE OR REPLACE FUNCTION create_book_selection_poll(
    p_auth_user_id UUID,
    p_club_id UUID,
    p_poll_title TEXT,
    p_poll_description TEXT DEFAULT NULL,
    p_book_options JSONB DEFAULT '[]'::JSONB,
    p_closes_at TIMESTAMP WITH TIME ZONE DEFAULT NULL
)
RETURNS TABLE(success BOOLEAN, message TEXT, poll_id UUID) AS $$
DECLARE
    admin_internal_id UUID;
    is_admin BOOLEAN;
    new_poll_id UUID;
    options_array TEXT[] := ARRAY[]::TEXT[];
    option_count INTEGER := 0;
BEGIN
    -- Resolve internal user ID for the caller
    admin_internal_id := get_user_internal_id(p_auth_user_id);

    IF admin_internal_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'User not found', NULL;
        RETURN;
    END IF;

    -- Check admin/owner permissions for the club
    SELECT EXISTS (
        SELECT 1 FROM book_club_members
        WHERE club_id = p_club_id
          AND user_id = admin_internal_id
          AND role IN ('admin', 'owner')
    ) INTO is_admin;

    IF NOT is_admin THEN
        RETURN QUERY SELECT FALSE, 'You do not have permission to create polls for this club', NULL;
        RETURN;
    END IF;

    -- Ensure we have poll options JSON
    IF p_book_options IS NULL OR jsonb_typeof(p_book_options) IS DISTINCT FROM 'array' THEN
        p_book_options := '[]'::JSONB;
    END IF;

    -- Convert JSONB options to TEXT[] for storage (each entry as JSON string)
    SELECT array_agg(option_elem::text), COUNT(*)
    INTO options_array, option_count
    FROM jsonb_array_elements(p_book_options) AS option_elem;

    IF options_array IS NULL THEN
        options_array := ARRAY[]::TEXT[];
    END IF;

    IF option_count < 2 THEN
        RETURN QUERY SELECT FALSE, 'Please provide at least two book options', NULL;
        RETURN;
    END IF;

    -- Insert poll record
    INSERT INTO book_polls (
        club_id,
        created_by,
        title,
        description,
        book_options,
        closes_at,
        created_at
    ) VALUES (
        p_club_id,
        admin_internal_id,
        TRIM(BOTH FROM p_poll_title),
        NULLIF(TRIM(p_poll_description), ''),
        options_array,
        p_closes_at,
        NOW()
    ) RETURNING id INTO new_poll_id;

    RETURN QUERY SELECT TRUE, 'Poll created successfully', new_poll_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION create_book_selection_poll(UUID, UUID, TEXT, TEXT, JSONB, TIMESTAMP WITH TIME ZONE) TO authenticated;
GRANT EXECUTE ON FUNCTION create_book_selection_poll(UUID, UUID, TEXT, TEXT, JSONB, TIMESTAMP WITH TIME ZONE) TO anon;

SELECT 'create_book_selection_poll function created.' AS status;
