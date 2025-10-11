-- Fix Discussion Membership Issues
-- The problem is that users aren't being added to discussion_members table

-- First, let's check what discussion-related functions exist
SELECT 
    'Existing Discussion Functions' as check_type,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name LIKE '%discussion%'
ORDER BY routine_name;

-- Check if discussion_members table exists and its structure
SELECT 
    'Discussion Members Table Structure' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'discussion_members' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check if discussions table exists and its structure
SELECT 
    'Discussions Table Structure' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'discussions' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Create discussion_members table if it doesn't exist
CREATE TABLE IF NOT EXISTS discussion_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    discussion_id UUID NOT NULL,
    user_id UUID NOT NULL,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(discussion_id, user_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_discussion_members_discussion_id ON discussion_members(discussion_id);
CREATE INDEX IF NOT EXISTS idx_discussion_members_user_id ON discussion_members(user_id);

-- Add foreign key constraints if they don't exist
DO $$
BEGIN
    -- Add foreign key to discussions table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_discussion_members_discussion_id'
        AND table_name = 'discussion_members'
    ) THEN
        ALTER TABLE discussion_members 
        ADD CONSTRAINT fk_discussion_members_discussion_id 
        FOREIGN KEY (discussion_id) REFERENCES discussions(id) ON DELETE CASCADE;
    END IF;
    
    -- Add foreign key to users table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_discussion_members_user_id'
        AND table_name = 'discussion_members'
    ) THEN
        ALTER TABLE discussion_members 
        ADD CONSTRAINT fk_discussion_members_user_id 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Enable RLS on discussion_members if not already enabled
ALTER TABLE discussion_members ENABLE ROW LEVEL SECURITY;

-- Drop existing policies and recreate them
DROP POLICY IF EXISTS "Users can view discussion members" ON discussion_members;
DROP POLICY IF EXISTS "Users can join discussions" ON discussion_members;

-- Create RLS policies for discussion_members
CREATE POLICY "Users can view discussion members" ON discussion_members
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM discussion_members dm
            JOIN users u ON dm.user_id = u.id
            WHERE dm.discussion_id = discussion_members.discussion_id
            AND u.auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can join discussions" ON discussion_members
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users u
            WHERE u.id = discussion_members.user_id
            AND u.auth_user_id = auth.uid()
        )
    );

-- Create or update the create_discussion function
DROP FUNCTION IF EXISTS create_discussion(UUID, TEXT, TEXT, TEXT, TEXT, TEXT[]) CASCADE;

CREATE OR REPLACE FUNCTION create_discussion(
    auth_user_id UUID,
    discussion_title TEXT,
    discussion_content TEXT,
    book_title TEXT DEFAULT NULL,
    book_author TEXT DEFAULT NULL,
    discussion_tags TEXT[] DEFAULT '{}'
)
RETURNS JSONB AS $$
DECLARE
    user_internal_id UUID;
    discussion_id UUID;
    discussion_result JSONB;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Create the discussion
    INSERT INTO discussions (title, content, book_title, book_author, tags, created_by, created_at)
    VALUES (discussion_title, discussion_content, book_title, book_author, discussion_tags, user_internal_id, NOW())
    RETURNING id INTO discussion_id;
    
    -- Add the creator as a member of the discussion
    INSERT INTO discussion_members (discussion_id, user_id, joined_at)
    VALUES (discussion_id, user_internal_id, NOW())
    ON CONFLICT (discussion_id, user_id) DO NOTHING;
    
    -- Return the created discussion
    SELECT jsonb_build_object(
        'id', d.id,
        'title', d.title,
        'content', d.content,
        'bookTitle', d.book_title,
        'bookAuthor', d.book_author,
        'tags', d.tags,
        'createdBy', d.created_by,
        'createdAt', d.created_at,
        'participantCount', 1,
        'lastActivity', d.created_at,
        'isParticipant', true,
        'creatorName', u.name,
        'creatorUsername', u.username,
        'isCreatedByUser', true
    ) INTO discussion_result
    FROM discussions d
    JOIN users u ON d.created_by = u.id
    WHERE d.id = discussion_id;
    
    RETURN discussion_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create or update the join_discussion function
DROP FUNCTION IF EXISTS join_discussion(UUID, UUID) CASCADE;

CREATE OR REPLACE FUNCTION join_discussion(
    auth_user_id UUID,
    discussion_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Add user to discussion members
    INSERT INTO discussion_members (discussion_id, user_id, joined_at)
    VALUES (discussion_id, user_internal_id, NOW())
    ON CONFLICT (discussion_id, user_id) DO NOTHING;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update the add_discussion_message function to be more lenient with membership checks
DROP FUNCTION IF EXISTS add_discussion_message(UUID, UUID, TEXT) CASCADE;

CREATE OR REPLACE FUNCTION add_discussion_message(
    auth_user_id UUID,
    discussion_id UUID,
    message_content TEXT
)
RETURNS UUID AS $$
DECLARE
    user_internal_id UUID;
    message_id UUID;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if user is a member of the discussion OR is the creator
    IF NOT EXISTS (
        SELECT 1 FROM discussion_members dm
        WHERE dm.discussion_id = add_discussion_message.discussion_id 
        AND dm.user_id = user_internal_id
    ) AND NOT EXISTS (
        SELECT 1 FROM discussions d
        WHERE d.id = add_discussion_message.discussion_id
        AND d.created_by = user_internal_id
    ) THEN
        -- If user is not a member and not the creator, add them as a member automatically
        INSERT INTO discussion_members (discussion_id, user_id, joined_at)
        VALUES (add_discussion_message.discussion_id, user_internal_id, NOW())
        ON CONFLICT (discussion_id, user_id) DO NOTHING;
    END IF;
    
    -- Insert the message
    INSERT INTO discussion_messages (discussion_id, user_id, message, created_at)
    VALUES (add_discussion_message.discussion_id, user_internal_id, add_discussion_message.message_content, NOW())
    RETURNING id INTO message_id;
    
    -- Create notification for other members (if function exists)
    BEGIN
        PERFORM create_discussion_message_notification(
            add_discussion_message.discussion_id,
            user_internal_id,
            add_discussion_message.message_content
        );
    EXCEPTION
        WHEN OTHERS THEN
            -- Log the error but don't fail the main operation
            RAISE NOTICE 'Failed to create discussion message notification: %', SQLERRM;
    END;
    
    RETURN message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the functions
DO $$
DECLARE
    test_user_id UUID;
    test_discussion_id UUID;
    message_id UUID;
BEGIN
    -- Get test data if available
    SELECT u.auth_user_id INTO test_user_id FROM users u LIMIT 1;
    SELECT d.id INTO test_discussion_id FROM discussions d LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_discussion_id IS NOT NULL THEN
        BEGIN
            -- Test the add_discussion_message function
            message_id := add_discussion_message(test_user_id, test_discussion_id, 'Test message with membership fix');
            RAISE NOTICE '✅ add_discussion_message test successful with membership fix, message_id: %', message_id;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE '❌ Function test failed: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE '⚠️ No test data available for function test';
    END IF;
END $$;

-- Show the final function verification
SELECT 
    'Final Function Verification' as check_type,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name IN ('create_discussion', 'join_discussion', 'add_discussion_message')
ORDER BY routine_name;
