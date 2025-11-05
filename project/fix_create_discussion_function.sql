-- Fix Create Discussion Function
-- This script creates the missing create_discussion database function
-- that allows users to create new discussions

-- ===========================================
-- STEP 1: DROP EXISTING FUNCTION (if any)
-- ===========================================

DROP FUNCTION IF EXISTS create_discussion(UUID, TEXT, TEXT, TEXT, TEXT, TEXT[]);

-- ===========================================
-- STEP 2: CREATE CREATE_DISCUSSION FUNCTION
-- ===========================================

-- Create discussion function that matches what the frontend expects
CREATE OR REPLACE FUNCTION create_discussion(
    auth_user_id UUID,
    discussion_title TEXT,
    discussion_content TEXT,
    book_title TEXT DEFAULT NULL,
    book_author TEXT DEFAULT NULL,
    tags TEXT[] DEFAULT '{}'
)
RETURNS JSONB AS $$
DECLARE
    user_internal_id UUID;
    new_discussion_id UUID;
    creator_name TEXT;
    creator_username TEXT;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Get creator name and username
    SELECT u.name, u.username INTO creator_name, creator_username
    FROM users u
    WHERE u.id = user_internal_id;
    
    -- Create the discussion
    INSERT INTO discussions (
        title,
        content,
        book_title,
        book_author,
        tags,
        created_by,
        created_at,
        updated_at
    )
    VALUES (
        discussion_title,
        discussion_content,
        book_title,
        book_author,
        COALESCE(tags, '{}'),
        user_internal_id,
        NOW(),
        NOW()
    )
    RETURNING id INTO new_discussion_id;
    
    -- Add creator as admin member of the discussion
    INSERT INTO discussion_members (
        discussion_id,
        user_id,
        role,
        joined_at
    )
    VALUES (
        new_discussion_id,
        user_internal_id,
        'admin',
        NOW()
    )
    ON CONFLICT (discussion_id, user_id) DO NOTHING;
    
    -- Return the created discussion as JSONB
    RETURN (
        SELECT jsonb_build_object(
            'id', d.id::TEXT,
            'title', d.title,
            'content', d.content,
            'bookTitle', d.book_title,
            'bookAuthor', d.book_author,
            'tags', COALESCE(d.tags, '{}'),
            'createdBy', d.created_by::TEXT,
            'createdAt', d.created_at::TEXT,
            'participantCount', (SELECT COUNT(*)::INTEGER FROM discussion_members dm WHERE dm.discussion_id = d.id),
            'lastActivity', COALESCE(
                (SELECT MAX(dm.created_at) FROM discussion_messages dm WHERE dm.discussion_id = d.id),
                d.created_at
            )::TEXT,
            'isParticipant', TRUE,
            'creatorName', creator_name,
            'creatorUsername', creator_username,
            'isCreatedByUser', TRUE
        )
        FROM discussions d
        WHERE d.id = new_discussion_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- STEP 3: GRANT PERMISSIONS
-- ===========================================

GRANT EXECUTE ON FUNCTION create_discussion(UUID, TEXT, TEXT, TEXT, TEXT, TEXT[]) TO authenticated;
GRANT EXECUTE ON FUNCTION create_discussion(UUID, TEXT, TEXT, TEXT, TEXT, TEXT[]) TO anon;

-- ===========================================
-- STEP 4: VERIFY FUNCTION CREATION
-- ===========================================

SELECT 
    '=== CREATE_DISCUSSION FUNCTION CREATED ===' as header,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name = 'create_discussion';

SELECT '=== CREATE_DISCUSSION FUNCTION FIX COMPLETE ===' as header;

