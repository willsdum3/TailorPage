-- Create table to store club mute preferences
-- Users can mute/unmute notifications for specific book clubs

CREATE TABLE IF NOT EXISTS club_mute_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    club_id UUID NOT NULL REFERENCES book_clubs(id) ON DELETE CASCADE,
    is_muted BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, club_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_club_mute_preferences_user_id ON club_mute_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_club_mute_preferences_club_id ON club_mute_preferences(club_id);
CREATE INDEX IF NOT EXISTS idx_club_mute_preferences_user_club ON club_mute_preferences(user_id, club_id);

-- Enable RLS
ALTER TABLE club_mute_preferences ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
DROP POLICY IF EXISTS "Users can view their own mute preferences" ON club_mute_preferences;
DROP POLICY IF EXISTS "Users can manage their own mute preferences" ON club_mute_preferences;

CREATE POLICY "Users can view their own mute preferences" ON club_mute_preferences
    FOR SELECT USING (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()::uuid));

CREATE POLICY "Users can manage their own mute preferences" ON club_mute_preferences
    FOR ALL USING (user_id = (SELECT id FROM users WHERE auth_user_id = auth.uid()::uuid));

-- Function to toggle club mute status
CREATE OR REPLACE FUNCTION toggle_club_mute(
    p_auth_user_id UUID,
    p_club_id UUID
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
    
    -- Check if user is a member of the club
    IF NOT EXISTS (
        SELECT 1 FROM book_club_members 
        WHERE user_id = v_user_internal_id 
        AND club_id = p_club_id
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'You are not a member of this club');
    END IF;
    
    -- Get current mute status
    SELECT is_muted INTO v_current_mute_status
    FROM club_mute_preferences
    WHERE user_id = v_user_internal_id
      AND club_id = p_club_id;
    
    -- Toggle the mute status
    v_new_mute_status := NOT COALESCE(v_current_mute_status, FALSE);
    
    -- Insert or update the mute preference
    INSERT INTO club_mute_preferences (user_id, club_id, is_muted, updated_at)
    VALUES (v_user_internal_id, p_club_id, v_new_mute_status, NOW())
    ON CONFLICT (user_id, club_id)
    DO UPDATE SET 
        is_muted = v_new_mute_status,
        updated_at = NOW();
    
    RETURN jsonb_build_object(
        'success', true,
        'isMuted', v_new_mute_status,
        'message', CASE 
            WHEN v_new_mute_status THEN 'Club notifications muted'
            ELSE 'Club notifications unmuted'
        END
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', COALESCE(SQLERRM, 'Failed to toggle mute status'));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

-- Function to get club mute status
CREATE OR REPLACE FUNCTION get_club_mute_status(
    p_auth_user_id UUID,
    p_club_id UUID
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
    FROM club_mute_preferences
    WHERE user_id = v_user_internal_id
      AND club_id = p_club_id;
    
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
GRANT EXECUTE ON FUNCTION toggle_club_mute(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION toggle_club_mute(UUID, UUID) TO anon;
GRANT EXECUTE ON FUNCTION get_club_mute_status(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_club_mute_status(UUID, UUID) TO anon;

