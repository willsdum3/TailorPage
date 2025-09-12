-- Debug script to check how poll options are stored and retrieved
-- This will help us understand the data format issue

-- Check the actual data in the polls table
SELECT 
    id,
    title,
    options,
    jsonb_typeof(options) as options_type,
    CASE 
        WHEN jsonb_typeof(options) = 'array' THEN jsonb_array_length(options)
        ELSE NULL
    END as array_length
FROM book_club_polls 
ORDER BY created_at DESC 
LIMIT 5;

-- Check if we can convert the options to array
SELECT 
    id,
    title,
    options,
    jsonb_typeof(options) as original_type,
    CASE 
        WHEN jsonb_typeof(options) = 'string' THEN 
            CASE 
                WHEN (options::text)::jsonb IS NOT NULL THEN 'convertible_to_jsonb'
                ELSE 'not_convertible'
            END
        ELSE 'not_string'
    END as conversion_test
FROM book_club_polls 
ORDER BY created_at DESC 
LIMIT 5;
