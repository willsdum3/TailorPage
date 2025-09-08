-- =====================================================
-- TAILOR MATES FUNCTIONS FOR SUPABASE AUTH (CLEAN VERSION)
-- =====================================================
-- This script creates all Tailor Mates RPC functions for Supabase Auth

-- =====================================================
-- HELPER FUNCTIONS (REQUIRED BY OTHER FUNCTIONS)
-- =====================================================

-- Function to get user ID from auth_user_id
CREATE OR REPLACE FUNCTION get_user_id_from_auth(auth_user_id UUID)
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
BEGIN
    SELECT id INTO user_uuid
    FROM users
    WHERE auth_user_id = get_user_id_from_auth.auth_user_id;
    
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'User not found for auth_user_id: %', auth_user_id;
    END IF;
    
    RETURN user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user has completed personality quiz
CREATE OR REPLACE FUNCTION user_has_personality_profile(auth_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
    profile_exists BOOLEAN;
BEGIN
    user_uuid := get_user_id_from_auth(auth_user_id);
    
    SELECT EXISTS(
        SELECT 1 FROM user_personality_profiles 
        WHERE user_id = user_uuid
    ) INTO profile_exists;
    
    RETURN profile_exists;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate personality match score
CREATE OR REPLACE FUNCTION calculate_personality_match(user1_id UUID, user2_id UUID)
RETURNS DECIMAL(5,2) AS $$
DECLARE
    user1_profile RECORD;
    user2_profile RECORD;
    total_score DECIMAL(5,2) := 0;
    trait_count INTEGER := 0;
    trait_score DECIMAL(5,2);
BEGIN
    -- Get personality profiles
    SELECT * INTO user1_profile FROM user_personality_profiles WHERE user_id = user1_id;
    SELECT * INTO user2_profile FROM user_personality_profiles WHERE user_id = user2_id;
    
    -- Check if both users have profiles
    IF user1_profile IS NULL OR user2_profile IS NULL THEN
        RETURN 0;
    END IF;
    
    -- Calculate similarity for each trait
    -- Openness
    trait_score := 100 - ABS(user1_profile.openness - user2_profile.openness) * 4;
    total_score := total_score + GREATEST(0, trait_score);
    trait_count := trait_count + 1;
    
    -- Conscientiousness
    trait_score := 100 - ABS(user1_profile.conscientiousness - user2_profile.conscientiousness) * 4;
    total_score := total_score + GREATEST(0, trait_score);
    trait_count := trait_count + 1;
    
    -- Extraversion
    trait_score := 100 - ABS(user1_profile.extraversion - user2_profile.extraversion) * 4;
    total_score := total_score + GREATEST(0, trait_score);
    trait_count := trait_count + 1;
    
    -- Agreeableness
    trait_score := 100 - ABS(user1_profile.agreeableness - user2_profile.agreeableness) * 4;
    total_score := total_score + GREATEST(0, trait_score);
    trait_count := trait_count + 1;
    
    -- Emotional Stability
    trait_score := 100 - ABS(user1_profile.emotional_stability - user2_profile.emotional_stability) * 4;
    total_score := total_score + GREATEST(0, trait_score);
    trait_count := trait_count + 1;
    
    -- Return average score
    RETURN ROUND(total_score / trait_count, 2);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to generate match reasons
CREATE OR REPLACE FUNCTION generate_match_reasons(user1_id UUID, user2_id UUID)
RETURNS TEXT[] AS $$
DECLARE
    user1_profile RECORD;
    user2_profile RECORD;
    reasons TEXT[] := '{}';
    trait_diff DECIMAL(5,2);
BEGIN
    -- Get personality profiles
    SELECT * INTO user1_profile FROM user_personality_profiles WHERE user_id = user1_id;
    SELECT * INTO user2_profile FROM user_personality_profiles WHERE user_id = user2_id;
    
    -- Check if both users have profiles
    IF user1_profile IS NULL OR user2_profile IS NULL THEN
        RETURN reasons;
    END IF;
    
    -- Check each trait for similarity
    -- Openness
    trait_diff := ABS(user1_profile.openness - user2_profile.openness);
    IF trait_diff <= 2 THEN
        reasons := array_append(reasons, 'Similar openness to new experiences');
    END IF;
    
    -- Conscientiousness
    trait_diff := ABS(user1_profile.conscientiousness - user2_profile.conscientiousness);
    IF trait_diff <= 2 THEN
        reasons := array_append(reasons, 'Similar organizational habits');
    END IF;
    
    -- Extraversion
    trait_diff := ABS(user1_profile.extraversion - user2_profile.extraversion);
    IF trait_diff <= 2 THEN
        reasons := array_append(reasons, 'Similar social energy levels');
    END IF;
    
    -- Agreeableness
    trait_diff := ABS(user1_profile.agreeableness - user2_profile.agreeableness);
    IF trait_diff <= 2 THEN
        reasons := array_append(reasons, 'Similar cooperation styles');
    END IF;
    
    -- Emotional Stability
    trait_diff := ABS(user1_profile.emotional_stability - user2_profile.emotional_stability);
    IF trait_diff <= 2 THEN
        reasons := array_append(reasons, 'Similar emotional responses');
    END IF;
    
    -- If no specific reasons, add a general one
    IF array_length(reasons, 1) IS NULL THEN
        reasons := array_append(reasons, 'Good overall personality compatibility');
    END IF;
    
    RETURN reasons;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- BOOK CLUB FUNCTIONS
-- =====================================================

-- Function to create a book club
CREATE OR REPLACE FUNCTION create_book_club(
    auth_user_id UUID,
    club_name TEXT,
    club_description TEXT,
    current_book_title TEXT DEFAULT NULL,
    current_book_author TEXT DEFAULT NULL,
    max_members INTEGER DEFAULT 10,
    is_public BOOLEAN DEFAULT true,
    target_personality_traits TEXT[] DEFAULT '{}',
    tags TEXT[] DEFAULT '{}',
    meeting_info TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
    club_uuid UUID;
BEGIN
    -- Get user ID from auth_user_id
    user_uuid := get_user_id_from_auth(auth_user_id);
    
    -- Validate max_members
    IF max_members < 5 OR max_members > 100 THEN
        RAISE EXCEPTION 'Max members must be between 5 and 100';
    END IF;
    
    -- Create the book club
    INSERT INTO book_clubs (
        name, description, current_book_title, current_book_author,
        max_members, is_public, target_personality_traits, tags, meeting_info, created_by
    )
    VALUES (
        club_name, club_description, current_book_title, current_book_author,
        max_members, is_public, target_personality_traits, tags, meeting_info, user_uuid
    )
    RETURNING id INTO club_uuid;
    
    -- Add creator as owner
    INSERT INTO club_memberships (club_id, user_id, role)
    VALUES (club_uuid, user_uuid, 'owner');
    
    RETURN club_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get all book clubs with user membership status
CREATE OR REPLACE FUNCTION get_book_clubs(auth_user_id UUID)
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    current_book_title TEXT,
    current_book_author TEXT,
    max_members INTEGER,
    is_public BOOLEAN,
    target_personality_traits TEXT[],
    tags TEXT[],
    meeting_info TEXT,
    created_by UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    member_count BIGINT,
    is_member BOOLEAN,
    user_role TEXT
) AS $$
DECLARE
    user_uuid UUID;
BEGIN
    user_uuid := get_user_id_from_auth(auth_user_id);
    
    RETURN QUERY
    SELECT 
        bc.id,
        bc.name,
        bc.description,
        bc.current_book_title,
        bc.current_book_author,
        bc.max_members,
        bc.is_public,
        bc.target_personality_traits,
        bc.tags,
        bc.meeting_info,
        bc.created_by,
        bc.created_at,
        COUNT(cm.id) as member_count,
        CASE WHEN user_membership.id IS NOT NULL THEN true ELSE false END as is_member,
        COALESCE(user_membership.role, '') as user_role
    FROM book_clubs bc
    LEFT JOIN club_memberships cm ON bc.id = cm.club_id
    LEFT JOIN club_memberships user_membership ON bc.id = user_membership.club_id AND user_membership.user_id = user_uuid
    WHERE bc.is_public = true OR bc.created_by = user_uuid OR user_membership.id IS NOT NULL
    GROUP BY bc.id, bc.name, bc.description, bc.current_book_title, bc.current_book_author,
             bc.max_members, bc.is_public, bc.target_personality_traits, bc.tags,
             bc.meeting_info, bc.created_by, bc.created_at, user_membership.id, user_membership.role
    ORDER BY bc.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to join a book club
CREATE OR REPLACE FUNCTION join_book_club(auth_user_id UUID, club_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
    current_member_count INTEGER;
    max_members INTEGER;
BEGIN
    user_uuid := get_user_id_from_auth(auth_user_id);
    
    -- Check if club exists and get max members
    SELECT max_members INTO max_members
    FROM book_clubs
    WHERE id = club_id;
    
    IF max_members IS NULL THEN
        RAISE EXCEPTION 'Book club not found';
    END IF;
    
    -- Check current member count
    SELECT COUNT(*) INTO current_member_count
    FROM club_memberships
    WHERE club_id = join_book_club.club_id;
    
    -- Check if already a member
    IF EXISTS (SELECT 1 FROM club_memberships WHERE club_id = join_book_club.club_id AND user_id = user_uuid) THEN
        RAISE EXCEPTION 'Already a member of this club';
    END IF;
    
    -- Check if club is full
    IF current_member_count >= max_members THEN
        RAISE EXCEPTION 'Club is full';
    END IF;
    
    -- Add user to club
    INSERT INTO club_memberships (club_id, user_id, role)
    VALUES (club_id, user_uuid, 'member');
    
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to leave a book club
CREATE OR REPLACE FUNCTION leave_book_club(auth_user_id UUID, club_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
    user_role TEXT;
BEGIN
    user_uuid := get_user_id_from_auth(auth_user_id);
    
    -- Get user's role in the club
    SELECT role INTO user_role
    FROM club_memberships
    WHERE club_id = leave_book_club.club_id AND user_id = user_uuid;
    
    IF user_role IS NULL THEN
        RAISE EXCEPTION 'Not a member of this club';
    END IF;
    
    -- Don't allow owner to leave (they should transfer ownership first)
    IF user_role = 'owner' THEN
        RAISE EXCEPTION 'Club owner cannot leave. Transfer ownership first.';
    END IF;
    
    -- Remove user from club
    DELETE FROM club_memberships
    WHERE club_id = leave_book_club.club_id AND user_id = user_uuid;
    
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- DISCUSSION FUNCTIONS
-- =====================================================

-- Function to create a discussion
CREATE OR REPLACE FUNCTION create_discussion(
    auth_user_id UUID,
    discussion_title TEXT,
    discussion_content TEXT,
    book_title TEXT DEFAULT NULL,
    book_author TEXT DEFAULT NULL,
    tags TEXT[] DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
    discussion_uuid UUID;
BEGIN
    user_uuid := get_user_id_from_auth(auth_user_id);
    
    -- Create the discussion
    INSERT INTO discussions (
        title, content, book_title, book_author, tags, created_by
    )
    VALUES (
        discussion_title, discussion_content, book_title, book_author, tags, user_uuid
    )
    RETURNING id INTO discussion_uuid;
    
    -- Add creator as participant
    INSERT INTO discussion_participants (discussion_id, user_id)
    VALUES (discussion_uuid, user_uuid);
    
    RETURN discussion_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get all discussions with participation status
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
    user_uuid := get_user_id_from_auth(auth_user_id);
    
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
        COUNT(dm.id) as message_count,
        COUNT(DISTINCT dp.id) as participant_count,
        CASE WHEN user_participation.id IS NOT NULL THEN true ELSE false END as is_participant,
        MAX(dm.created_at) as last_message_at
    FROM discussions d
    LEFT JOIN discussion_messages dm ON d.id = dm.discussion_id
    LEFT JOIN discussion_participants dp ON d.id = dp.discussion_id
    LEFT JOIN discussion_participants user_participation ON d.id = user_participation.discussion_id AND user_participation.user_id = user_uuid
    GROUP BY d.id, d.title, d.content, d.book_title, d.book_author, d.tags,
             d.created_by, d.created_at, d.updated_at, user_participation.id
    ORDER BY COALESCE(MAX(dm.created_at), d.created_at) DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to join a discussion
CREATE OR REPLACE FUNCTION join_discussion(auth_user_id UUID, discussion_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
BEGIN
    user_uuid := get_user_id_from_auth(auth_user_id);
    
    -- Check if discussion exists
    IF NOT EXISTS (SELECT 1 FROM discussions WHERE id = discussion_id) THEN
        RAISE EXCEPTION 'Discussion not found';
    END IF;
    
    -- Check if already a participant
    IF EXISTS (SELECT 1 FROM discussion_participants WHERE discussion_id = join_discussion.discussion_id AND user_id = user_uuid) THEN
        RETURN true; -- Already a participant, return success
    END IF;
    
    -- Add user to discussion
    INSERT INTO discussion_participants (discussion_id, user_id)
    VALUES (discussion_id, user_uuid);
    
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to add a message to a discussion
CREATE OR REPLACE FUNCTION add_discussion_message(
    auth_user_id UUID,
    discussion_id UUID,
    message_content TEXT
)
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
    message_uuid UUID;
BEGIN
    user_uuid := get_user_id_from_auth(auth_user_id);
    
    -- Check if discussion exists
    IF NOT EXISTS (SELECT 1 FROM discussions WHERE id = discussion_id) THEN
        RAISE EXCEPTION 'Discussion not found';
    END IF;
    
    -- Add user as participant if not already
    INSERT INTO discussion_participants (discussion_id, user_id)
    VALUES (discussion_id, user_uuid)
    ON CONFLICT (discussion_id, user_id) DO NOTHING;
    
    -- Add the message
    INSERT INTO discussion_messages (discussion_id, user_id, content)
    VALUES (discussion_id, user_uuid, message_content)
    RETURNING id INTO message_uuid;
    
    -- Update discussion updated_at
    UPDATE discussions SET updated_at = NOW() WHERE id = discussion_id;
    
    RETURN message_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get discussion messages
CREATE OR REPLACE FUNCTION get_discussion_messages(
    auth_user_id UUID,
    discussion_id UUID,
    limit_count INTEGER DEFAULT 50,
    offset_count INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    content TEXT,
    user_id UUID,
    user_name TEXT,
    user_username TEXT,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    user_uuid UUID;
BEGIN
    user_uuid := get_user_id_from_auth(auth_user_id);
    
    -- Check if discussion exists
    IF NOT EXISTS (SELECT 1 FROM discussions WHERE id = discussion_id) THEN
        RAISE EXCEPTION 'Discussion not found';
    END IF;
    
    -- Add user as participant if not already
    INSERT INTO discussion_participants (discussion_id, user_id)
    VALUES (discussion_id, user_uuid)
    ON CONFLICT (discussion_id, user_id) DO NOTHING;
    
    RETURN QUERY
    SELECT 
        dm.id,
        dm.content,
        dm.user_id,
        u.name,
        u.username,
        dm.created_at
    FROM discussion_messages dm
    JOIN users u ON dm.user_id = u.id
    WHERE dm.discussion_id = get_discussion_messages.discussion_id
    ORDER BY dm.created_at ASC
    LIMIT limit_count
    OFFSET offset_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- FRIEND FUNCTIONS
-- =====================================================

-- Function to send a friend request
CREATE OR REPLACE FUNCTION send_friend_request(auth_user_id UUID, target_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
    target_uuid UUID;
BEGIN
    user_uuid := get_user_id_from_auth(auth_user_id);
    
    -- Get target user ID from auth_user_id
    target_uuid := get_user_id_from_auth(target_user_id);
    
    -- Check if users are the same
    IF user_uuid = target_uuid THEN
        RAISE EXCEPTION 'Cannot send friend request to yourself';
    END IF;
    
    -- Check if connection already exists
    IF EXISTS (
        SELECT 1 FROM friend_connections 
        WHERE (requester_id = user_uuid AND addressee_id = target_uuid)
           OR (requester_id = target_uuid AND addressee_id = user_uuid)
    ) THEN
        RAISE EXCEPTION 'Friend connection already exists';
    END IF;
    
    -- Create friend request
    INSERT INTO friend_connections (requester_id, addressee_id, status)
    VALUES (user_uuid, target_uuid, 'pending');
    
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to accept a friend request
CREATE OR REPLACE FUNCTION accept_friend_request(auth_user_id UUID, requester_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    user_uuid UUID;
    requester_uuid UUID;
BEGIN
    user_uuid := get_user_id_from_auth(auth_user_id);
    requester_uuid := get_user_id_from_auth(requester_user_id);
    
    -- Update the friend request
    UPDATE friend_connections
    SET status = 'accepted', updated_at = NOW()
    WHERE requester_id = requester_uuid AND addressee_id = user_uuid AND status = 'pending';
    
    -- Check if update was successful
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No pending friend request found';
    END IF;
    
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get friend connections
CREATE OR REPLACE FUNCTION get_friend_connections(auth_user_id UUID)
RETURNS TABLE (
    id UUID,
    other_user_id UUID,
    other_user_name TEXT,
    other_user_username TEXT,
    status TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    is_requester BOOLEAN
) AS $$
DECLARE
    user_uuid UUID;
BEGIN
    user_uuid := get_user_id_from_auth(auth_user_id);
    
    RETURN QUERY
    SELECT 
        fc.id,
        CASE 
            WHEN fc.requester_id = user_uuid THEN fc.addressee_id
            ELSE fc.requester_id
        END as other_user_id,
        CASE 
            WHEN fc.requester_id = user_uuid THEN addressee.name
            ELSE requester.name
        END as other_user_name,
        CASE 
            WHEN fc.requester_id = user_uuid THEN addressee.username
            ELSE requester.username
        END as other_user_username,
        fc.status,
        fc.created_at,
        (fc.requester_id = user_uuid) as is_requester
    FROM friend_connections fc
    JOIN users requester ON fc.requester_id = requester.id
    JOIN users addressee ON fc.addressee_id = addressee.id
    WHERE fc.requester_id = user_uuid OR fc.addressee_id = user_uuid
    ORDER BY fc.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to generate friend recommendations
CREATE OR REPLACE FUNCTION generate_friend_recommendations(auth_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    user_uuid UUID;
    recommendation_count INTEGER := 0;
    rec RECORD;
BEGIN
    user_uuid := get_user_id_from_auth(auth_user_id);
    
    -- Check if user has personality profile
    IF NOT user_has_personality_profile(auth_user_id) THEN
        RAISE EXCEPTION 'User must complete personality quiz before getting friend recommendations';
    END IF;
    
    -- Clear existing recommendations
    DELETE FROM friend_recommendations WHERE user_id = user_uuid;
    
    -- Generate new recommendations based on personality similarity
    FOR rec IN
        SELECT 
            u.id as recommended_user_id,
            calculate_personality_match(user_uuid, u.id) as match_score,
            generate_match_reasons(user_uuid, u.id) as match_reasons
        FROM users u
        JOIN user_personality_profiles upp ON u.id = upp.user_id
        WHERE u.id != user_uuid
          AND NOT EXISTS (
              SELECT 1 FROM friend_connections fc
              WHERE (fc.requester_id = user_uuid AND fc.addressee_id = u.id)
                 OR (fc.requester_id = u.id AND fc.addressee_id = user_uuid)
          )
          AND NOT EXISTS (
              SELECT 1 FROM friend_recommendations fr
              WHERE fr.user_id = user_uuid AND fr.recommended_user_id = u.id
          )
        HAVING calculate_personality_match(user_uuid, u.id) >= 70.0
        ORDER BY calculate_personality_match(user_uuid, u.id) DESC
        LIMIT 10
    LOOP
        INSERT INTO friend_recommendations (
            user_id, recommended_user_id, match_score, match_reasons
        )
        VALUES (
            user_uuid, rec.recommended_user_id, rec.match_score, rec.match_reasons
        );
        
        recommendation_count := recommendation_count + 1;
    END LOOP;
    
    RETURN recommendation_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get friend recommendations
CREATE OR REPLACE FUNCTION get_friend_recommendations(auth_user_id UUID)
RETURNS TABLE (
    id UUID,
    recommended_user_id UUID,
    recommended_user_name TEXT,
    recommended_user_username TEXT,
    match_score DECIMAL(5,2),
    match_reasons TEXT[],
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    user_uuid UUID;
BEGIN
    user_uuid := get_user_id_from_auth(auth_user_id);
    
    RETURN QUERY
    SELECT 
        fr.id,
        fr.recommended_user_id,
        u.name,
        u.username,
        fr.match_score,
        fr.match_reasons,
        fr.created_at
    FROM friend_recommendations fr
    JOIN users u ON fr.recommended_user_id = u.id
    WHERE fr.user_id = user_uuid
      AND fr.expires_at > NOW()
    ORDER BY fr.match_score DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

-- Grant execute permissions on all functions
GRANT EXECUTE ON FUNCTION create_book_club(UUID, TEXT, TEXT, TEXT, TEXT, INTEGER, BOOLEAN, TEXT[], TEXT[], TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_book_clubs(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION join_book_club(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION leave_book_club(UUID, UUID) TO authenticated;

GRANT EXECUTE ON FUNCTION create_discussion(UUID, TEXT, TEXT, TEXT, TEXT, TEXT[]) TO authenticated;
GRANT EXECUTE ON FUNCTION get_discussions(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION join_discussion(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION add_discussion_message(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_discussion_messages(UUID, UUID, INTEGER, INTEGER) TO authenticated;

GRANT EXECUTE ON FUNCTION send_friend_request(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION accept_friend_request(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_friend_connections(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION generate_friend_recommendations(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_friend_recommendations(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_personality_match(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION generate_match_reasons(UUID, UUID) TO authenticated;

GRANT EXECUTE ON FUNCTION get_user_id_from_auth(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION user_has_personality_profile(UUID) TO authenticated;

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '🎉 Tailor Mates functions setup completed successfully!';
    RAISE NOTICE 'Created book club functions: create_book_club, get_book_clubs, join_book_club, leave_book_club';
    RAISE NOTICE 'Created discussion functions: create_discussion, get_discussions, join_discussion, add_discussion_message, get_discussion_messages';
    RAISE NOTICE 'Created friend functions: send_friend_request, accept_friend_request, get_friend_connections, generate_friend_recommendations, get_friend_recommendations';
    RAISE NOTICE 'Created helper functions: calculate_personality_match, generate_match_reasons, get_user_id_from_auth, user_has_personality_profile';
    RAISE NOTICE 'All functions are ready for use!';
END $$;
