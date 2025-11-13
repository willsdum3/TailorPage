-- Create table to store discussion mute preferences
-- Users can mute/unmute notifications for specific discussions

CREATE TABLE IF NOT EXISTS discussion_mute_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    discussion_id UUID NOT NULL REFERENCES discussions(id) ON DELETE CASCADE,
    is_muted BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, discussion_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_discussion_mute_preferences_user_id ON discussion_mute_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_discussion_mute_preferences_discussion_id ON discussion_mute_preferences(discussion_id);
CREATE INDEX IF NOT EXISTS idx_discussion_mute_preferences_user_discussion ON discussion_mute_preferences(user_id, discussion_id);

-- Enable RLS
ALTER TABLE discussion_mute_preferences ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
DROP POLICY IF EXISTS "Users can view their own mute preferences" ON discussion_mute_preferences;
DROP POLICY IF EXISTS "Users can manage their own mute preferences" ON discussion_mute_preferences;

CREATE POLICY "Users can view their own mute preferences" ON discussion_mute_preferences
    FOR SELECT USING (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()::uuid));

CREATE POLICY "Users can manage their own mute preferences" ON discussion_mute_preferences
    FOR ALL USING (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()::uuid));

-- Function to toggle discussion mute status
CREATE OR REPLACE FUNCTION toggle_discussion_mute(
    p_auth_user_id UUID,
    p_discussion_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_user_internal_id UUID;
    v_current_mute_status BOOLEAN;
    v_new_mute_status BOOLEAN;
BEGIN
    -- Get user's internal ID
    v_user_internal_id := get_user_internal_id(p_auth_user_id);
    
    IF v_user_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Check if user is a participant of the discussion
    IF NOT EXISTS (
        SELECT 1 FROM discussion_members 
        WHERE user_id = v_user_internal_id 
        AND discussion_id = p_discussion_id
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'You are not a participant of this discussion');
    END IF;
    
    -- Get current mute status
    SELECT is_muted INTO v_current_mute_status
    FROM discussion_mute_preferences
    WHERE user_id = v_user_internal_id
      AND discussion_id = p_discussion_id;
    
    -- Toggle the mute status
    v_new_mute_status := NOT COALESCE(v_current_mute_status, FALSE);
    
    -- Insert or update the mute preference
    INSERT INTO discussion_mute_preferences (user_id, discussion_id, is_muted, updated_at)
    VALUES (v_user_internal_id, p_discussion_id, v_new_mute_status, NOW())
    ON CONFLICT (user_id, discussion_id)
    DO UPDATE SET 
        is_muted = v_new_mute_status,
        updated_at = NOW();
    
    RETURN jsonb_build_object(
        'success', true,
        'isMuted', v_new_mute_status,
        'message', CASE 
            WHEN v_new_mute_status THEN 'Discussion notifications muted'
            ELSE 'Discussion notifications unmuted'
        END
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', COALESCE(SQLERRM, 'Failed to toggle mute status'));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

-- Function to get discussion mute status
CREATE OR REPLACE FUNCTION get_discussion_mute_status(
    p_auth_user_id UUID,
    p_discussion_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_user_internal_id UUID;
    v_is_muted BOOLEAN;
BEGIN
    -- Get user's internal ID
    v_user_internal_id := get_user_internal_id(p_auth_user_id);
    
    IF v_user_internal_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'User not found', 'isMuted', false);
    END IF;
    
    -- Get mute status (default to false if not set)
    SELECT COALESCE(is_muted, false) INTO v_is_muted
    FROM discussion_mute_preferences
    WHERE user_id = v_user_internal_id
      AND discussion_id = p_discussion_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'isMuted', v_is_muted
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', COALESCE(SQLERRM, 'Failed to get mute status'), 'isMuted', false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION toggle_discussion_mute(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION toggle_discussion_mute(UUID, UUID) TO anon;
GRANT EXECUTE ON FUNCTION get_discussion_mute_status(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_discussion_mute_status(UUID, UUID) TO anon;

