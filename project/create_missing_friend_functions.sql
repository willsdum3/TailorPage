-- Create missing friend functions that are causing 404 errors

-- 1. Create get_friend_requests function
CREATE OR REPLACE FUNCTION get_friend_requests(p_auth_user_id UUID)
RETURNS TABLE(
    id UUID,
    friend_id UUID,
    friend_name TEXT,
    friend_username TEXT,
    friend_image_url TEXT,
    status TEXT,
    personality_match_score INTEGER,
    created_at TIMESTAMP WITH TIME ZONE
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        fr.id,
        fr.requester_id as friend_id,
        u.name as friend_name,
        u.username as friend_username,
        u.avatar_url as friend_image_url,
        fr.status,
        0 as personality_match_score, -- Default for now
        fr.created_at
    FROM friend_requests fr
    JOIN users u ON fr.requester_id = u.id
    WHERE fr.target_id = p_auth_user_id
    AND fr.status = 'pending'
    ORDER BY fr.created_at DESC;
END;
$$;

-- 2. Create get_friend_connections function
CREATE OR REPLACE FUNCTION get_friend_connections(p_auth_user_id UUID)
RETURNS TABLE(
    id UUID,
    friend_id UUID,
    friend_name TEXT,
    friend_username TEXT,
    friend_image_url TEXT,
    status TEXT,
    personality_match_score INTEGER,
    created_at TIMESTAMP WITH TIME ZONE
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        fr.id,
        CASE 
            WHEN fr.requester_id = p_auth_user_id THEN fr.target_id
            ELSE fr.requester_id
        END as friend_id,
        CASE 
            WHEN fr.requester_id = p_auth_user_id THEN u2.name
            ELSE u1.name
        END as friend_name,
        CASE 
            WHEN fr.requester_id = p_auth_user_id THEN u2.username
            ELSE u1.username
        END as friend_username,
        CASE 
            WHEN fr.requester_id = p_auth_user_id THEN u2.avatar_url
            ELSE u1.avatar_url
        END as friend_image_url,
        fr.status,
        0 as personality_match_score, -- Default for now
        fr.created_at
    FROM friend_requests fr
    LEFT JOIN users u1 ON fr.requester_id = u1.id
    LEFT JOIN users u2 ON fr.target_id = u2.id
    WHERE (fr.requester_id = p_auth_user_id OR fr.target_id = p_auth_user_id)
    AND fr.status = 'accepted'
    ORDER BY fr.created_at DESC;
END;
$$;

-- 3. Create get_friend_recommendations function
CREATE OR REPLACE FUNCTION get_friend_recommendations(p_auth_user_id UUID)
RETURNS TABLE(
    id UUID,
    recommended_user_id UUID,
    recommended_user_name TEXT,
    recommended_user_username TEXT,
    recommended_user_image_url TEXT,
    match_score INTEGER,
    match_reasons TEXT[],
    created_at TIMESTAMP WITH TIME ZONE
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gen_random_uuid() as id,
        u.id as recommended_user_id,
        u.name as recommended_user_name,
        u.username as recommended_user_username,
        u.avatar_url as recommended_user_image_url,
        75 as match_score, -- Default score
        ARRAY['Similar reading interests', 'Active in book clubs', 'Great conversation starter'] as match_reasons,
        NOW() as created_at
    FROM users u
    WHERE u.id != p_auth_user_id
    AND u.id NOT IN (
        SELECT CASE 
            WHEN requester_id = p_auth_user_id THEN target_id
            ELSE requester_id
        END
        FROM friend_requests 
        WHERE (requester_id = p_auth_user_id OR target_id = p_auth_user_id)
    )
    LIMIT 5;
END;
$$;

-- 4. Create generate_friend_recommendations function
CREATE OR REPLACE FUNCTION generate_friend_recommendations(p_auth_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    recommendation_count INTEGER;
BEGIN
    -- For now, just return a count of potential recommendations
    SELECT COUNT(*) INTO recommendation_count
    FROM users u
    WHERE u.id != p_auth_user_id
    AND u.id NOT IN (
        SELECT CASE 
            WHEN requester_id = p_auth_user_id THEN target_id
            ELSE requester_id
        END
        FROM friend_requests 
        WHERE (requester_id = p_auth_user_id OR target_id = p_auth_user_id)
    );
    
    RETURN recommendation_count;
END;
$$;

-- 5. Create send_friend_request function
CREATE OR REPLACE FUNCTION send_friend_request(
    p_auth_user_id UUID,
    p_target_user_id UUID,
    p_message TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    existing_request UUID;
    result JSON;
BEGIN
    -- Check if request already exists
    SELECT id INTO existing_request
    FROM friend_requests
    WHERE requester_id = p_auth_user_id 
    AND target_id = p_target_user_id
    AND status = 'pending';
    
    IF existing_request IS NOT NULL THEN
        result := json_build_object('success', false, 'error', 'Friend request already exists');
        RETURN result;
    END IF;
    
    -- Check if they're already friends
    SELECT id INTO existing_request
    FROM friend_requests
    WHERE ((requester_id = p_auth_user_id AND target_id = p_target_user_id)
           OR (requester_id = p_target_user_id AND target_id = p_auth_user_id))
    AND status = 'accepted';
    
    IF existing_request IS NOT NULL THEN
        result := json_build_object('success', false, 'error', 'You are already friends');
        RETURN result;
    END IF;
    
    -- Create the friend request
    INSERT INTO friend_requests (requester_id, target_id, message, status)
    VALUES (p_auth_user_id, p_target_user_id, p_message, 'pending');
    
    result := json_build_object('success', true);
    RETURN result;
END;
$$;

-- 6. Create accept_friend_request function
CREATE OR REPLACE FUNCTION accept_friend_request(
    p_auth_user_id UUID,
    p_requester_user_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    request_id UUID;
    result JSON;
BEGIN
    -- Find the pending request
    SELECT id INTO request_id
    FROM friend_requests
    WHERE requester_id = p_requester_user_id 
    AND target_id = p_auth_user_id
    AND status = 'pending';
    
    IF request_id IS NULL THEN
        result := json_build_object('success', false, 'error', 'Friend request not found');
        RETURN result;
    END IF;
    
    -- Accept the request
    UPDATE friend_requests 
    SET status = 'accepted'
    WHERE id = request_id;
    
    result := json_build_object('success', true);
    RETURN result;
END;
$$;

-- 7. Create reject_friend_request function
CREATE OR REPLACE FUNCTION reject_friend_request(
    p_auth_user_id UUID,
    p_requester_user_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    request_id UUID;
    result JSON;
BEGIN
    -- Find the pending request
    SELECT id INTO request_id
    FROM friend_requests
    WHERE requester_id = p_requester_user_id 
    AND target_id = p_auth_user_id
    AND status = 'pending';
    
    IF request_id IS NULL THEN
        result := json_build_object('success', false, 'error', 'Friend request not found');
        RETURN result;
    END IF;
    
    -- Reject the request
    UPDATE friend_requests 
    SET status = 'rejected'
    WHERE id = request_id;
    
    result := json_build_object('success', true);
    RETURN result;
END;
$$;
