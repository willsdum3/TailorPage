-- Fix Profile Picture Preservation Issue
-- This script updates the get_or_create_user function to preserve existing profile pictures
-- when users sign in with Google OAuth

-- Drop the existing function
DROP FUNCTION IF EXISTS get_or_create_user(UUID, TEXT, TEXT, TEXT, TEXT);

-- Create the improved function that preserves existing avatar URLs
CREATE OR REPLACE FUNCTION get_or_create_user(
    auth_user_id UUID,
    user_name TEXT,
    user_email TEXT,
    user_username TEXT DEFAULT NULL,
    user_avatar_url TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
    existing_avatar_url TEXT;
    final_avatar_url TEXT;
    final_username TEXT;
BEGIN
    -- Try to find existing user
    SELECT id, avatar_url, username INTO user_uuid, existing_avatar_url, final_username
    FROM users
    WHERE users.auth_user_id = get_or_create_user.auth_user_id;
    
    -- If user doesn't exist, create them
    IF user_uuid IS NULL THEN
        INSERT INTO users (auth_user_id, name, email, username, avatar_url)
        VALUES (get_or_create_user.auth_user_id, user_name, user_email, user_username, user_avatar_url)
        RETURNING id INTO user_uuid;
        
        RAISE NOTICE 'Created new user with ID: %', user_uuid;
    ELSE
        -- User exists, update only if values are different
        -- Preserve existing avatar_url unless new one is provided and different
        IF user_avatar_url IS NOT NULL AND user_avatar_url != existing_avatar_url THEN
            final_avatar_url := user_avatar_url;
            RAISE NOTICE 'Updating existing user avatar from % to %', existing_avatar_url, final_avatar_url;
        ELSE
            final_avatar_url := existing_avatar_url;
            RAISE NOTICE 'Preserving existing user avatar: %', existing_avatar_url;
        END IF;
        
        -- Preserve existing username unless explicitly changing it
        IF user_username IS NOT NULL AND user_username != final_username THEN
            final_username := user_username;
            RAISE NOTICE 'Updating username from % to %', final_username, user_username;
        ELSE
            RAISE NOTICE 'Preserving existing username: %', final_username;
        END IF;
        
        -- Update user profile with new information, preserving existing data if appropriate
        UPDATE users 
        SET 
            name = COALESCE(user_name, name),
            email = COALESCE(user_email, email),
            username = final_username,
            avatar_url = final_avatar_url,
            updated_at = NOW()
        WHERE id = user_uuid;
        
        RAISE NOTICE 'Updated existing user with ID: %', user_uuid;
    END IF;
    
    RETURN user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Verify the function exists
SELECT 
    'get_or_create_user function updated successfully' as status,
    proname as function_name,
    proargnames as parameters
FROM pg_proc 
WHERE proname = 'get_or_create_user';
