-- =====================================================
-- FIX REMOVE_BOOK_FROM_FAVORITES FUNCTION
-- =====================================================

-- This script fixes the remove_book_from_favorites function to avoid parameter conflicts

-- Drop the existing function
DROP FUNCTION IF EXISTS remove_book_from_favorites(UUID, TEXT, TEXT);

-- Create the fixed function
CREATE OR REPLACE FUNCTION remove_book_from_favorites(
    p_auth_user_id UUID,
    p_book_title TEXT,
    p_book_author TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    v_user_uuid UUID;
    v_deleted_count INTEGER;
BEGIN
    -- Get user
    SELECT id INTO v_user_uuid
    FROM users
    WHERE auth_user_id = p_auth_user_id;
    
    IF v_user_uuid IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Remove book from favorites
    DELETE FROM user_favorites
    WHERE user_id = v_user_uuid 
    AND LOWER(book_title) = LOWER(p_book_title)
    AND LOWER(book_author) = LOWER(p_book_author);
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    RETURN v_deleted_count > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION remove_book_from_favorites TO authenticated;
GRANT EXECUTE ON FUNCTION remove_book_from_favorites TO anon;

SELECT '=== REMOVE_BOOK_FROM_FAVORITES FUNCTION FIXED ===' as info;
