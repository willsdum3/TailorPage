import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
const supabaseServiceKey = import.meta.env.VITE_SUPABASE_SERVICE_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true
  }
});

// Create admin client for server-side operations
export const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey || supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true
  }
});

// Database types for the fresh schema
export interface Database {
  public: {
    Tables: {
      users: {
        Row: {
          id: string;
          auth_user_id: string;
          name: string;
          username: string | null;
          email: string;
          avatar_url: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          auth_user_id: string;
          name: string;
          username?: string | null;
          email: string;
          avatar_url?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          auth_user_id?: string;
          name?: string;
          username?: string | null;
          email?: string;
          avatar_url?: string | null;
          created_at?: string;
          updated_at?: string;
        };
      };
      user_personality_profiles: {
        Row: {
          id: string;
          user_id: string;
          openness: number;
          conscientiousness: number;
          extraversion: number;
          agreeableness: number;
          emotional_stability: number;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          user_id: string;
          openness: number;
          conscientiousness: number;
          extraversion: number;
          agreeableness: number;
          emotional_stability: number;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          user_id?: string;
          openness?: number;
          conscientiousness?: number;
          extraversion?: number;
          agreeableness?: number;
          emotional_stability?: number;
          created_at?: string;
          updated_at?: string;
        };
      };
      user_favorites: {
        Row: {
          id: string;
          user_id: string;
          book_title: string;
          book_author: string;
          book_genre: string | null;
          book_description: string | null;
          book_amazon_link: string | null;
          book_cover_image_url: string | null;
          reason: string | null;
          created_at: string;
        };
        Insert: {
          id?: string;
          user_id: string;
          book_title: string;
          book_author: string;
          book_genre?: string | null;
          book_description?: string | null;
          book_amazon_link?: string | null;
          book_cover_image_url?: string | null;
          reason?: string | null;
          created_at?: string;
        };
        Update: {
          id?: string;
          user_id?: string;
          book_title?: string;
          book_author?: string;
          book_genre?: string | null;
          book_description?: string | null;
          book_amazon_link?: string | null;
          book_cover_image_url?: string | null;
          reason?: string | null;
          created_at?: string;
        };
      };
    };
  };
}

// Helper function to get current user
export const getCurrentUser = async () => {
  const { data: { user }, error } = await supabase.auth.getUser();
  if (error) {
    console.error('Error getting current user:', error);
    return null;
  }
  return user;
};

// Helper function to get user by auth ID
export const getUserByAuthId = async (authUserId: string) => {
  const { data, error } = await supabase
    .from('users')
    .select('*')
    .eq('auth_user_id', authUserId)
    .single();

  if (error) {
    console.error('Error getting user by auth ID:', error);
    return null;
  }
  return data;
};

// Helper function to upsert user
export const upsertUser = async (userData: {
  auth_user_id: string;
  name: string;
  email: string;
  username?: string;
  avatar_url?: string;
}) => {
  const { data, error } = await supabase
    .from('users')
    .upsert(userData, {
      onConflict: 'auth_user_id'
    })
    .select()
    .single();

  if (error) {
    console.error('Error upserting user:', error);
    return null;
  }
  return data;
};

// Helper function to save personality profile
export const saveUserPersonalityProfile = async (
  authUserId: string,
  profile: {
    openness: number;
    conscientiousness: number;
    extraversion: number;
    agreeableness: number;
    emotionalStability: number;
  }
) => {
  const { data, error } = await supabaseAdmin
    .rpc('save_personality_profile', {
      auth_user_id: authUserId,
      openness_val: profile.openness,
      conscientiousness_val: profile.conscientiousness,
      extraversion_val: profile.extraversion,
      agreeableness_val: profile.agreeableness,
      emotional_stability_val: profile.emotionalStability
    });

  if (error) {
    console.error('Error saving personality profile:', error);
    return null;
  }
  return data;
};

// Helper function to get personality profile
export const getUserPersonalityProfile = async (authUserId: string) => {
  const { data, error } = await supabaseAdmin
    .rpc('get_personality_profile', { auth_user_id: authUserId });

  if (error) {
    console.error('Error fetching personality profile:', error);
    return null;
  }
  return data?.[0] || null;
};

// Helper function to add book to favorites
export const addBookToFavorites = async (
  authUserId: string,
  bookData: {
    title: string;
    author: string;
    genre?: string;
    description?: string;
    amazon_link?: string;
    cover_image_url?: string;
    reason?: string;
  }
) => {
  console.log('🔍 addBookToFavorites called with:', { authUserId, bookData });
  
  try {
    const { data, error } = await supabaseAdmin
      .rpc('add_book_to_user_favorites', {
        user_auth_id: authUserId,
        title: bookData.title,
        author: bookData.author,
        genre: bookData.genre || null,
        description: bookData.description || null,
        amazon_link: bookData.amazon_link || null,
        cover_image_url: bookData.cover_image_url || null,
        reason_text: bookData.reason || null
      });

    if (error) {
      console.error('❌ Error adding book to favorites:', error);
      console.error('❌ Error details:', {
        message: error.message,
        details: error.details,
        hint: error.hint,
        code: error.code
      });
      console.error('❌ Full error object:', JSON.stringify(error, null, 2));
      return null;
    }
    
    console.log('✅ addBookToFavorites successful, returned data:', data);
    return data;
  } catch (err) {
    console.error('❌ Exception in addBookToFavorites:', err);
    return null;
  }
};

// Helper function to remove book from favorites
export const removeBookFromFavorites = async (
  authUserId: string,
  bookTitle: string,
  bookAuthor: string
) => {
  const { data, error } = await supabaseAdmin
    .rpc('remove_book_from_user_favorites', {
      user_auth_id: authUserId,
      title: bookTitle,
      author: bookAuthor
    });

  if (error) {
    console.error('Error removing book from favorites:', error);
    return false;
  }
  return data;
};

// Helper function to get user favorites
export const getUserFavorites = async (authUserId: string) => {
  console.log('🔍 getUserFavorites called with authUserId:', authUserId);
  
  try {
    const { data, error } = await supabaseAdmin
      .rpc('get_user_favorites', { auth_user_id: authUserId });

    if (error) {
      console.error('❌ Error fetching user favorites:', error);
      console.error('❌ Error details:', {
        message: error.message,
        details: error.details,
        hint: error.hint,
        code: error.code
      });
      console.error('❌ Full error object:', JSON.stringify(error, null, 2));
      return [];
    }
    
    console.log('✅ getUserFavorites successful, returned data:', data);
    return data || [];
  } catch (err) {
    console.error('❌ Exception in getUserFavorites:', err);
    return [];
  }
}; 