import { supabase } from '../lib/supabase';
import { 
  BookClub, 
  Discussion, 
  DiscussionMessage, 
  FriendConnection, 
  FriendRecommendation,
  CreateBookClubData,
  CreateDiscussionData
} from '../types';

export class TailorMatesService {
  // Enhanced helper function to check if user exists and sync if needed
  static async ensureUserExists(clerkUserId: string): Promise<boolean> {
    try {
      // First, check if user exists
      const { data: existingUser, error: checkError } = await supabase
        .from('users')
        .select('id')
        .eq('clerk_id', clerkUserId)
        .single();

      if (existingUser) {
        console.log('User found in database:', clerkUserId);
        return true;
      }

      // If user doesn't exist, try to sync them
      console.log('User not found, attempting to sync from Clerk...');
      
      // Get user data from Clerk (this would need to be passed from the component)
      // For now, we'll throw a more helpful error
      throw new Error('User not found in database. Please try logging out and back in to sync your account.');
    } catch (error) {
      console.error('Error ensuring user exists:', error);
      throw error;
    }
  }

  // Helper function to check if Tailor Mates tables exist
  static async checkTablesExist(): Promise<boolean> {
    try {
      // Try to query the book_clubs table
      const { data, error } = await supabase
        .from('book_clubs')
        .select('id')
        .limit(1);

      if (error) {
        console.error('Error checking book_clubs table:', error);
        return false;
      }

      return true;
    } catch (error) {
      console.error('Error checking tables:', error);
      return false;
    }
  }

  // Enhanced function to create user if they don't exist
  static async createUserIfNotExists(clerkUserId: string, userData: {
    name: string;
    username: string;
    email: string;
    image_url?: string;
  }): Promise<boolean> {
    try {
      const { data, error } = await supabase
        .from('users')
        .upsert({
          clerk_id: clerkUserId,
          name: userData.name,
          username: userData.username,
          email: userData.email,
          image_url: userData.image_url
        }, {
          onConflict: 'clerk_id',
          ignoreDuplicates: false,
        })
        .select()
        .single();

      if (error) {
        console.error('Error creating user:', error);
        return false;
      }

      console.log('User created/updated successfully:', data);
      return true;
    } catch (error) {
      console.error('Error in createUserIfNotExists:', error);
      return false;
    }
  }

  // Book Club Functions
  static async getBookClubs(clerkUserId: string): Promise<BookClub[]> {
    try {
      // Ensure user exists first
      await this.ensureUserExists(clerkUserId);

      const { data, error } = await supabase.rpc('get_book_clubs', {
        user_clerk_id: clerkUserId
      });

      if (error) {
        console.error('Error fetching book clubs:', error);
        throw new Error('Failed to fetch book clubs');
      }

      return data || [];
    } catch (error) {
      console.error('Error in getBookClubs:', error);
      throw error;
    }
  }

  static async createBookClub(clubData: CreateBookClubData, clerkUserId: string, userData?: {
    name: string;
    username: string;
    email: string;
    image_url?: string;
  }): Promise<string> {
    try {
      // Check if tables exist first
      const tablesExist = await this.checkTablesExist();
      if (!tablesExist) {
        console.error('Tailor Mates tables do not exist');
        throw new Error('Database tables not found. Please contact support.');
      }

      // Check if user exists first
      let userExists = false;
      try {
        userExists = await this.ensureUserExists(clerkUserId);
      } catch (error) {
        // If user doesn't exist and we have user data, try to create them
        if (userData) {
          console.log('Attempting to create user with provided data...');
          const created = await this.createUserIfNotExists(clerkUserId, userData);
          if (created) {
            userExists = true;
          } else {
            throw new Error('Failed to create user account. Please try logging out and back in.');
          }
        } else {
          throw error;
        }
      }

      if (!userExists) {
        throw new Error('User not found in database. Please try logging out and back in.');
      }

      console.log('Creating book club with data:', {
        user_clerk_id: clerkUserId,
        club_name: clubData.name,
        club_description: clubData.description,
        current_book_title: clubData.currentBookTitle || null,
        current_book_author: clubData.currentBookAuthor || null,
        max_members: clubData.maxMembers,
        personality_traits: clubData.personalityTraits,
        meeting_time: clubData.meetingTime || null,
        next_meeting_date: clubData.nextMeetingDate || null,
        is_private: clubData.isPrivate,
        tags: clubData.tags
      });

      const { data, error } = await supabase.rpc('create_book_club', {
        user_clerk_id: clerkUserId,
        club_name: clubData.name,
        club_description: clubData.description,
        current_book_title: clubData.currentBookTitle || null,
        current_book_author: clubData.currentBookAuthor || null,
        max_members: clubData.maxMembers,
        personality_traits: clubData.personalityTraits,
        meeting_time: clubData.meetingTime || null,
        next_meeting_date: clubData.nextMeetingDate || null,
        is_private: clubData.isPrivate,
        tags: clubData.tags
      });

      if (error) {
        console.error('Error creating book club:', error);
        console.error('Error details:', {
          message: error.message,
          details: error.details,
          hint: error.hint,
          code: error.code
        });
        
        // Provide more specific error messages
        if (error.message?.includes('duplicate key')) {
          throw new Error('A book club with this name already exists. Please choose a different name.');
        } else if (error.message?.includes('permission')) {
          throw new Error('You do not have permission to create book clubs. Please contact support.');
        } else {
          throw new Error(`Failed to create book club: ${error.message}`);
        }
      }

      console.log('Book club created successfully:', data);
      return data;
    } catch (error) {
      console.error('Error in createBookClub:', error);
      throw error;
    }
  }

  static async joinBookClub(clubId: string, clerkUserId: string): Promise<boolean> {
    try {
      // Ensure user exists first
      await this.ensureUserExists(clerkUserId);

      const { data, error } = await supabase.rpc('join_book_club', {
        user_clerk_id: clerkUserId,
        club_id: clubId
      });

      if (error) {
        console.error('Error joining book club:', error);
        throw new Error('Failed to join book club');
      }

      return data;
    } catch (error) {
      console.error('Error in joinBookClub:', error);
      throw error;
    }
  }

  static async leaveBookClub(clubId: string, clerkUserId: string): Promise<boolean> {
    try {
      // Ensure user exists first
      await this.ensureUserExists(clerkUserId);

      const { data, error } = await supabase.rpc('leave_book_club', {
        user_clerk_id: clerkUserId,
        club_id: clubId
      });

      if (error) {
        console.error('Error leaving book club:', error);
        throw new Error('Failed to leave book club');
      }

      return data;
    } catch (error) {
      console.error('Error in leaveBookClub:', error);
      throw error;
    }
  }

  // Discussion Functions
  static async getDiscussions(clerkUserId: string): Promise<Discussion[]> {
    const { data, error } = await supabase.rpc('get_discussions', {
      user_clerk_id: clerkUserId
    });

    if (error) {
      console.error('Error fetching discussions:', error);
      throw new Error('Failed to fetch discussions');
    }

    return data || [];
  }

  static async createDiscussion(discussionData: CreateDiscussionData, clerkUserId: string): Promise<string> {
    const { data, error } = await supabase.rpc('create_discussion', {
      user_clerk_id: clerkUserId,
      title: discussionData.title,
      content: discussionData.content,
      book_title: discussionData.bookTitle || null,
      book_author: discussionData.bookAuthor || null,
      tags: discussionData.tags
    });

    if (error) {
      console.error('Error creating discussion:', error);
      throw new Error('Failed to create discussion');
    }

    return data;
  }

  static async joinDiscussion(discussionId: string, clerkUserId: string): Promise<boolean> {
    const { data, error } = await supabase.rpc('join_discussion', {
      user_clerk_id: clerkUserId,
      discussion_id: discussionId
    });

    if (error) {
      console.error('Error joining discussion:', error);
      throw new Error('Failed to join discussion');
    }

    return data;
  }

  static async getDiscussionMessages(discussionId: string): Promise<DiscussionMessage[]> {
    const { data, error } = await supabase.rpc('get_discussion_messages', {
      discussion_id: discussionId
    });

    if (error) {
      console.error('Error fetching discussion messages:', error);
      throw new Error('Failed to fetch discussion messages');
    }

    return data || [];
  }

  static async addDiscussionMessage(discussionId: string, content: string, clerkUserId: string): Promise<string> {
    const { data, error } = await supabase.rpc('add_discussion_message', {
      user_clerk_id: clerkUserId,
      discussion_id: discussionId,
      message_content: content
    });

    if (error) {
      console.error('Error adding discussion message:', error);
      throw new Error('Failed to add discussion message');
    }

    return data;
  }

  // Friend Functions
  static async getFriendConnections(clerkUserId: string): Promise<FriendConnection[]> {
    const { data, error } = await supabase.rpc('get_friend_connections', {
      user_clerk_id: clerkUserId
    });

    if (error) {
      console.error('Error fetching friend connections:', error);
      throw new Error('Failed to fetch friend connections');
    }

    return data || [];
  }

  static async sendFriendRequest(friendClerkId: string, clerkUserId: string): Promise<boolean> {
    const { data, error } = await supabase.rpc('send_friend_request', {
      user_clerk_id: clerkUserId,
      friend_clerk_id: friendClerkId
    });

    if (error) {
      console.error('Error sending friend request:', error);
      throw new Error('Failed to send friend request');
    }

    return data;
  }

  static async acceptFriendRequest(friendClerkId: string, clerkUserId: string): Promise<boolean> {
    const { data, error } = await supabase.rpc('accept_friend_request', {
      user_clerk_id: clerkUserId,
      friend_clerk_id: friendClerkId
    });

    if (error) {
      console.error('Error accepting friend request:', error);
      throw new Error('Failed to accept friend request');
    }

    return data;
  }

  static async getFriendRecommendations(clerkUserId: string): Promise<FriendRecommendation[]> {
    const { data, error } = await supabase.rpc('get_friend_recommendations', {
      user_clerk_id: clerkUserId
    });

    if (error) {
      console.error('Error fetching friend recommendations:', error);
      throw new Error('Failed to fetch friend recommendations');
    }

    return data || [];
  }

  static async generateFriendRecommendations(clerkUserId: string): Promise<boolean> {
    const { data, error } = await supabase.rpc('generate_friend_recommendations', {
      user_clerk_id: clerkUserId
    });

    if (error) {
      console.error('Error generating friend recommendations:', error);
      throw new Error('Failed to generate friend recommendations');
    }

    return data;
  }

  // Utility Functions
  static formatDate(dateString: string): string {
    const date = new Date(dateString);
    const now = new Date();
    const diffInHours = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60));
    
    if (diffInHours < 1) {
      return 'Just now';
    } else if (diffInHours < 24) {
      return `${diffInHours} hour${diffInHours > 1 ? 's' : ''} ago`;
    } else if (diffInHours < 48) {
      return 'Yesterday';
    } else {
      return date.toLocaleDateString();
    }
  }

  static getPersonalityTraitColor(trait: string): string {
    const colors: { [key: string]: string } = {
      'Openness': 'from-purple-500/20 to-pink-500/20 text-purple-300',
      'Conscientiousness': 'from-blue-500/20 to-cyan-500/20 text-blue-300',
      'Extraversion': 'from-green-500/20 to-emerald-500/20 text-green-300',
      'Agreeableness': 'from-yellow-500/20 to-orange-500/20 text-yellow-300',
      'Emotional Stability': 'from-red-500/20 to-pink-500/20 text-red-300',
      'Rational Thinking': 'from-indigo-500/20 to-purple-500/20 text-indigo-300',
      'Core Values': 'from-teal-500/20 to-cyan-500/20 text-teal-300',
      'Lifestyle': 'from-amber-500/20 to-yellow-500/20 text-amber-300',
      'Social Style': 'from-emerald-500/20 to-green-500/20 text-emerald-300',
      'Self Expression': 'from-rose-500/20 to-pink-500/20 text-rose-300'
    };
    
    return colors[trait] || 'from-gray-500/20 to-gray-600/20 text-gray-300';
  }

  static getMatchScoreColor(score: number): string {
    if (score >= 0.9) return 'text-green-400';
    if (score >= 0.8) return 'text-blue-400';
    if (score >= 0.7) return 'text-yellow-400';
    if (score >= 0.6) return 'text-orange-400';
    return 'text-red-400';
  }

  static getMatchScoreLabel(score: number): string {
    if (score >= 0.9) return 'Excellent Match';
    if (score >= 0.8) return 'Great Match';
    if (score >= 0.7) return 'Good Match';
    if (score >= 0.6) return 'Fair Match';
    return 'Poor Match';
  }
}
