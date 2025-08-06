-- Tailor Page App Database Schema for Supabase
-- SQL tables for managing user book favorites

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (extends Clerk user data)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), -- Supabase auth.users.id
    clerk_id VARCHAR(255) UNIQUE NOT NULL, -- Clerk user ID
    name VARCHAR(255) NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    image_url VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Books table (stores book information)
CREATE TABLE books (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(500) NOT NULL,
    author VARCHAR(255) NOT NULL,
    genre VARCHAR(100) NOT NULL,
    description TEXT,
    amazon_link VARCHAR(500),
    cover_image_url VARCHAR(500),
    isbn VARCHAR(20),
    published_date DATE,
    page_count INTEGER,
    language VARCHAR(50) DEFAULT 'English',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_isbn CHECK (isbn ~* '^[0-9-]{10,17}$' OR isbn IS NULL),
    CONSTRAINT valid_page_count CHECK (page_count > 0 OR page_count IS NULL)
);

-- User Favorites table (junction table for user-book relationships)
CREATE TABLE user_favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    book_id UUID NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    date_added TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT, -- Optional user notes about the book
    rating SMALLINT CHECK (rating >= 1 AND rating <= 5), -- Optional user rating
    is_read BOOLEAN DEFAULT FALSE, -- Track if user has read the book
    read_date DATE, -- When the user finished reading
    UNIQUE(user_id, book_id),
    CONSTRAINT valid_read_date CHECK (read_date IS NULL OR read_date <= CURRENT_DATE)
);

-- User Personality Profiles table
CREATE TABLE user_personality_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    openness DECIMAL(3,1) NOT NULL CHECK (openness >= 0 AND openness <= 20),
    conscientiousness DECIMAL(3,1) NOT NULL CHECK (conscientiousness >= 0 AND conscientiousness <= 20),
    extraversion DECIMAL(3,1) NOT NULL CHECK (extraversion >= 0 AND extraversion <= 20),
    agreeableness DECIMAL(3,1) NOT NULL CHECK (agreeableness >= 0 AND agreeableness <= 20),
    emotional_stability DECIMAL(3,1) NOT NULL CHECK (emotional_stability >= 0 AND emotional_stability <= 20),
    rational_thinking DECIMAL(3,1) NOT NULL CHECK (rational_thinking >= 0 AND rational_thinking <= 20),
    core_values DECIMAL(3,1) NOT NULL CHECK (core_values >= 0 AND core_values <= 20),
    lifestyle DECIMAL(3,1) NOT NULL CHECK (lifestyle >= 0 AND lifestyle <= 20),
    social_style DECIMAL(3,1) NOT NULL CHECK (social_style >= 0 AND social_style <= 20),
    self_expression DECIMAL(3,1) NOT NULL CHECK (self_expression >= 0 AND self_expression <= 20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id) -- One profile per user
);

-- Book Recommendations table (stores AI-generated recommendations)
CREATE TABLE book_recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    book_id UUID NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    reason TEXT NOT NULL, -- AI explanation for why this book was recommended
    recommendation_score DECIMAL(3,2) CHECK (recommendation_score >= 0 AND recommendation_score <= 1),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, book_id) -- One recommendation per user-book combination
);

-- Reading Lists table (for organizing favorites into collections)
CREATE TABLE reading_lists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_list_name CHECK (LENGTH(TRIM(name)) > 0)
);

-- Reading List Items table (books in reading lists)
CREATE TABLE reading_list_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reading_list_id UUID NOT NULL REFERENCES reading_lists(id) ON DELETE CASCADE,
    book_id UUID NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    position INTEGER NOT NULL, -- Order within the list
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(reading_list_id, book_id),
    UNIQUE(reading_list_id, position),
    CONSTRAINT valid_position CHECK (position > 0)
);

-- User Activity Log table (for tracking user interactions)
CREATE TABLE user_activity_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    activity_type TEXT NOT NULL CHECK (activity_type IN ('favorite_added', 'favorite_removed', 'book_read', 'rating_added', 'list_created', 'list_updated', 'profile_updated', 'quiz_completed')),
    book_id UUID REFERENCES books(id) ON DELETE SET NULL,
    reading_list_id UUID REFERENCES reading_lists(id) ON DELETE SET NULL,
    metadata JSONB, -- Additional activity-specific data
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_users_clerk_id ON users(clerk_id);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_books_title ON books(title);
CREATE INDEX idx_books_author ON books(author);
CREATE INDEX idx_books_genre ON books(genre);
CREATE INDEX idx_books_isbn ON books(isbn);
CREATE INDEX idx_user_favorites_user_id ON user_favorites(user_id);
CREATE INDEX idx_user_favorites_book_id ON user_favorites(book_id);
CREATE INDEX idx_user_favorites_date_added ON user_favorites(date_added);
CREATE INDEX idx_user_favorites_is_read ON user_favorites(is_read);
CREATE INDEX idx_user_personality_profiles_user_id ON user_personality_profiles(user_id);
CREATE INDEX idx_book_recommendations_user_id ON book_recommendations(user_id);
CREATE INDEX idx_book_recommendations_book_id ON book_recommendations(book_id);
CREATE INDEX idx_reading_lists_user_id ON reading_lists(user_id);
CREATE INDEX idx_reading_lists_is_public ON reading_lists(is_public);
CREATE INDEX idx_reading_list_items_reading_list_id ON reading_list_items(reading_list_id);
CREATE INDEX idx_reading_list_items_position ON reading_list_items(position);
CREATE INDEX idx_user_activity_log_user_id ON user_activity_log(user_id);
CREATE INDEX idx_user_activity_log_activity_type ON user_activity_log(activity_type);
CREATE INDEX idx_user_activity_log_created_at ON user_activity_log(created_at);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_books_updated_at BEFORE UPDATE ON books FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_personality_profiles_updated_at BEFORE UPDATE ON user_personality_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_reading_lists_updated_at BEFORE UPDATE ON reading_lists FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE books ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_personality_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE book_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE reading_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE reading_list_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_activity_log ENABLE ROW LEVEL SECURITY;

-- RLS Policies for users table
CREATE POLICY "Users can view their own profile" ON users
    FOR SELECT USING (auth.uid()::text = clerk_id);

CREATE POLICY "Users can update their own profile" ON users
    FOR UPDATE USING (auth.uid()::text = clerk_id);

CREATE POLICY "Users can insert their own profile" ON users
    FOR INSERT WITH CHECK (auth.uid()::text = clerk_id);

-- RLS Policies for books table (public read access)
CREATE POLICY "Anyone can view books" ON books
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can insert books" ON books
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- RLS Policies for user_favorites table
CREATE POLICY "Users can view their own favorites" ON user_favorites
    FOR SELECT USING (
        user_id IN (
            SELECT id FROM users WHERE clerk_id = auth.uid()::text
        )
    );

CREATE POLICY "Users can insert their own favorites" ON user_favorites
    FOR INSERT WITH CHECK (
        user_id IN (
            SELECT id FROM users WHERE clerk_id = auth.uid()::text
        )
    );

CREATE POLICY "Users can update their own favorites" ON user_favorites
    FOR UPDATE USING (
        user_id IN (
            SELECT id FROM users WHERE clerk_id = auth.uid()::text
        )
    );

CREATE POLICY "Users can delete their own favorites" ON user_favorites
    FOR DELETE USING (
        user_id IN (
            SELECT id FROM users WHERE clerk_id = auth.uid()::text
        )
    );

-- RLS Policies for user_personality_profiles table
CREATE POLICY "Users can view their own personality profile" ON user_personality_profiles
    FOR SELECT USING (
        user_id IN (
            SELECT id FROM users WHERE clerk_id = auth.uid()::text
        )
    );

CREATE POLICY "Users can insert their own personality profile" ON user_personality_profiles
    FOR INSERT WITH CHECK (
        user_id IN (
            SELECT id FROM users WHERE clerk_id = auth.uid()::text
        )
    );

CREATE POLICY "Users can update their own personality profile" ON user_personality_profiles
    FOR UPDATE USING (
        user_id IN (
            SELECT id FROM users WHERE clerk_id = auth.uid()::text
        )
    );

-- RLS Policies for book_recommendations table
CREATE POLICY "Users can view their own recommendations" ON book_recommendations
    FOR SELECT USING (
        user_id IN (
            SELECT id FROM users WHERE clerk_id = auth.uid()::text
        )
    );

CREATE POLICY "Users can insert their own recommendations" ON book_recommendations
    FOR INSERT WITH CHECK (
        user_id IN (
            SELECT id FROM users WHERE clerk_id = auth.uid()::text
        )
    );

CREATE POLICY "Users can delete their own recommendations" ON book_recommendations
    FOR DELETE USING (
        user_id IN (
            SELECT id FROM users WHERE clerk_id = auth.uid()::text
        )
    );

-- RLS Policies for reading_lists table
CREATE POLICY "Users can view their own reading lists" ON reading_lists
    FOR SELECT USING (
        user_id IN (
            SELECT id FROM users WHERE clerk_id = auth.uid()::text
        )
    );

CREATE POLICY "Users can view public reading lists" ON reading_lists
    FOR SELECT USING (is_public = true);

CREATE POLICY "Users can insert their own reading lists" ON reading_lists
    FOR INSERT WITH CHECK (
        user_id IN (
            SELECT id FROM users WHERE clerk_id = auth.uid()::text
        )
    );

CREATE POLICY "Users can update their own reading lists" ON reading_lists
    FOR UPDATE USING (
        user_id IN (
            SELECT id FROM users WHERE clerk_id = auth.uid()::text
        )
    );

CREATE POLICY "Users can delete their own reading lists" ON reading_lists
    FOR DELETE USING (
        user_id IN (
            SELECT id FROM users WHERE clerk_id = auth.uid()::text
        )
    );

-- RLS Policies for reading_list_items table
CREATE POLICY "Users can view items in their own reading lists" ON reading_list_items
    FOR SELECT USING (
        reading_list_id IN (
            SELECT id FROM reading_lists WHERE user_id IN (
                SELECT id FROM users WHERE clerk_id = auth.uid()::text
            )
        )
    );

CREATE POLICY "Users can view items in public reading lists" ON reading_list_items
    FOR SELECT USING (
        reading_list_id IN (
            SELECT id FROM reading_lists WHERE is_public = true
        )
    );

CREATE POLICY "Users can insert items in their own reading lists" ON reading_list_items
    FOR INSERT WITH CHECK (
        reading_list_id IN (
            SELECT id FROM reading_lists WHERE user_id IN (
                SELECT id FROM users WHERE clerk_id = auth.uid()::text
            )
        )
    );

CREATE POLICY "Users can update items in their own reading lists" ON reading_list_items
    FOR UPDATE USING (
        reading_list_id IN (
            SELECT id FROM reading_lists WHERE user_id IN (
                SELECT id FROM users WHERE clerk_id = auth.uid()::text
            )
        )
    );

CREATE POLICY "Users can delete items in their own reading lists" ON reading_list_items
    FOR DELETE USING (
        reading_list_id IN (
            SELECT id FROM reading_lists WHERE user_id IN (
                SELECT id FROM users WHERE clerk_id = auth.uid()::text
            )
        )
    );

-- RLS Policies for user_activity_log table
CREATE POLICY "Users can view their own activity" ON user_activity_log
    FOR SELECT USING (
        user_id IN (
            SELECT id FROM users WHERE clerk_id = auth.uid()::text
        )
    );

CREATE POLICY "Users can insert their own activity" ON user_activity_log
    FOR INSERT WITH CHECK (
        user_id IN (
            SELECT id FROM users WHERE clerk_id = auth.uid()::text
        )
    );

-- Create functions for common operations

-- Function to get user favorites with book details
CREATE OR REPLACE FUNCTION get_user_favorites(user_clerk_id TEXT)
RETURNS TABLE (
    favorite_id UUID,
    date_added TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    rating SMALLINT,
    is_read BOOLEAN,
    read_date DATE,
    book_id UUID,
    title VARCHAR(500),
    author VARCHAR(255),
    genre VARCHAR(100),
    description TEXT,
    amazon_link VARCHAR(500),
    cover_image_url VARCHAR(500)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        uf.id as favorite_id,
        uf.date_added,
        uf.notes,
        uf.rating,
        uf.is_read,
        uf.read_date,
        b.id as book_id,
        b.title,
        b.author,
        b.genre,
        b.description,
        b.amazon_link,
        b.cover_image_url
    FROM user_favorites uf
    JOIN books b ON uf.book_id = b.id
    JOIN users u ON uf.user_id = u.id
    WHERE u.clerk_id = user_clerk_id
    ORDER BY uf.date_added DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user reading statistics
CREATE OR REPLACE FUNCTION get_user_reading_stats(user_clerk_id TEXT)
RETURNS TABLE (
    total_favorites BIGINT,
    books_read BIGINT,
    books_to_read BIGINT,
    average_rating NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT as total_favorites,
        COUNT(CASE WHEN uf.is_read = TRUE THEN 1 END)::BIGINT as books_read,
        COUNT(CASE WHEN uf.is_read = FALSE THEN 1 END)::BIGINT as books_to_read,
        AVG(uf.rating) as average_rating
    FROM user_favorites uf
    JOIN users u ON uf.user_id = u.id
    WHERE u.clerk_id = user_clerk_id AND uf.rating IS NOT NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to add a book to favorites
CREATE OR REPLACE FUNCTION add_book_to_favorites(
    user_clerk_id TEXT,
    book_title TEXT,
    book_author TEXT,
    book_genre TEXT,
    book_description TEXT,
    book_amazon_link TEXT,
    book_cover_image_url TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
    book_uuid UUID;
    favorite_uuid UUID;
BEGIN
    -- Get user UUID
    SELECT id INTO user_uuid FROM users WHERE clerk_id = user_clerk_id;
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;

    -- Check if book exists, if not create it
    SELECT id INTO book_uuid FROM books 
    WHERE title = book_title AND author = book_author;
    
    IF book_uuid IS NULL THEN
        INSERT INTO books (title, author, genre, description, amazon_link, cover_image_url)
        VALUES (book_title, book_author, book_genre, book_description, book_amazon_link, book_cover_image_url)
        RETURNING id INTO book_uuid;
    END IF;

    -- Add to favorites
    INSERT INTO user_favorites (user_id, book_id)
    VALUES (user_uuid, book_uuid)
    ON CONFLICT (user_id, book_id) DO NOTHING
    RETURNING id INTO favorite_uuid;

    -- Log activity
    INSERT INTO user_activity_log (user_id, activity_type, book_id, metadata)
    VALUES (user_uuid, 'favorite_added', book_uuid, jsonb_build_object('book_title', book_title));

    RETURN favorite_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Sample data insertion queries
-- Note: Replace placeholder values with actual data

-- Insert sample books
INSERT INTO books (title, author, genre, description, amazon_link, cover_image_url) 
VALUES 
('The Great Gatsby', 'F. Scott Fitzgerald', 'Classic', 'A story of the fabulously wealthy Jay Gatsby and his love for the beautiful Daisy Buchanan.', 'https://amazon.com/gatsby', 'https://example.com/gatsby.jpg'),
('1984', 'George Orwell', 'Dystopian', 'A dystopian social science fiction novel and cautionary tale.', 'https://amazon.com/1984', 'https://example.com/1984.jpg'),
('Pride and Prejudice', 'Jane Austen', 'Romance', 'A romantic novel of manners that follows the emotional development of Elizabeth Bennet.', 'https://amazon.com/pride', 'https://example.com/pride.jpg');

-- Useful queries for the application

-- Get all favorites for a user with book details (using function)
-- SELECT * FROM get_user_favorites('user_clerk_id_here');

-- Get user's reading statistics (using function)
-- SELECT * FROM get_user_reading_stats('user_clerk_id_here');

-- Get books by genre for a user
-- SELECT 
--     b.genre,
--     COUNT(*) as book_count
-- FROM user_favorites uf
-- JOIN books b ON uf.book_id = b.id
-- JOIN users u ON uf.user_id = u.id
-- WHERE u.clerk_id = 'user_clerk_id_here'
-- GROUP BY b.genre
-- ORDER BY book_count DESC;

-- Get recent activity for a user
-- SELECT 
--     ual.activity_type,
--     b.title as book_title,
--     ual.created_at
-- FROM user_activity_log ual
-- LEFT JOIN books b ON ual.book_id = b.id
-- JOIN users u ON ual.user_id = u.id
-- WHERE u.clerk_id = 'user_clerk_id_here'
-- ORDER BY ual.created_at DESC
-- LIMIT 10;

-- Add a book to favorites (using function)
-- SELECT add_book_to_favorites('user_clerk_id_here', 'Book Title', 'Author Name', 'Genre', 'Description', 'Amazon Link', 'Cover URL'); 