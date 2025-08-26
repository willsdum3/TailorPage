import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL!;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY!;
const supabaseServiceKey = import.meta.env.VITE_SUPABASE_SERVICE_KEY!;

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true
  }
});

// Service role client for admin operations
export const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

// Types for our database tables
export interface Database {
  public: {
    Tables: {
      users: {
        Row: {
          id: string;
          auth_user_id: string; // Supabase Auth user ID
          name: string;
          username: string;
          email: string;
          image_url: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          auth_user_id: string;
          name: string;
          username: string;
          email: string;
          image_url?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          auth_user_id?: string;
          name?: string;
          username?: string;
          email?: string;
          image_url?: string | null;
          created_at?: string;
          updated_at?: string;
        };
      };
      user_favorites: {
        Row: {
          id: string;
          user_id: string;
          book_id: string;
          date_added: string;
          notes: string | null;
          rating: number | null;
          is_read: boolean;
          read_date: string | null;
        };
        Insert: {
          id?: string;
          user_id: string;
          book_id: string;
          date_added?: string;
          notes?: string | null;
          rating?: number | null;
          is_read?: boolean;
          read_date?: string | null;
        };
        Update: {
          id?: string;
          user_id?: string;
          book_id?: string;
          date_added?: string;
          notes?: string | null;
          rating?: number | null;
          is_read?: boolean;
          read_date?: string | null;
        };
      };
      books: {
        Row: {
          id: string;
          title: string;
          author: string;
          genre: string;
          description: string | null;
          amazon_link: string | null;
          cover_image_url: string | null;
          isbn: string | null;
          published_date: string | null;
          page_count: number | null;
          language: string;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          title: string;
          author: string;
          genre: string;
          description?: string | null;
          amazon_link?: string | null;
          cover_image_url?: string | null;
          isbn?: string | null;
          published_date?: string | null;
          page_count?: number | null;
          language?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          title?: string;
          author?: string;
          genre?: string;
          description?: string | null;
          amazon_link?: string | null;
          cover_image_url?: string | null;
          isbn?: string | null;
          published_date?: string | null;
          page_count?: number | null;
          language?: string;
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
          rational_thinking: number;
          core_values: number;
          lifestyle: number;
          social_style: number;
          self_expression: number;
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
          rational_thinking: number;
          core_values: number;
          lifestyle: number;
          social_style: number;
          self_expression: number;
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
          rational_thinking?: number;
          core_values?: number;
          lifestyle?: number;
          social_style?: number;
          self_expression?: number;
          created_at?: string;
          updated_at?: string;
        };
      };
    };
  };
}

// Helper function to get current authenticated user
export const getCurrentUser = async () => {
  const { data: { user }, error } = await supabase.auth.getUser();
  
  if (error) {
    console.error('Error getting current user:', error);
    return null;
  }
  
  return user;
};

// Helper function to get user from Supabase Auth ID
export const getUserByAuthId = async (authUserId: string) => {
  const { data, error } = await supabase
    .from('users')
    .select('*')
    .eq('auth_user_id', authUserId)
    .single();

  if (error) {
    console.error('Error fetching user:', error);
    return null;
  }

  return data;
};

// Helper function to create or update user
export const upsertUser = async (userData: {
  auth_user_id: string;
  name: string;
  username: string;
  email: string;
  image_url?: string;
}) => {
  console.log('upsertUser: Starting upsert with data:', userData);
  
  try {
    // First, check if user exists with this email
    const { data: existingUser } = await supabaseAdmin
      .from('users')
      .select('auth_user_id, email')
      .eq('email', userData.email)
      .single();

    if (existingUser && existingUser.auth_user_id !== userData.auth_user_id) {
      console.log('upsertUser: Email conflict detected. Existing user:', existingUser);
      // Email exists but with different auth_user_id - this is a conflict
      throw new Error(`Email ${userData.email} is already registered with a different account`);
    }

    // Proceed with upsert using auth_user_id as conflict resolution
    const { data, error } = await supabaseAdmin
      .from('users')
      .upsert(userData, {
        onConflict: 'auth_user_id',
        ignoreDuplicates: false,
      })
      .select()
      .single();

    if (error) {
      console.error('Error upserting user:', error);
      console.error('Error details:', {
        code: error.code,
        message: error.message,
        details: error.details,
        hint: error.hint
      });
      return null;
    }

    console.log('upsertUser: Successfully upserted user:', data);
    return data;
  } catch (err) {
    console.error('Exception in upsertUser:', err);
    return null;
  }
};

// Helper function to get user favorites
export const getUserFavorites = async (authUserId: string) => {
  const { data, error } = await supabaseAdmin
    .rpc('get_user_favorites', { user_auth_id: authUserId });

  if (error) {
    console.error('Error fetching user favorites:', error);
    return [];
  }

  return data || [];
};

// Helper function to add book to favorites
export const addBookToFavorites = async (
  authUserId: string,
  bookData: {
    title: string;
    author: string;
    genre: string;
    description: string;
    amazon_link: string;
    cover_image_url?: string;
  }
) => {
  const { data, error } = await supabaseAdmin
    .rpc('save_book_to_favorites', {
      user_auth_id: authUserId,
      book_title: bookData.title,
      book_author: bookData.author,
      book_genre: bookData.genre,
      book_description: bookData.description,
      book_amazon_link: bookData.amazon_link,
      book_cover_image_url: bookData.cover_image_url || null,
    });

  if (error) {
    console.error('Error adding book to favorites:', error);
    return null;
  }

  return data;
};

// Helper function to remove book from favorites
export const removeBookFromFavorites = async (
  authUserId: string,
  bookTitle: string,
  bookAuthor: string
) => {
  const { data, error } = await supabaseAdmin
    .rpc('remove_book_from_favorites', {
      user_auth_id: authUserId,
      book_title: bookTitle,
      book_author: bookAuthor,
    });

  if (error) {
    console.error('Error removing book from favorites:', error);
    return false;
  }

  return data;
};

// Helper function to get user personality profile
export const getUserPersonalityProfile = async (authUserId: string) => {
  const { data, error } = await supabaseAdmin
    .rpc('get_user_personality_profile', { user_auth_id: authUserId });

  if (error) {
    console.error('Error fetching personality profile:', error);
    return null;
  }

  return data?.[0] || null;
};

// Helper function to save user personality profile
export const saveUserPersonalityProfile = async (
  authUserId: string,
  profile: {
    openness: number;
    conscientiousness: number;
    extraversion: number;
    agreeableness: number;
    emotionalStability: number;
    rationalThinking: number;
    coreValues: number;
    lifestyle: number;
    socialStyle: number;
    selfExpression: number;
  }
) => {
  const { data, error } = await supabaseAdmin
    .rpc('save_user_personality_profile', {
      user_auth_id: authUserId,
      openness_val: profile.openness,
      conscientiousness_val: profile.conscientiousness,
      extraversion_val: profile.extraversion,
      agreeableness_val: profile.agreeableness,
      emotional_stability_val: profile.emotionalStability,
      rational_thinking_val: profile.rationalThinking,
      core_values_val: profile.coreValues,
      lifestyle_val: profile.lifestyle,
      social_style_val: profile.socialStyle,
      self_expression_val: profile.selfExpression
    });

  if (error) {
    console.error('Error saving personality profile:', error);
    return null;
  }

  return data;
}; 