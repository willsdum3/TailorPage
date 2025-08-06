-- Quiz Results and Personality Breakdown Schema for Supabase
-- Extends the existing Tailor Page App database schema

-- Quiz Sessions table (tracks each quiz attempt)
CREATE TABLE quiz_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    total_questions INTEGER DEFAULT 0,
    questions_answered INTEGER DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'abandoned')),
    personality_profile_id UUID REFERENCES user_personality_profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, started_at)
);

-- Quiz Questions table (stores the questions used in quizzes)
CREATE TABLE quiz_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_text TEXT NOT NULL,
    question_type TEXT NOT NULL CHECK (question_type IN ('statement', 'book')),
    trait_category TEXT NOT NULL CHECK (trait_category IN ('openness', 'conscientiousness', 'extraversion', 'agreeableness', 'emotional_stability', 'rational_thinking', 'core_values', 'lifestyle', 'social_style', 'self_expression')),
    question_order INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(trait_category, question_order)
);

-- Book Questions table (for book preference questions)
CREATE TABLE book_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_id UUID NOT NULL REFERENCES quiz_questions(id) ON DELETE CASCADE,
    book_title TEXT NOT NULL,
    book_author TEXT NOT NULL,
    book_description TEXT,
    book_cover_url VARCHAR(500),
    book_genre VARCHAR(100),
    amazon_link VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User Quiz Responses table (stores individual question responses)
CREATE TABLE user_quiz_responses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quiz_session_id UUID NOT NULL REFERENCES quiz_sessions(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES quiz_questions(id) ON DELETE CASCADE,
    response_value INTEGER NOT NULL CHECK (response_value >= 1 AND response_value <= 5), -- 1-5 Likert scale
    response_text TEXT, -- For book questions: 'yes' or 'no'
    response_time_seconds INTEGER, -- Time taken to answer in seconds
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(quiz_session_id, question_id)
);

-- Personality Trait Scores table (detailed breakdown of each trait)
CREATE TABLE personality_trait_scores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quiz_session_id UUID NOT NULL REFERENCES quiz_sessions(id) ON DELETE CASCADE,
    trait_name TEXT NOT NULL CHECK (trait_name IN ('openness', 'conscientiousness', 'extraversion', 'agreeableness', 'emotional_stability', 'rational_thinking', 'core_values', 'lifestyle', 'social_style', 'self_expression')),
    raw_score DECIMAL(5,2) NOT NULL, -- Raw score before normalization
    normalized_score DECIMAL(3,1) NOT NULL CHECK (normalized_score >= 0 AND normalized_score <= 20), -- Final score (0-20)
    questions_answered INTEGER NOT NULL DEFAULT 0,
    average_response DECIMAL(3,2), -- Average response value for this trait
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(quiz_session_id, trait_name)
);

-- Personality Insights table (AI-generated insights about personality traits)
CREATE TABLE personality_insights (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quiz_session_id UUID NOT NULL REFERENCES quiz_sessions(id) ON DELETE CASCADE,
    trait_name TEXT NOT NULL CHECK (trait_name IN ('openness', 'conscientiousness', 'extraversion', 'agreeableness', 'emotional_stability', 'rational_thinking', 'core_values', 'lifestyle', 'social_style', 'self_expression')),
    insight_title TEXT NOT NULL,
    insight_description TEXT NOT NULL,
    insight_type TEXT NOT NULL CHECK (insight_type IN ('strength', 'growth_area', 'neutral', 'recommendation')),
    confidence_score DECIMAL(3,2) CHECK (confidence_score >= 0 AND confidence_score <= 1),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Reading Style Analysis table (how personality affects reading preferences)
CREATE TABLE reading_style_analysis (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quiz_session_id UUID NOT NULL REFERENCES quiz_sessions(id) ON DELETE CASCADE,
    reading_style TEXT NOT NULL, -- e.g., 'Analytical', 'Emotional', 'Adventure-seeking', etc.
    style_description TEXT NOT NULL,
    preferred_genres TEXT[], -- Array of preferred genres
    reading_motivations TEXT[], -- Array of reading motivations
    reading_habits TEXT[], -- Array of reading habits
    confidence_score DECIMAL(3,2) CHECK (confidence_score >= 0 AND confidence_score <= 1),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Quiz Progress Tracking table (tracks user progress through quiz)
CREATE TABLE quiz_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quiz_session_id UUID NOT NULL REFERENCES quiz_sessions(id) ON DELETE CASCADE,
    current_question_index INTEGER NOT NULL DEFAULT 0,
    total_questions INTEGER NOT NULL,
    progress_percentage DECIMAL(5,2) NOT NULL DEFAULT 0,
    time_spent_seconds INTEGER DEFAULT 0,
    last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(quiz_session_id)
);

-- Create indexes for better performance
CREATE INDEX idx_quiz_sessions_user_id ON quiz_sessions(user_id);
CREATE INDEX idx_quiz_sessions_status ON quiz_sessions(status);
CREATE INDEX idx_quiz_sessions_completed_at ON quiz_sessions(completed_at);
CREATE INDEX idx_quiz_questions_trait_category ON quiz_questions(trait_category);
CREATE INDEX idx_quiz_questions_is_active ON quiz_questions(is_active);
CREATE INDEX idx_user_quiz_responses_session_id ON user_quiz_responses(quiz_session_id);
CREATE INDEX idx_user_quiz_responses_question_id ON user_quiz_responses(question_id);
CREATE INDEX idx_personality_trait_scores_session_id ON personality_trait_scores(quiz_session_id);
CREATE INDEX idx_personality_trait_scores_trait_name ON personality_trait_scores(trait_name);
CREATE INDEX idx_personality_insights_session_id ON personality_insights(quiz_session_id);
CREATE INDEX idx_personality_insights_trait_name ON personality_insights(trait_name);
CREATE INDEX idx_reading_style_analysis_session_id ON reading_style_analysis(quiz_session_id);
CREATE INDEX idx_quiz_progress_session_id ON quiz_progress(quiz_session_id);

-- Create triggers for updated_at
CREATE TRIGGER update_quiz_sessions_updated_at BEFORE UPDATE ON quiz_sessions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_quiz_questions_updated_at BEFORE UPDATE ON quiz_questions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_book_questions_updated_at BEFORE UPDATE ON book_questions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_quiz_progress_updated_at BEFORE UPDATE ON quiz_progress FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE quiz_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE book_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_quiz_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE personality_trait_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE personality_insights ENABLE ROW LEVEL SECURITY;
ALTER TABLE reading_style_analysis ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_progress ENABLE ROW LEVEL SECURITY;

-- RLS Policies for quiz_sessions table
CREATE POLICY "Users can view their own quiz sessions" ON quiz_sessions
    FOR SELECT USING (
        user_id IN (
            SELECT id FROM users WHERE clerk_id = auth.uid()::text
        )
    );

CREATE POLICY "Users can insert their own quiz sessions" ON quiz_sessions
    FOR INSERT WITH CHECK (
        user_id IN (
            SELECT id FROM users WHERE clerk_id = auth.uid()::text
        )
    );

CREATE POLICY "Users can update their own quiz sessions" ON quiz_sessions
    FOR UPDATE USING (
        user_id IN (
            SELECT id FROM users WHERE clerk_id = auth.uid()::text
        )
    );

-- RLS Policies for quiz_questions table (public read access)
CREATE POLICY "Anyone can view quiz questions" ON quiz_questions
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can insert quiz questions" ON quiz_questions
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- RLS Policies for book_questions table (public read access)
CREATE POLICY "Anyone can view book questions" ON book_questions
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can insert book questions" ON book_questions
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- RLS Policies for user_quiz_responses table
CREATE POLICY "Users can view their own quiz responses" ON user_quiz_responses
    FOR SELECT USING (
        quiz_session_id IN (
            SELECT id FROM quiz_sessions WHERE user_id IN (
                SELECT id FROM users WHERE clerk_id = auth.uid()::text
            )
        )
    );

CREATE POLICY "Users can insert their own quiz responses" ON user_quiz_responses
    FOR INSERT WITH CHECK (
        quiz_session_id IN (
            SELECT id FROM quiz_sessions WHERE user_id IN (
                SELECT id FROM users WHERE clerk_id = auth.uid()::text
            )
        )
    );

CREATE POLICY "Users can update their own quiz responses" ON user_quiz_responses
    FOR UPDATE USING (
        quiz_session_id IN (
            SELECT id FROM quiz_sessions WHERE user_id IN (
                SELECT id FROM users WHERE clerk_id = auth.uid()::text
            )
        )
    );

-- RLS Policies for personality_trait_scores table
CREATE POLICY "Users can view their own trait scores" ON personality_trait_scores
    FOR SELECT USING (
        quiz_session_id IN (
            SELECT id FROM quiz_sessions WHERE user_id IN (
                SELECT id FROM users WHERE clerk_id = auth.uid()::text
            )
        )
    );

CREATE POLICY "Users can insert their own trait scores" ON personality_trait_scores
    FOR INSERT WITH CHECK (
        quiz_session_id IN (
            SELECT id FROM quiz_sessions WHERE user_id IN (
                SELECT id FROM users WHERE clerk_id = auth.uid()::text
            )
        )
    );

-- RLS Policies for personality_insights table
CREATE POLICY "Users can view their own insights" ON personality_insights
    FOR SELECT USING (
        quiz_session_id IN (
            SELECT id FROM quiz_sessions WHERE user_id IN (
                SELECT id FROM users WHERE clerk_id = auth.uid()::text
            )
        )
    );

CREATE POLICY "Users can insert their own insights" ON personality_insights
    FOR INSERT WITH CHECK (
        quiz_session_id IN (
            SELECT id FROM quiz_sessions WHERE user_id IN (
                SELECT id FROM users WHERE clerk_id = auth.uid()::text
            )
        )
    );

-- RLS Policies for reading_style_analysis table
CREATE POLICY "Users can view their own reading style" ON reading_style_analysis
    FOR SELECT USING (
        quiz_session_id IN (
            SELECT id FROM quiz_sessions WHERE user_id IN (
                SELECT id FROM users WHERE clerk_id = auth.uid()::text
            )
        )
    );

CREATE POLICY "Users can insert their own reading style" ON reading_style_analysis
    FOR INSERT WITH CHECK (
        quiz_session_id IN (
            SELECT id FROM quiz_sessions WHERE user_id IN (
                SELECT id FROM users WHERE clerk_id = auth.uid()::text
            )
        )
    );

-- RLS Policies for quiz_progress table
CREATE POLICY "Users can view their own quiz progress" ON quiz_progress
    FOR SELECT USING (
        quiz_session_id IN (
            SELECT id FROM quiz_sessions WHERE user_id IN (
                SELECT id FROM users WHERE clerk_id = auth.uid()::text
            )
        )
    );

CREATE POLICY "Users can insert their own quiz progress" ON quiz_progress
    FOR INSERT WITH CHECK (
        quiz_session_id IN (
            SELECT id FROM quiz_sessions WHERE user_id IN (
                SELECT id FROM users WHERE clerk_id = auth.uid()::text
            )
        )
    );

CREATE POLICY "Users can update their own quiz progress" ON quiz_progress
    FOR UPDATE USING (
        quiz_session_id IN (
            SELECT id FROM quiz_sessions WHERE user_id IN (
                SELECT id FROM users WHERE clerk_id = auth.uid()::text
            )
        )
    );

-- Create functions for common operations

-- Function to start a new quiz session
CREATE OR REPLACE FUNCTION start_quiz_session(user_clerk_id TEXT)
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
    session_uuid UUID;
BEGIN
    -- Get user UUID
    SELECT id INTO user_uuid FROM users WHERE clerk_id = user_clerk_id;
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;

    -- Create new quiz session
    INSERT INTO quiz_sessions (user_id, status)
    VALUES (user_uuid, 'in_progress')
    RETURNING id INTO session_uuid;

    -- Initialize quiz progress
    INSERT INTO quiz_progress (quiz_session_id, current_question_index, total_questions, progress_percentage)
    VALUES (session_uuid, 0, (SELECT COUNT(*) FROM quiz_questions WHERE is_active = true), 0);

    -- Log activity
    INSERT INTO user_activity_log (user_id, activity_type, metadata)
    VALUES (user_uuid, 'quiz_started', jsonb_build_object('session_id', session_uuid));

    RETURN session_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to save quiz response
CREATE OR REPLACE FUNCTION save_quiz_response(
    session_uuid UUID,
    question_uuid UUID,
    response_val INTEGER,
    response_txt TEXT DEFAULT NULL,
    response_time_sec INTEGER DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    response_uuid UUID;
    user_uuid UUID;
BEGIN
    -- Get user UUID from session
    SELECT user_id INTO user_uuid FROM quiz_sessions WHERE id = session_uuid;
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'Quiz session not found';
    END IF;

    -- Save response
    INSERT INTO user_quiz_responses (quiz_session_id, question_id, response_value, response_text, response_time_seconds)
    VALUES (session_uuid, question_uuid, response_val, response_txt, response_time_sec)
    ON CONFLICT (quiz_session_id, question_id) 
    DO UPDATE SET 
        response_value = EXCLUDED.response_value,
        response_text = EXCLUDED.response_text,
        response_time_seconds = EXCLUDED.response_time_seconds,
        created_at = NOW()
    RETURNING id INTO response_uuid;

    -- Update quiz progress
    UPDATE quiz_progress 
    SET 
        current_question_index = (
            SELECT COUNT(*) FROM user_quiz_responses WHERE quiz_session_id = session_uuid
        ),
        progress_percentage = (
            SELECT (COUNT(*)::DECIMAL / total_questions * 100) 
            FROM user_quiz_responses 
            CROSS JOIN quiz_progress 
            WHERE quiz_session_id = session_uuid
        ),
        time_spent_seconds = time_spent_seconds + COALESCE(response_time_sec, 0),
        last_activity_at = NOW(),
        updated_at = NOW()
    WHERE quiz_session_id = session_uuid;

    RETURN response_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to complete quiz and calculate personality scores
CREATE OR REPLACE FUNCTION complete_quiz_session(session_uuid UUID)
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
    profile_uuid UUID;
    trait_record RECORD;
BEGIN
    -- Get user UUID from session
    SELECT user_id INTO user_uuid FROM quiz_sessions WHERE id = session_uuid;
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'Quiz session not found';
    END IF;

    -- Mark session as completed
    UPDATE quiz_sessions 
    SET 
        status = 'completed',
        completed_at = NOW(),
        questions_answered = (SELECT COUNT(*) FROM user_quiz_responses WHERE quiz_session_id = session_uuid),
        updated_at = NOW()
    WHERE id = session_uuid;

    -- Calculate personality trait scores
    FOR trait_record IN 
        SELECT 
            qq.trait_category,
            COUNT(uqr.id) as questions_answered,
            AVG(uqr.response_value) as avg_response,
            SUM(uqr.response_value) as raw_score
        FROM quiz_questions qq
        LEFT JOIN user_quiz_responses uqr ON qq.id = uqr.question_id AND uqr.quiz_session_id = session_uuid
        WHERE qq.is_active = true
        GROUP BY qq.trait_category
    LOOP
        -- Insert trait scores (normalize to 0-20 scale)
        INSERT INTO personality_trait_scores (
            quiz_session_id, 
            trait_name, 
            raw_score, 
            normalized_score, 
            questions_answered, 
            average_response
        )
        VALUES (
            session_uuid,
            trait_record.trait_category,
            trait_record.raw_score,
            LEAST(20, GREATEST(0, (trait_record.raw_score / trait_record.questions_answered) * 4)), -- Normalize to 0-20
            trait_record.questions_answered,
            trait_record.avg_response
        );
    END LOOP;

    -- Create personality profile
    INSERT INTO user_personality_profiles (
        user_id,
        openness,
        conscientiousness,
        extraversion,
        agreeableness,
        emotional_stability,
        rational_thinking,
        core_values,
        lifestyle,
        social_style,
        self_expression
    )
    SELECT 
        user_uuid,
        COALESCE(pts_openness.normalized_score, 10.0),
        COALESCE(pts_conscientiousness.normalized_score, 10.0),
        COALESCE(pts_extraversion.normalized_score, 10.0),
        COALESCE(pts_agreeableness.normalized_score, 10.0),
        COALESCE(pts_emotional_stability.normalized_score, 10.0),
        COALESCE(pts_rational_thinking.normalized_score, 10.0),
        COALESCE(pts_core_values.normalized_score, 10.0),
        COALESCE(pts_lifestyle.normalized_score, 10.0),
        COALESCE(pts_social_style.normalized_score, 10.0),
        COALESCE(pts_self_expression.normalized_score, 10.0)
    FROM quiz_sessions qs
    LEFT JOIN personality_trait_scores pts_openness ON qs.id = pts_openness.quiz_session_id AND pts_openness.trait_name = 'openness'
    LEFT JOIN personality_trait_scores pts_conscientiousness ON qs.id = pts_conscientiousness.quiz_session_id AND pts_conscientiousness.trait_name = 'conscientiousness'
    LEFT JOIN personality_trait_scores pts_extraversion ON qs.id = pts_extraversion.quiz_session_id AND pts_extraversion.trait_name = 'extraversion'
    LEFT JOIN personality_trait_scores pts_agreeableness ON qs.id = pts_agreeableness.quiz_session_id AND pts_agreeableness.trait_name = 'agreeableness'
    LEFT JOIN personality_trait_scores pts_emotional_stability ON qs.id = pts_emotional_stability.quiz_session_id AND pts_emotional_stability.trait_name = 'emotional_stability'
    LEFT JOIN personality_trait_scores pts_rational_thinking ON qs.id = pts_rational_thinking.quiz_session_id AND pts_rational_thinking.trait_name = 'rational_thinking'
    LEFT JOIN personality_trait_scores pts_core_values ON qs.id = pts_core_values.quiz_session_id AND pts_core_values.trait_name = 'core_values'
    LEFT JOIN personality_trait_scores pts_lifestyle ON qs.id = pts_lifestyle.quiz_session_id AND pts_lifestyle.trait_name = 'lifestyle'
    LEFT JOIN personality_trait_scores pts_social_style ON qs.id = pts_social_style.quiz_session_id AND pts_social_style.trait_name = 'social_style'
    LEFT JOIN personality_trait_scores pts_self_expression ON qs.id = pts_self_expression.quiz_session_id AND pts_self_expression.trait_name = 'self_expression'
    WHERE qs.id = session_uuid
    ON CONFLICT (user_id) 
    DO UPDATE SET
        openness = EXCLUDED.openness,
        conscientiousness = EXCLUDED.conscientiousness,
        extraversion = EXCLUDED.extraversion,
        agreeableness = EXCLUDED.agreeableness,
        emotional_stability = EXCLUDED.emotional_stability,
        rational_thinking = EXCLUDED.rational_thinking,
        core_values = EXCLUDED.core_values,
        lifestyle = EXCLUDED.lifestyle,
        social_style = EXCLUDED.social_style,
        self_expression = EXCLUDED.self_expression,
        updated_at = NOW()
    RETURNING id INTO profile_uuid;

    -- Update quiz session with profile reference
    UPDATE quiz_sessions SET personality_profile_id = profile_uuid WHERE id = session_uuid;

    -- Log activity
    INSERT INTO user_activity_log (user_id, activity_type, metadata)
    VALUES (user_uuid, 'quiz_completed', jsonb_build_object('session_id', session_uuid, 'profile_id', profile_uuid));

    RETURN profile_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's latest quiz results
CREATE OR REPLACE FUNCTION get_user_latest_quiz_results(user_clerk_id TEXT)
RETURNS TABLE (
    session_id UUID,
    completed_at TIMESTAMP WITH TIME ZONE,
    total_questions INTEGER,
    questions_answered INTEGER,
    time_spent_seconds INTEGER,
    openness DECIMAL(3,1),
    conscientiousness DECIMAL(3,1),
    extraversion DECIMAL(3,1),
    agreeableness DECIMAL(3,1),
    emotional_stability DECIMAL(3,1),
    rational_thinking DECIMAL(3,1),
    core_values DECIMAL(3,1),
    lifestyle DECIMAL(3,1),
    social_style DECIMAL(3,1),
    self_expression DECIMAL(3,1)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        qs.id as session_id,
        qs.completed_at,
        qs.total_questions,
        qs.questions_answered,
        qp.time_spent_seconds,
        pts_openness.normalized_score as openness,
        pts_conscientiousness.normalized_score as conscientiousness,
        pts_extraversion.normalized_score as extraversion,
        pts_agreeableness.normalized_score as agreeableness,
        pts_emotional_stability.normalized_score as emotional_stability,
        pts_rational_thinking.normalized_score as rational_thinking,
        pts_core_values.normalized_score as core_values,
        pts_lifestyle.normalized_score as lifestyle,
        pts_social_style.normalized_score as social_style,
        pts_self_expression.normalized_score as self_expression
    FROM quiz_sessions qs
    JOIN users u ON qs.user_id = u.id
    LEFT JOIN quiz_progress qp ON qs.id = qp.quiz_session_id
    LEFT JOIN personality_trait_scores pts_openness ON qs.id = pts_openness.quiz_session_id AND pts_openness.trait_name = 'openness'
    LEFT JOIN personality_trait_scores pts_conscientiousness ON qs.id = pts_conscientiousness.quiz_session_id AND pts_conscientiousness.trait_name = 'conscientiousness'
    LEFT JOIN personality_trait_scores pts_extraversion ON qs.id = pts_extraversion.quiz_session_id AND pts_extraversion.trait_name = 'extraversion'
    LEFT JOIN personality_trait_scores pts_agreeableness ON qs.id = pts_agreeableness.quiz_session_id AND pts_agreeableness.trait_name = 'agreeableness'
    LEFT JOIN personality_trait_scores pts_emotional_stability ON qs.id = pts_emotional_stability.quiz_session_id AND pts_emotional_stability.trait_name = 'emotional_stability'
    LEFT JOIN personality_trait_scores pts_rational_thinking ON qs.id = pts_rational_thinking.quiz_session_id AND pts_rational_thinking.trait_name = 'rational_thinking'
    LEFT JOIN personality_trait_scores pts_core_values ON qs.id = pts_core_values.quiz_session_id AND pts_core_values.trait_name = 'core_values'
    LEFT JOIN personality_trait_scores pts_lifestyle ON qs.id = pts_lifestyle.quiz_session_id AND pts_lifestyle.trait_name = 'lifestyle'
    LEFT JOIN personality_trait_scores pts_social_style ON qs.id = pts_social_style.quiz_session_id AND pts_social_style.trait_name = 'social_style'
    LEFT JOIN personality_trait_scores pts_self_expression ON qs.id = pts_self_expression.quiz_session_id AND pts_self_expression.trait_name = 'self_expression'
    WHERE u.clerk_id = user_clerk_id 
    AND qs.status = 'completed'
    ORDER BY qs.completed_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Sample data insertion queries

-- Insert sample quiz questions
INSERT INTO quiz_questions (question_text, question_type, trait_category, question_order) VALUES
-- Openness questions
('I enjoy trying new experiences and activities', 'statement', 'openness', 1),
('I prefer routine and familiar situations', 'statement', 'openness', 2),
('I like to explore abstract ideas and concepts', 'statement', 'openness', 3),

-- Conscientiousness questions  
('I am organized and plan things carefully', 'statement', 'conscientiousness', 1),
('I tend to procrastinate on important tasks', 'statement', 'conscientiousness', 2),
('I pay attention to details and accuracy', 'statement', 'conscientiousness', 3),

-- Extraversion questions
('I feel energized when spending time with others', 'statement', 'extraversion', 1),
('I prefer quiet, solitary activities', 'statement', 'extraversion', 2),
('I enjoy being the center of attention', 'statement', 'extraversion', 3),

-- Agreeableness questions
('I try to be understanding and compassionate', 'statement', 'agreeableness', 1),
('I can be competitive and argumentative', 'statement', 'agreeableness', 2),
('I enjoy helping others and being cooperative', 'statement', 'agreeableness', 3),

-- Emotional Stability questions
('I remain calm under pressure', 'statement', 'emotional_stability', 1),
('I often worry about things', 'statement', 'emotional_stability', 2),
('I handle stress and setbacks well', 'statement', 'emotional_stability', 3),

-- Rational Thinking questions
('I make decisions based on logic and facts', 'statement', 'rational_thinking', 1),
('I trust my intuition when making choices', 'statement', 'rational_thinking', 2),
('I analyze problems systematically', 'statement', 'rational_thinking', 3),

-- Core Values questions
('I have strong moral principles', 'statement', 'core_values', 1),
('I believe in treating everyone fairly', 'statement', 'core_values', 2),
('I value honesty and integrity', 'statement', 'core_values', 3),

-- Lifestyle questions
('I prefer an active, busy lifestyle', 'statement', 'lifestyle', 1),
('I enjoy a relaxed, laid-back approach', 'statement', 'lifestyle', 2),
('I like to set goals and work towards them', 'statement', 'lifestyle', 3),

-- Social Style questions
('I prefer deep, meaningful conversations', 'statement', 'social_style', 1),
('I enjoy light, casual social interactions', 'statement', 'social_style', 2),
('I like to connect with people on a personal level', 'statement', 'social_style', 3),

-- Self Expression questions
('I enjoy creative activities and self-expression', 'statement', 'self_expression', 1),
('I prefer practical, straightforward communication', 'statement', 'self_expression', 2),
('I like to share my thoughts and feelings openly', 'statement', 'self_expression', 3);

-- Insert sample book questions
INSERT INTO book_questions (question_id, book_title, book_author, book_description, book_genre) VALUES
((SELECT id FROM quiz_questions WHERE trait_category = 'openness' AND question_order = 1), 'The Alchemist', 'Paulo Coelho', 'A philosophical novel about following your dreams', 'Philosophical Fiction'),
((SELECT id FROM quiz_questions WHERE trait_category = 'conscientiousness' AND question_order = 1), 'Getting Things Done', 'David Allen', 'A productivity system for organizing tasks', 'Self-Help'),
((SELECT id FROM quiz_questions WHERE trait_category = 'extraversion' AND question_order = 1), 'How to Win Friends and Influence People', 'Dale Carnegie', 'A guide to social skills and relationships', 'Self-Help');

-- Useful queries for the application

-- Get all quiz questions for the current quiz
-- SELECT qq.*, bq.book_title, bq.book_author, bq.book_description 
-- FROM quiz_questions qq 
-- LEFT JOIN book_questions bq ON qq.id = bq.question_id 
-- WHERE qq.is_active = true 
-- ORDER BY qq.trait_category, qq.question_order;

-- Get user's quiz history
-- SELECT qs.*, qp.progress_percentage, qp.time_spent_seconds
-- FROM quiz_sessions qs
-- JOIN users u ON qs.user_id = u.id
-- LEFT JOIN quiz_progress qp ON qs.id = qp.quiz_session_id
-- WHERE u.clerk_id = 'user_clerk_id_here'
-- ORDER BY qs.created_at DESC;

-- Get detailed personality breakdown for a specific quiz session
-- SELECT pts.*, pi.insight_title, pi.insight_description, pi.insight_type
-- FROM personality_trait_scores pts
-- LEFT JOIN personality_insights pi ON pts.quiz_session_id = pi.quiz_session_id AND pts.trait_name = pi.trait_name
-- WHERE pts.quiz_session_id = 'session_uuid_here'
-- ORDER BY pts.trait_name;

-- Get reading style analysis for a user
-- SELECT rsa.*
-- FROM reading_style_analysis rsa
-- JOIN quiz_sessions qs ON rsa.quiz_session_id = qs.id
-- JOIN users u ON qs.user_id = u.id
-- WHERE u.clerk_id = 'user_clerk_id_here'
-- ORDER BY rsa.created_at DESC
-- LIMIT 1; 