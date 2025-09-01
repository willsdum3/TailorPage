import { supabase } from '../lib/supabase';

// Callback type for refreshing user data
export type RefreshUserCallback = () => void;

export interface UploadResult {
  success: boolean;
  url?: string;
  error?: string;
}

/**
 * Upload a profile picture to Supabase storage
 */
export const uploadProfilePicture = async (
  file: File,
  userId: string
): Promise<UploadResult> => {
  try {
    // Validate file type
    const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    if (!allowedTypes.includes(file.type)) {
      return {
        success: false,
        error: 'Invalid file type. Please upload a JPEG, PNG, GIF, or WebP image.'
      };
    }

    // Validate file size (5MB limit)
    const maxSize = 5 * 1024 * 1024; // 5MB
    if (file.size > maxSize) {
      return {
        success: false,
        error: 'File size too large. Please upload an image smaller than 5MB.'
      };
    }

    // Create a unique filename
    const fileExt = file.name.split('.').pop();
    const fileName = `${userId}/profile.${fileExt}`;

    // Upload to Supabase storage
    const { data, error } = await supabase.storage
      .from('profile-pictures')
      .upload(fileName, file, {
        cacheControl: '3600',
        upsert: true // This will overwrite existing files
      });

    if (error) {
      console.error('Storage upload error:', error);
      return {
        success: false,
        error: 'Failed to upload image. Please try again.'
      };
    }

    // Get the public URL
    const { data: urlData } = supabase.storage
      .from('profile-pictures')
      .getPublicUrl(fileName);

    if (!urlData.publicUrl) {
      return {
        success: false,
        error: 'Failed to get image URL. Please try again.'
      };
    }

    return {
      success: true,
      url: urlData.publicUrl
    };

  } catch (error) {
    console.error('Profile picture upload error:', error);
    return {
      success: false,
      error: 'An unexpected error occurred. Please try again.'
    };
  }
};

/**
 * Update user's avatar URL in the database
 */
export const updateUserAvatarUrl = async (
  userId: string,
  avatarUrl: string
): Promise<UploadResult> => {
  try {
    const { data, error } = await supabase.rpc('update_user_avatar_url', {
      user_auth_id: userId,
      avatar_url: avatarUrl
    });

    if (error) {
      console.error('Database update error:', error);
      return {
        success: false,
        error: 'Failed to update profile picture. Please try again.'
      };
    }

    return {
      success: true,
      url: avatarUrl
    };

  } catch (error) {
    console.error('Avatar URL update error:', error);
    return {
      success: false,
      error: 'An unexpected error occurred. Please try again.'
    };
  }
};

/**
 * Remove a profile picture from storage and database
 */
export const removeProfilePicture = async (userId: string): Promise<UploadResult> => {
  try {
    // Remove from storage
    const { error: storageError } = await supabase.storage
      .from('profile-pictures')
      .remove([`${userId}/profile.jpg`, `${userId}/profile.png`, `${userId}/profile.gif`, `${userId}/profile.webp`]);

    if (storageError) {
      console.warn('Storage removal error (may not exist):', storageError);
    }

    // Update database to remove avatar URL
    const { data, error } = await supabase.rpc('update_user_avatar_url', {
      user_auth_id: userId,
      avatar_url: null
    });

    if (error) {
      console.error('Database update error:', error);
      return {
        success: false,
        error: 'Failed to remove profile picture. Please try again.'
      };
    }

    return {
      success: true
    };

  } catch (error) {
    console.error('Profile picture removal error:', error);
    return {
      success: false,
      error: 'An unexpected error occurred. Please try again.'
    };
  }
};
