-- =====================================================
-- TEST DATABASE AND CREATE SIMPLE FUNCTION
-- =====================================================

-- Step 1: Check what tables exist
SELECT 'Available tables:' as info;
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Step 2: Check if books table exists and its structure
SELECT 'Books table structure:' as info;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'books' 
ORDER BY ordinal_position;

-- Step 3: Check if users table exists
SELECT 'Users table structure:' as info;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;

-- Step 4: Create a very simple test function
CREATE OR REPLACE FUNCTION get_simple_book_recommendations(
    user_auth_id UUID,
    limit_count INTEGER DEFAULT 6
)
RETURNS TABLE (
    id TEXT,
    title TEXT,
    author TEXT,
    genre TEXT
) AS $$
BEGIN
    -- Simple function that just returns some books
    RETURN QUERY
    SELECT 
        b.id::TEXT,
        b.title,
        b.author,
        b.genre
    FROM books b
    WHERE b.title IS NOT NULL 
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 5: Test if the simple function works
SELECT 'Testing simple function:' as info;
SELECT * FROM get_simple_book_recommendations('00000000-0000-0000-0000-000000000000'::UUID, 3);

-- Step 6: Grant permissions on the simple function
GRANT EXECUTE ON FUNCTION get_simple_book_recommendations(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_simple_book_recommendations(UUID, INTEGER) TO anon;

SELECT '=== SIMPLE FUNCTION TEST COMPLETE ===' as info;
