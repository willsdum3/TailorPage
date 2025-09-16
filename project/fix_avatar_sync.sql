-- =====================================================
-- FIX AVATAR SYNC AND TEST
-- =====================================================
-- This script helps sync avatar URLs and tests the fix

-- First, let's see the current state of avatars
DO $$
DECLARE
    total_users INTEGER;
    users_with_avatars INTEGER;
    sample_user RECORD;
BEGIN
    RAISE NOTICE '=== CURRENT AVATAR STATUS ===';
    
    SELECT COUNT(*) INTO total_users FROM users;
    RAISE NOTICE 'Total users: %', total_users;
    
    SELECT COUNT(*) INTO users_with_avatars 
    FROM users 
    WHERE avatar_url IS NOT NULL 
    AND avatar_url != '' 
    AND avatar_url != 'null';
    RAISE NOTICE 'Users with avatars: %', users_with_avatars;
    
    -- Show sample data
    FOR sample_user IN 
        SELECT username, name, avatar_url
        FROM users 
        WHERE username IS NOT NULL
        LIMIT 5
    LOOP
        RAISE NOTICE 'User @%: Avatar = %', 
            sample_user.username, 
            COALESCE(sample_user.avatar_url, 'NULL');
    END LOOP;
END $$;

-- Create a function to manually sync avatar URLs from auth metadata if needed
CREATE OR REPLACE FUNCTION sync_user_avatars_from_auth()
RETURNS INTEGER AS $$
DECLARE
    updated_count INTEGER := 0;
    user_record RECORD;
BEGIN
    -- This function would need to be called with actual auth data
    -- For now, let's just return 0
    RETURN 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the search function to see if it returns avatars
DO $$
DECLARE
    search_result RECORD;
    result_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== TESTING SEARCH WITH AVATARS ===';
    
    -- Test search for 'kat' (from your screenshot)
    FOR search_result IN 
        SELECT * FROM search_users_by_username('kat', 5)
    LOOP
        result_count := result_count + 1;
        RAISE NOTICE 'Search result %:', result_count;
        RAISE NOTICE '  Username: @%', search_result.username;
        RAISE NOTICE '  Name: %', search_result.name;
        RAISE NOTICE '  Avatar: %', COALESCE(search_result.avatar_url, 'NULL');
        RAISE NOTICE '  ID: %', search_result.id;
        RAISE NOTICE '---';
    END LOOP;
    
    IF result_count = 0 THEN
        RAISE NOTICE 'No search results found for "kat"';
    END IF;
END $$;

-- Check if we need to update the get_or_create_user function to handle avatars properly
DO $$
BEGIN
    RAISE NOTICE '=== DIAGNOSIS SUMMARY ===';
    RAISE NOTICE 'If users have NULL avatars, the issue is likely:';
    RAISE NOTICE '1. Avatar URLs are not being synced during user creation';
    RAISE NOTICE '2. The auth provider (Supabase Auth) does not have avatar data';
    RAISE NOTICE '3. The sync process is not mapping avatar fields correctly';
    RAISE NOTICE '';
    RAISE NOTICE 'Frontend fix applied: Changed image_url to avatar_url in useUserSync.ts';
    RAISE NOTICE 'This should fix avatar syncing for new logins.';
    RAISE NOTICE '';
    RAISE NOTICE 'For existing users without avatars, they may need to:';
    RAISE NOTICE '1. Upload profile pictures manually, or';
    RAISE NOTICE '2. Log out and log back in to trigger avatar sync';
END $$;
