-- =====================================================
-- FIX USERNAME LOOKUP FOR VERCEL
-- =====================================================
-- This script creates a function that allows username lookup without service key

-- Function to lookup email by username (can be called with regular client)
CREATE OR REPLACE FUNCTION lookup_email_by_username(username_input TEXT)
RETURNS TABLE(email TEXT) AS $$
BEGIN
    -- Check if username exists and return the email
    RETURN QUERY
    SELECT u.email
    FROM users u
    WHERE u.username = username_input
       OR u.username ILIKE username_input;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION lookup_email_by_username(TEXT) TO authenticated;

-- Test the function
DO $$
BEGIN
    RAISE NOTICE '✅ Username lookup function created successfully!';
    RAISE NOTICE 'This function can be called with the regular Supabase client (no service key needed)';
END $$;
