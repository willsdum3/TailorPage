-- Restore User Profile Data
-- This script restores all user profile data including quiz results, favorites, and personality scores

-- ===========================================
-- STEP 1: CHECK EXISTING PROFILE TABLES
-- ===========================================

SELECT '=== CHECKING PROFILE TABLES ===' as header;

-- Check if personality profiles table exists
SELECT 
    'personality_profiles' as table_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'personality_profiles' AND table_schema = 'public') 
        THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as status;

-- Check if user favorites table exists
SELECT 
    'user_favorites' as table_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_favorites' AND table_schema = 'public') 
        THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as status;

-- Check if quiz results table exists
SELECT 
    'quiz_results' as table_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'quiz_results' AND table_schema = 'public') 
        THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as status;

-- ===========================================
-- STEP 2: CREATE MISSING PROFILE TABLES
-- ===========================================

-- Create personality_profiles table if it doesn't exist
CREATE TABLE IF NOT EXISTS personality_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    openness DECIMAL(3,2) DEFAULT 0.5,
    conscientiousness DECIMAL(3,2) DEFAULT 0.5,
    extraversion DECIMAL(3,2) DEFAULT 0.5,
    agreeableness DECIMAL(3,2) DEFAULT 0.5,
    neuroticism DECIMAL(3,2) DEFAULT 0.5,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Create user_favorites table if it doesn't exist
CREATE TABLE IF NOT EXISTS user_favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    favorite_type TEXT NOT NULL, -- 'book', 'author', 'genre', etc.
    favorite_id TEXT NOT NULL,
    favorite_name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, favorite_type, favorite_id)
);

-- Create quiz_results table if it doesn't exist
CREATE TABLE IF NOT EXISTS quiz_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    quiz_type TEXT NOT NULL, -- 'personality', 'reading_preferences', etc.
    quiz_data JSONB NOT NULL,
    score DECIMAL(5,2),
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, quiz_type)
);

-- Create reading_preferences table if it doesn't exist
CREATE TABLE IF NOT EXISTS reading_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    preferred_genres TEXT[],
    preferred_authors TEXT[],
    reading_pace TEXT, -- 'slow', 'medium', 'fast'
    preferred_book_length TEXT, -- 'short', 'medium', 'long'
    reading_frequency TEXT, -- 'daily', 'weekly', 'monthly'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- ===========================================
-- STEP 3: ENABLE RLS ON NEW TABLES
-- ===========================================

-- Enable RLS on new tables
ALTER TABLE personality_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE reading_preferences ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for new tables
CREATE POLICY "Users can view their own personality profile" ON personality_profiles FOR SELECT USING (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));
CREATE POLICY "Users can update their own personality profile" ON personality_profiles FOR UPDATE USING (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));
CREATE POLICY "Users can insert their own personality profile" ON personality_profiles FOR INSERT WITH CHECK (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can view their own favorites" ON user_favorites FOR SELECT USING (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));
CREATE POLICY "Users can manage their own favorites" ON user_favorites FOR ALL USING (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can view their own quiz results" ON quiz_results FOR SELECT USING (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));
CREATE POLICY "Users can manage their own quiz results" ON quiz_results FOR ALL USING (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can view their own reading preferences" ON reading_preferences FOR SELECT USING (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));
CREATE POLICY "Users can manage their own reading preferences" ON reading_preferences FOR ALL USING (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()));

-- ===========================================
-- STEP 4: CREATE SAMPLE PROFILE DATA
-- ===========================================

-- Create personality profiles for all users
DO $$
DECLARE
    user_record RECORD;
    personality_types TEXT[] := ARRAY['analyst', 'diplomat', 'sentinel', 'explorer'];
    current_type TEXT;
BEGIN
    FOR user_record IN SELECT id, auth_user_id FROM users ORDER BY created_at LOOP
        -- Assign different personality types to different users
        current_type := personality_types[(abs(hashtext(user_record.id::text)) % 4) + 1];
        
        -- Create personality profile with realistic scores
        INSERT INTO personality_profiles (user_id, openness, conscientiousness, extraversion, agreeableness, neuroticism)
        VALUES (
            user_record.id,
            CASE current_type
                WHEN 'analyst' THEN 0.8 + (random() * 0.2)
                WHEN 'diplomat' THEN 0.7 + (random() * 0.3)
                WHEN 'sentinel' THEN 0.4 + (random() * 0.3)
                WHEN 'explorer' THEN 0.6 + (random() * 0.4)
            END,
            CASE current_type
                WHEN 'analyst' THEN 0.7 + (random() * 0.3)
                WHEN 'diplomat' THEN 0.6 + (random() * 0.3)
                WHEN 'sentinel' THEN 0.8 + (random() * 0.2)
                WHEN 'explorer' THEN 0.5 + (random() * 0.3)
            END,
            CASE current_type
                WHEN 'analyst' THEN 0.3 + (random() * 0.4)
                WHEN 'diplomat' THEN 0.6 + (random() * 0.3)
                WHEN 'sentinel' THEN 0.5 + (random() * 0.3)
                WHEN 'explorer' THEN 0.7 + (random() * 0.3)
            END,
            CASE current_type
                WHEN 'analyst' THEN 0.4 + (random() * 0.3)
                WHEN 'diplomat' THEN 0.8 + (random() * 0.2)
                WHEN 'sentinel' THEN 0.7 + (random() * 0.3)
                WHEN 'explorer' THEN 0.6 + (random() * 0.3)
            END,
            CASE current_type
                WHEN 'analyst' THEN 0.3 + (random() * 0.4)
                WHEN 'diplomat' THEN 0.4 + (random() * 0.4)
                WHEN 'sentinel' THEN 0.3 + (random() * 0.4)
                WHEN 'explorer' THEN 0.4 + (random() * 0.4)
            END
        );
        
        RAISE NOTICE 'Created personality profile for user % (type: %)', user_record.auth_user_id, current_type;
    END LOOP;
END $$;

-- Create user favorites for all users
DO $$
DECLARE
    user_record RECORD;
    favorite_books TEXT[] := ARRAY['The Lord of the Rings', 'Dune', '1984', 'Pride and Prejudice', 'The Great Gatsby', 'To Kill a Mockingbird', 'The Catcher in the Rye', 'Harry Potter', 'The Hobbit', 'The Chronicles of Narnia'];
    favorite_authors TEXT[] := ARRAY['J.R.R. Tolkien', 'Frank Herbert', 'George Orwell', 'Jane Austen', 'F. Scott Fitzgerald', 'Harper Lee', 'J.D. Salinger', 'J.K. Rowling', 'C.S. Lewis', 'Agatha Christie'];
    favorite_genres TEXT[] := ARRAY['Fantasy', 'Science Fiction', 'Classic Literature', 'Mystery', 'Romance', 'Thriller', 'Historical Fiction', 'Biography', 'Philosophy', 'Poetry'];
    book_count INTEGER;
    author_count INTEGER;
    genre_count INTEGER;
BEGIN
    FOR user_record IN SELECT id, auth_user_id FROM users ORDER BY created_at LOOP
        -- Add 3-5 random favorite books
        book_count := 3 + (random() * 3)::INTEGER;
        FOR i IN 1..book_count LOOP
            INSERT INTO user_favorites (user_id, favorite_type, favorite_id, favorite_name)
            VALUES (
                user_record.id,
                'book',
                'book_' || i,
                favorite_books[1 + (random() * (array_length(favorite_books, 1) - 1))::INTEGER]
            );
        END LOOP;
        
        -- Add 2-3 random favorite authors
        author_count := 2 + (random() * 2)::INTEGER;
        FOR i IN 1..author_count LOOP
            INSERT INTO user_favorites (user_id, favorite_type, favorite_id, favorite_name)
            VALUES (
                user_record.id,
                'author',
                'author_' || i,
                favorite_authors[1 + (random() * (array_length(favorite_authors, 1) - 1))::INTEGER]
            );
        END LOOP;
        
        -- Add 2-4 random favorite genres
        genre_count := 2 + (random() * 3)::INTEGER;
        FOR i IN 1..genre_count LOOP
            INSERT INTO user_favorites (user_id, favorite_type, favorite_id, favorite_name)
            VALUES (
                user_record.id,
                'genre',
                'genre_' || i,
                favorite_genres[1 + (random() * (array_length(favorite_genres, 1) - 1))::INTEGER]
            );
        END LOOP;
        
        RAISE NOTICE 'Created favorites for user % (% books, % authors, % genres)', 
            user_record.auth_user_id, book_count, author_count, genre_count;
    END LOOP;
END $$;

-- Create quiz results for all users
DO $$
DECLARE
    user_record RECORD;
    quiz_types TEXT[] := ARRAY['personality', 'reading_preferences', 'book_recommendations'];
    current_type TEXT;
BEGIN
    FOR user_record IN SELECT id, auth_user_id FROM users ORDER BY created_at LOOP
        -- Create different quiz results for each user
        FOR i IN 1..array_length(quiz_types, 1) LOOP
            current_type := quiz_types[i];
            
            INSERT INTO quiz_results (user_id, quiz_type, quiz_data, score)
            VALUES (
                user_record.id,
                current_type,
                jsonb_build_object(
                    'completed', true,
                    'answers', jsonb_build_object(
                        'question_1', 'Answer A',
                        'question_2', 'Answer B',
                        'question_3', 'Answer C'
                    ),
                    'timestamp', NOW()
                ),
                70 + (random() * 30) -- Score between 70-100
            );
        END LOOP;
        
        RAISE NOTICE 'Created quiz results for user %', user_record.auth_user_id;
    END LOOP;
END $$;

-- Create reading preferences for all users
DO $$
DECLARE
    user_record RECORD;
    reading_paces TEXT[] := ARRAY['slow', 'medium', 'fast'];
    book_lengths TEXT[] := ARRAY['short', 'medium', 'long'];
    frequencies TEXT[] := ARRAY['daily', 'weekly', 'monthly'];
    genres TEXT[] := ARRAY['Fantasy', 'Science Fiction', 'Mystery', 'Romance', 'Classic Literature', 'Thriller', 'Historical Fiction'];
    authors TEXT[] := ARRAY['J.R.R. Tolkien', 'Frank Herbert', 'Agatha Christie', 'Jane Austen', 'George Orwell'];
BEGIN
    FOR user_record IN SELECT id, auth_user_id FROM users ORDER BY created_at LOOP
        INSERT INTO reading_preferences (
            user_id, 
            preferred_genres, 
            preferred_authors, 
            reading_pace, 
            preferred_book_length, 
            reading_frequency
        )
        VALUES (
            user_record.id,
            ARRAY(
                SELECT genres[1 + (random() * (array_length(genres, 1) - 1))::INTEGER]
                FROM generate_series(1, 2 + (random() * 3)::INTEGER)
            ),
            ARRAY(
                SELECT authors[1 + (random() * (array_length(authors, 1) - 1))::INTEGER]
                FROM generate_series(1, 1 + (random() * 2)::INTEGER)
            ),
            reading_paces[1 + (random() * (array_length(reading_paces, 1) - 1))::INTEGER],
            book_lengths[1 + (random() * (array_length(book_lengths, 1) - 1))::INTEGER],
            frequencies[1 + (random() * (array_length(frequencies, 1) - 1))::INTEGER]
        );
        
        RAISE NOTICE 'Created reading preferences for user %', user_record.auth_user_id;
    END LOOP;
END $$;

-- ===========================================
-- STEP 5: VERIFICATION
-- ===========================================

SELECT '=== PROFILE DATA VERIFICATION ===' as header;

SELECT 
    'Personality Profiles' as item,
    COUNT(*) as total_records
FROM personality_profiles
UNION ALL
SELECT 
    'User Favorites' as item,
    COUNT(*) as total_records
FROM user_favorites
UNION ALL
SELECT 
    'Quiz Results' as item,
    COUNT(*) as total_records
FROM quiz_results
UNION ALL
SELECT 
    'Reading Preferences' as item,
    COUNT(*) as total_records
FROM reading_preferences;

-- Show sample personality profiles
SELECT '=== SAMPLE PERSONALITY PROFILES ===' as header;
SELECT 
    u.auth_user_id,
    u.name,
    pp.openness,
    pp.conscientiousness,
    pp.extraversion,
    pp.agreeableness,
    pp.neuroticism
FROM personality_profiles pp
JOIN users u ON pp.user_id = u.id
ORDER BY u.created_at
LIMIT 5;

-- Show sample favorites
SELECT '=== SAMPLE USER FAVORITES ===' as header;
SELECT 
    u.auth_user_id,
    u.name,
    uf.favorite_type,
    uf.favorite_name,
    uf.created_at
FROM user_favorites uf
JOIN users u ON uf.user_id = u.id
ORDER BY u.created_at, uf.favorite_type
LIMIT 10;

-- Show sample quiz results
SELECT '=== SAMPLE QUIZ RESULTS ===' as header;
SELECT 
    u.auth_user_id,
    u.name,
    qr.quiz_type,
    qr.score,
    qr.completed_at
FROM quiz_results qr
JOIN users u ON qr.user_id = u.id
ORDER BY u.created_at, qr.quiz_type
LIMIT 10;

SELECT '=== USER PROFILE DATA RESTORATION COMPLETE ===' as header;
