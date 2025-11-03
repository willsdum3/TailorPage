-- Create Missing Database Functions
-- This script creates all the missing functions that the frontend is trying to call

-- ===========================================
-- STEP 1: CREATE GET_CLUB_POLLS FUNCTION
-- ===========================================

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS get_club_polls(UUID, UUID);
DROP FUNCTION IF EXISTS get_club_polls(UUID);

-- Create get_club_polls function
CREATE OR REPLACE FUNCTION get_club_polls(
    p_auth_user_id UUID,
    p_club_id UUID
)
RETURNS TABLE(
    id UUID,
    title TEXT,
    description TEXT,
    book_options TEXT[],
    closes_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE,
    created_by UUID,
    total_votes INTEGER,
    user_vote INTEGER
) AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(p_auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if user is a member of the club
    IF NOT EXISTS (
        SELECT 1 FROM book_club_members bcm
        WHERE bcm.club_id = p_club_id 
        AND bcm.user_id = user_internal_id
    ) THEN
        RAISE EXCEPTION 'User is not a member of this club';
    END IF;
    
    -- Return polls for the club
    RETURN QUERY
    SELECT 
        bp.id,
        bp.title,
        bp.description,
        COALESCE(bp.book_options, ARRAY[]::TEXT[]) as book_options,
        bp.closes_at,
        bp.created_at,
        bp.created_by,
        COALESCE(bp.total_votes, 0) as total_votes,
        COALESCE(bv.option_index, -1) as user_vote
    FROM book_polls bp
    LEFT JOIN book_votes bv ON bp.id = bv.poll_id AND bv.user_id = user_internal_id
    WHERE bp.club_id = p_club_id
    ORDER BY bp.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- STEP 2: CREATE POLL MAINTENANCE FUNCTION
-- ===========================================

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS maintain_poll_hygiene();
DROP FUNCTION IF EXISTS maintain_poll_hygiene(UUID);

-- Create poll maintenance function
CREATE OR REPLACE FUNCTION maintain_poll_hygiene()
RETURNS JSONB AS $$
DECLARE
    closed_polls INTEGER := 0;
    deleted_polls INTEGER := 0;
BEGIN
    -- Close polls that have passed their closing time
    UPDATE book_polls 
    SET status = 'closed'
    WHERE status = 'active' 
    AND closes_at IS NOT NULL 
    AND closes_at < NOW();
    
    GET DIAGNOSTICS closed_polls = ROW_COUNT;
    
    -- Delete very old closed polls (older than 30 days)
    DELETE FROM book_polls 
    WHERE status = 'closed' 
    AND created_at < NOW() - INTERVAL '30 days';
    
    GET DIAGNOSTICS deleted_polls = ROW_COUNT;
    
    RETURN jsonb_build_object(
        'success', true,
        'closed_polls', closed_polls,
        'deleted_polls', deleted_polls,
        'message', 'Poll maintenance completed'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- STEP 3: CREATE FRIEND CONNECTIONS FUNCTION
-- ===========================================

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS get_friend_connections(UUID);
DROP FUNCTION IF EXISTS get_friend_connections(UUID, TEXT);

-- Create get_friend_connections function
CREATE OR REPLACE FUNCTION get_friend_connections(
    p_auth_user_id UUID
)
RETURNS TABLE(
    id UUID,
    user_id UUID,
    friend_id UUID,
    status TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    friend_name TEXT,
    friend_username TEXT,
    friend_email TEXT
) AS $$
DECLARE
    user_internal_id UUID;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(p_auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Return friend connections
    RETURN QUERY
    SELECT 
        fc.id,
        fc.user_id,
        fc.friend_id,
        fc.status,
        fc.created_at,
        u.name as friend_name,
        u.username as friend_username,
        u.email as friend_email
    FROM friend_connections fc
    JOIN users u ON fc.friend_id = u.id
    WHERE fc.user_id = user_internal_id
    ORDER BY fc.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- STEP 4: CREATE USER BLOCK CHECK FUNCTION
-- ===========================================

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS is_user_blocked(UUID, UUID);
DROP FUNCTION IF EXISTS check_user_blocked(UUID, UUID);

-- Create is_user_blocked function
CREATE OR REPLACE FUNCTION is_user_blocked(
    p_auth_user_id UUID,
    p_target_user_id TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    user_internal_id UUID;
    target_internal_id UUID;
    is_blocked BOOLEAN := FALSE;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(p_auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Get target user's internal ID
    SELECT id INTO target_internal_id
    FROM users 
    WHERE id::text = p_target_user_id;
    
    IF target_internal_id IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Check if user is blocked by target user
    SELECT EXISTS (
        SELECT 1 FROM user_blocks ub
        WHERE ub.blocker_id = target_internal_id
        AND ub.blocked_id = user_internal_id
    ) INTO is_blocked;
    
    RETURN is_blocked;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- STEP 5: CREATE ADDITIONAL MISSING FUNCTIONS
-- ===========================================

-- Create leave_book_club function
CREATE OR REPLACE FUNCTION leave_book_club(
    p_auth_user_id UUID,
    p_club_id UUID
)
RETURNS JSONB AS $$
DECLARE
    user_internal_id UUID;
    club_name TEXT;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(p_auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Get club name
    SELECT bc.name INTO club_name
    FROM book_clubs bc
    WHERE bc.id = p_club_id;
    
    IF club_name IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Club not found');
    END IF;
    
    -- Remove user from club
    DELETE FROM book_club_members 
    WHERE club_id = p_club_id 
    AND user_id = user_internal_id;
    
    RETURN jsonb_build_object('success', true, 'message', 'Successfully left ' || club_name);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create delete_book_club function
CREATE OR REPLACE FUNCTION delete_book_club(
    p_auth_user_id UUID,
    p_book_club_id UUID
)
RETURNS JSONB AS $$
DECLARE
    user_internal_id UUID;
    club_name TEXT;
    is_creator BOOLEAN := FALSE;
BEGIN
    -- Get user's internal ID
    user_internal_id := get_user_internal_id(p_auth_user_id);
    
    IF user_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Check if user is the creator
    SELECT bc.name, (bc.creator_id = user_internal_id) INTO club_name, is_creator
    FROM book_clubs bc
    WHERE bc.id = p_book_club_id;
    
    IF club_name IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Club not found');
    END IF;
    
    IF NOT is_creator THEN
        RETURN jsonb_build_object('success', false, 'error', 'Only the club creator can delete the club');
    END IF;
    
    -- Delete the club (cascade will handle related records)
    DELETE FROM book_clubs WHERE id = p_book_club_id;
    
    RETURN jsonb_build_object('success', true, 'message', 'Club deleted successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- STEP 6: CREATE MISSING TABLES IF NEEDED
-- ===========================================

-- Create book_polls table if it doesn't exist
CREATE TABLE IF NOT EXISTS book_polls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES book_clubs(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    book_options TEXT[],
    closes_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID NOT NULL REFERENCES users(id),
    status TEXT DEFAULT 'active',
    total_votes INTEGER DEFAULT 0
);

-- Create book_votes table if it doesn't exist
CREATE TABLE IF NOT EXISTS book_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poll_id UUID NOT NULL REFERENCES book_polls(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id),
    option_index INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(poll_id, user_id)
);

-- Check and fix table structures if needed
DO $$
BEGIN
    -- Check book_polls table
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'book_polls' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'book_polls' AND column_name = 'created_by' AND table_schema = 'public') THEN
            DROP TABLE IF EXISTS book_polls CASCADE;
            CREATE TABLE book_polls (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                club_id UUID NOT NULL REFERENCES book_clubs(id) ON DELETE CASCADE,
                title TEXT NOT NULL,
                description TEXT,
                book_options TEXT[],
                closes_at TIMESTAMP WITH TIME ZONE,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                created_by UUID NOT NULL REFERENCES users(id),
                status TEXT DEFAULT 'active',
                total_votes INTEGER DEFAULT 0
            );
        END IF;
    END IF;
    
    -- Check book_votes table
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'book_votes' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'book_votes' AND column_name = 'user_id' AND table_schema = 'public') THEN
            DROP TABLE IF EXISTS book_votes CASCADE;
            CREATE TABLE book_votes (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                poll_id UUID NOT NULL REFERENCES book_polls(id) ON DELETE CASCADE,
                user_id UUID NOT NULL REFERENCES users(id),
                option_index INTEGER NOT NULL,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                UNIQUE(poll_id, user_id)
            );
        END IF;
    END IF;
END $$;

-- Create friend_connections table if it doesn't exist
CREATE TABLE IF NOT EXISTS friend_connections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    friend_id UUID NOT NULL REFERENCES users(id),
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, friend_id)
);

-- Check if the table already exists with different column names
DO $$
BEGIN
    -- If friend_connections exists but with different column names, drop and recreate
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'friend_connections' AND table_schema = 'public') THEN
        -- Check if user_id column exists
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'friend_connections' AND column_name = 'user_id' AND table_schema = 'public') THEN
            DROP TABLE IF EXISTS friend_connections CASCADE;
            CREATE TABLE friend_connections (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                user_id UUID NOT NULL REFERENCES users(id),
                friend_id UUID NOT NULL REFERENCES users(id),
                status TEXT DEFAULT 'pending',
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                UNIQUE(user_id, friend_id)
            );
        END IF;
    END IF;
END $$;

-- Create user_blocks table if it doesn't exist
CREATE TABLE IF NOT EXISTS user_blocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    blocker_id UUID NOT NULL REFERENCES users(id),
    blocked_id UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(blocker_id, blocked_id)
);

-- Check user_blocks table structure
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_blocks' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_blocks' AND column_name = 'blocker_id' AND table_schema = 'public') THEN
            DROP TABLE IF EXISTS user_blocks CASCADE;
            CREATE TABLE user_blocks (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                blocker_id UUID NOT NULL REFERENCES users(id),
                blocked_id UUID NOT NULL REFERENCES users(id),
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                UNIQUE(blocker_id, blocked_id)
            );
        END IF;
    END IF;
END $$;

-- ===========================================
-- STEP 7: ENABLE RLS ON NEW TABLES
-- ===========================================

-- Enable RLS on new tables
ALTER TABLE book_polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE book_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE friend_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_blocks ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for new tables
CREATE POLICY "Users can view all polls" ON book_polls FOR SELECT USING (true);
CREATE POLICY "Users can create polls" ON book_polls FOR INSERT WITH CHECK (created_by = (SELECT id FROM users WHERE auth_user_id = auth.uid()));
CREATE POLICY "Users can view all votes" ON book_votes FOR SELECT USING (true);
CREATE POLICY "Users can vote" ON book_votes FOR INSERT WITH CHECK (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));
CREATE POLICY "Users can view friend connections" ON friend_connections FOR SELECT USING (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));
CREATE POLICY "Users can create friend connections" ON friend_connections FOR INSERT WITH CHECK (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));
CREATE POLICY "Users can view blocks" ON user_blocks FOR SELECT USING (blocker_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

-- ===========================================
-- STEP 8: VERIFICATION
-- ===========================================

SELECT '=== MISSING FUNCTIONS CREATED ===' as header;

-- Show all functions
SELECT 
    'Functions Created' as check_type,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name IN (
    'get_club_polls',
    'maintain_poll_hygiene',
    'get_friend_connections',
    'is_user_blocked',
    'leave_book_club',
    'delete_book_club'
)
ORDER BY routine_name;

SELECT '=== ALL MISSING FUNCTIONS CREATED ===' as status;
