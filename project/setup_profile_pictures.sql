-- =====================================================
-- SETUP PROFILE PICTURES STORAGE
-- =====================================================
-- This script sets up Supabase storage for profile pictures

-- =====================================================
-- STEP 1: CREATE STORAGE BUCKET
-- =====================================================

-- Create the profile-pictures bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile-pictures',
  'profile-pictures',
  true,
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- STEP 2: CREATE STORAGE POLICIES
-- =====================================================

-- Policy for authenticated users to upload their own profile pictures
CREATE POLICY "Users can upload their own profile pictures" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'profile-pictures' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy for authenticated users to update their own profile pictures
CREATE POLICY "Users can update their own profile pictures" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'profile-pictures' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy for authenticated users to delete their own profile pictures
CREATE POLICY "Users can delete their own profile pictures" ON storage.objects
FOR DELETE USING (
  bucket_id = 'profile-pictures' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy for public read access to profile pictures
CREATE POLICY "Profile pictures are publicly readable" ON storage.objects
FOR SELECT USING (bucket_id = 'profile-pictures');

-- =====================================================
-- STEP 3: CREATE HELPER FUNCTION TO UPDATE USER AVATAR
-- =====================================================

CREATE OR REPLACE FUNCTION update_user_avatar_url(
  user_auth_id UUID,
  avatar_url TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result JSON;
BEGIN
  -- Update the user's avatar_url
  UPDATE users 
  SET 
    avatar_url = update_user_avatar_url.avatar_url,
    updated_at = NOW()
  WHERE auth_user_id = user_auth_id;
  
  -- Return success
  result := json_build_object(
    'success', true,
    'message', 'Avatar URL updated successfully'
  );
  
  RETURN result;
EXCEPTION
  WHEN OTHERS THEN
    result := json_build_object(
      'success', false,
      'message', 'Failed to update avatar URL: ' || SQLERRM
    );
    RETURN result;
END;
$$;

-- =====================================================
-- STEP 4: GRANT PERMISSIONS
-- =====================================================

-- Grant execute permission on the helper function
GRANT EXECUTE ON FUNCTION update_user_avatar_url(UUID, TEXT) TO authenticated;

-- =====================================================
-- STEP 5: CREATE RLS POLICY FOR AVATAR URL UPDATES
-- =====================================================

-- Allow users to update their own avatar_url
CREATE POLICY "Users can update their own avatar_url" ON users
FOR UPDATE USING (auth.uid() = auth_user_id);

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

-- This will show a message when the script completes
DO $$
BEGIN
  RAISE NOTICE 'Profile pictures storage setup completed successfully!';
  RAISE NOTICE 'Users can now upload profile pictures to the profile-pictures bucket.';
  RAISE NOTICE 'Profile pictures will be publicly accessible and organized by user ID.';
END $$;
