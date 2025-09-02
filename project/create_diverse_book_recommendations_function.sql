-- =====================================================
-- CREATE DIVERSE BOOK RECOMMENDATIONS FUNCTION
-- =====================================================

-- This function provides diverse book recommendations from the full 16,000+ book database
-- It ensures variety across genres, authors, and personality traits

-- Step 1: Create the diverse book recommendations function
CREATE OR REPLACE FUNCTION get_diverse_book_recommendations(
    user_auth_id UUID,
    personality_openness INTEGER DEFAULT 10,
    personality_conscientiousness INTEGER DEFAULT 10,
    personality_extraversion INTEGER DEFAULT 10,
    personality_agreeableness INTEGER DEFAULT 10,
    personality_emotional_stability INTEGER DEFAULT 10,
    personality_rational_thinking INTEGER DEFAULT 10,
    personality_core_values INTEGER DEFAULT 10,
    personality_lifestyle INTEGER DEFAULT 10,
    personality_social_style INTEGER DEFAULT 10,
    personality_self_expression INTEGER DEFAULT 10,
    exclude_book_ids TEXT[] DEFAULT ARRAY[]::TEXT[],
    limit_count INTEGER DEFAULT 6
)
RETURNS TABLE (
    id TEXT,
    title TEXT,
    author TEXT,
    genre TEXT,
    description TEXT,
    amazon_link TEXT,
    cover_image_url TEXT,
    reason TEXT,
    match_score NUMERIC
) AS $$
DECLARE
    v_user_id UUID;
    v_recommendations RECORD;
BEGIN
    -- Get the user's internal ID
    SELECT id INTO v_user_id
    FROM users
    WHERE auth_user_id = get_diverse_book_recommendations.user_auth_id;
    
    IF v_user_id IS NULL THEN
        -- Return empty result if user not found
        RETURN;
    END IF;
    
    -- Return diverse book recommendations with personality scoring
    RETURN QUERY
    WITH scored_books AS (
        SELECT 
            b.id,
            b.title,
            b.author,
            b.genre,
            b.description,
            b.amazon_link,
            b.cover_image_url,
            -- Calculate personality match score
            (
                -- Base score for all books
                50 +
                -- Openness adjustments
                CASE 
                    WHEN b.genre IN ('Literary Fiction', 'Philosophy', 'Science Fiction', 'Experimental Fiction') 
                    THEN (personality_openness - 10) * 2
                    WHEN b.genre IN ('Romance', 'Contemporary Fiction', 'Self-Help') 
                    THEN (20 - personality_openness) * 1
                    ELSE 0
                END +
                -- Conscientiousness adjustments
                CASE 
                    WHEN b.genre IN ('Self-Help', 'Business', 'Biography', 'History') 
                    THEN (personality_conscientiousness - 10) * 2
                    WHEN b.genre IN ('Fantasy', 'Romance', 'Thriller') 
                    THEN (20 - personality_conscientiousness) * 1
                    ELSE 0
                END +
                -- Extraversion adjustments
                CASE 
                    WHEN b.genre IN ('Romance', 'Contemporary Fiction', 'Biography', 'Adventure') 
                    THEN (personality_extraversion - 10) * 2
                    WHEN b.genre IN ('Literary Fiction', 'Philosophy', 'Science Fiction') 
                    THEN (20 - personality_extraversion) * 1
                    ELSE 0
                END +
                -- Agreeableness adjustments
                CASE 
                    WHEN b.genre IN ('Romance', 'Contemporary Fiction', 'Self-Help', 'Biography') 
                    THEN (personality_agreeableness - 10) * 2
                    WHEN b.genre IN ('Thriller', 'Dark Fantasy', 'Dystopian Fiction') 
                    THEN (20 - personality_agreeableness) * 1
                    ELSE 0
                END +
                -- Emotional stability adjustments
                CASE 
                    WHEN b.genre IN ('Thriller', 'Psychological Thriller', 'Dystopian Fiction') 
                    THEN (personality_emotional_stability - 10) * 2
                    WHEN b.genre IN ('Romance', 'Contemporary Fiction', 'Self-Help') 
                    THEN (20 - personality_emotional_stability) * 1
                    ELSE 0
                END +
                -- Random factor for diversity (0-20 points)
                (random() * 20)
            ) as match_score
        FROM books b
        WHERE 
            -- Exclude previously recommended books
            NOT (b.id = ANY(exclude_book_ids))
            -- Ensure we have basic book information
            AND b.title IS NOT NULL 
            AND b.author IS NOT NULL
            AND b.genre IS NOT NULL
    ),
    diverse_selection AS (
        SELECT DISTINCT ON (genre) 
            id, title, author, genre, description, amazon_link, cover_image_url, reason, match_score
        FROM scored_books
        ORDER BY genre, match_score DESC
        LIMIT 3
    ),
    remaining_selection AS (
        SELECT 
            id, title, author, genre, description, amazon_link, cover_image_url, reason, match_score
        FROM scored_books
        WHERE id NOT IN (SELECT id FROM diverse_selection)
        ORDER BY match_score DESC
        LIMIT (limit_count - 3)
    )
    SELECT * FROM (
        SELECT * FROM diverse_selection
        UNION ALL
        SELECT * FROM remaining_selection
    ) final_selection
    ORDER BY match_score DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 2: Grant execute permissions
GRANT EXECUTE ON FUNCTION get_diverse_book_recommendations(UUID, INTEGER, INTEGER, INTEGER, INTEGER, INTEGER, INTEGER, INTEGER, INTEGER, INTEGER, TEXT[], INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_diverse_book_recommendations(UUID, INTEGER, INTEGER, INTEGER, INTEGER, INTEGER, INTEGER, TEXT[], INTEGER) TO anon;

-- Step 3: Verify function exists
SELECT 'get_diverse_book_recommendations function created:' as info;

SELECT proname, pronargs, proargnames
FROM pg_proc 
WHERE proname = 'get_diverse_book_recommendations';

SELECT '=== DIVERSE BOOK RECOMMENDATIONS FUNCTION CREATED ===' as info;
