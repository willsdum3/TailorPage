-- Fix Username Login
-- This script creates the missing lookup_email_by_username function
-- that allows users to sign in with their username instead of email

-- ===========================================
-- STEP 1: DROP EXISTING FUNCTION (if any)
-- ===========================================

DROP FUNCTION IF EXISTS lookup_email_by_username(TEXT);

-- ===========================================
-- STEP 2: CREATE LOOKUP_EMAIL_BY_USERNAME FUNCTION
-- ===========================================

-- Function to lookup email by username for authentication
CREATE OR REPLACE FUNCTION lookup_email_by_username(username_input TEXT)
RETURNS TABLE(
    email TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    found_email TEXT;
BEGIN
    -- Validate input
    IF username_input IS NULL OR TRIM(username_input) = '' THEN
        RETURN; -- Return empty result for invalid input
    END IF;
    
    -- Look up the email from the users table using the username
    -- Handle case-insensitive matching and trim whitespace
    SELECT u.email INTO found_email
    FROM users u
    WHERE u.username IS NOT NULL
      AND LOWER(TRIM(u.username)) = LOWER(TRIM(username_input))
    LIMIT 1;
    
    -- If email found, return it; otherwise return empty result
    IF found_email IS NOT NULL THEN
        RETURN QUERY SELECT found_email;
    END IF;
END;
$$;

-- ===========================================
-- STEP 3: GRANT PERMISSIONS
-- ===========================================

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION lookup_email_by_username(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION lookup_email_by_username(TEXT) TO anon;

-- ===========================================
-- STEP 4: TEST THE FUNCTION
-- ===========================================

-- Note: Uncomment and modify the test below with a real username to test
-- SELECT * FROM lookup_email_by_username('your_username_here');

SELECT '=== USERNAME LOGIN FUNCTION CREATED ===' as header;

