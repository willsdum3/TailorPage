-- =====================================================
-- FIX USERNAME STORAGE ISSUE
-- =====================================================
-- This script fixes the username storage problem in the database

-- =====================================================
-- STEP 1: Update the get_or_create_user function to properly handle usernames
-- =====================================================

-- Drop the existing function
DROP FUNCTION IF EXISTS get_or_create_user(UUID, TEXT, TEXT, TEXT, TEXT);

-- Create an improved version that properly handles username updates
CREATE OR REPLACE FUNCTION get_or_create_user(
    auth_user_id UUID,
    user_name TEXT,
    user_email TEXT,
    user_username TEXT DEFAULT NULL,
    user_avatar_url TEXT DEFAULT NULL
)
RETURNS TABLE(
    id UUID,
    username TEXT,
    email TEXT,
    name TEXT,
    avatar_url TEXT
) AS $$
DECLARE
    user_uuid UUID;
    existing_username TEXT;
BEGIN
    -- Try to find existing user
    SELECT id, username INTO user_uuid, existing_username
    FROM users
    WHERE users.auth_user_id = get_or_create_user.auth_user_id;
    
    -- If user doesn't exist, create them
    IF user_uuid IS NULL THEN
        INSERT INTO users (auth_user_id, name, email, username, avatar_url)
        VALUES (get_or_create_user.auth_user_id, user_name, user_email, user_username, user_avatar_url)
        RETURNING id INTO user_uuid;
        
        -- Return the newly created user data
        RETURN QUERY
        SELECT u.id, u.username, u.email, u.name, u.avatar_url
        FROM users u
        WHERE u.id = user_uuid;
    ELSE
        -- User exists, update their information if needed
        UPDATE users 
        SET 
            name = COALESCE(user_name, name),
            email = COALESCE(user_email, email),
            username = COALESCE(user_username, username),
            avatar_url = COALESCE(user_avatar_url, avatar_url),
            updated_at = NOW()
        WHERE id = user_uuid;
        
        -- Return the updated user data
        RETURN QUERY
        SELECT u.id, u.username, u.email, u.name, u.avatar_url
        FROM users u
        WHERE u.id = user_uuid;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 2: Create a function to update existing users with usernames
-- =====================================================

CREATE OR REPLACE FUNCTION update_existing_users_with_usernames()
RETURNS TEXT AS $$
DECLARE
    user_record RECORD;
    updated_count INTEGER := 0;
BEGIN
    -- Loop through all users who don't have usernames
    FOR user_record IN 
        SELECT auth_user_id, email, name
        FROM users 
        WHERE username IS NULL OR username = ''
    LOOP
        -- Generate a username from email prefix
        UPDATE users 
        SET username = split_part(user_record.email, '@', 1),
            updated_at = NOW()
        WHERE auth_user_id = user_record.auth_user_id;
        
        updated_count := updated_count + 1;
    END LOOP;
    
    RETURN 'Updated ' || updated_count || ' users with usernames';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 3: Grant necessary permissions
-- =====================================================

GRANT EXECUTE ON FUNCTION get_or_create_user(UUID, TEXT, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION update_existing_users_with_usernames() TO authenticated;

-- =====================================================
-- STEP 4: Update existing users (optional - run this if you want to backfill usernames)
-- =====================================================

-- Uncomment the line below to automatically update existing users with usernames
-- SELECT update_existing_users_with_usernames();
