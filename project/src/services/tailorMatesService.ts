import { supabase } from '../lib/supabase';
import { 
  BookClub, 
  Discussion, 
  DiscussionMessage, 
  FriendConnection, 
  FriendRecommendation,
  CreateBookClubData,
  CreateBookClubServiceData,
  CreateDiscussionData
} from '../types';

export class TailorMatesService {
  // Helper function to get current user's auth_user_id
  static async getCurrentUserId(): Promise<string> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      throw new Error('User not authenticated');
    }
    return user.id;
  }

  // Helper function to check if user exists in database
  static async ensureUserExists(authUserId: string): Promise<boolean> {
    try {
      // Check if user exists in our users table
      const { data: existingUser, error: checkError } = await supabase
        .from('users')
        .select('id')
        .eq('auth_user_id', authUserId)
        .single();

      if (existingUser) {
        console.log('User found in database:', authUserId);
        return true;
      }

      // If user doesn't exist, they need to complete signup first
      throw new Error('User not found in database. Please ensure you are properly signed in.');
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

  // =====================================================
  // BOOK CLUB FUNCTIONS
  // =====================================================

  static async createBookClub(clubData: CreateBookClubServiceData): Promise<BookClub | null> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('create_book_club', {
          auth_user_id: authUserId,
          club_name: clubData.name,
          club_description: clubData.description,
          current_book_title: clubData.currentBookTitle || null,
          current_book_author: clubData.currentBookAuthor || null,
          max_members: clubData.maxMembers || 10,
          is_public: clubData.isPublic !== false,
          target_personality_traits: clubData.targetPersonalityTraits || [],
          tags: clubData.tags || [],
          meeting_info: clubData.meetingInfo || null
        });

      if (error) {
        console.error('Error creating book club:', error);
        return null;
      }

      console.log('Book club created successfully:', data);
      return data;
    } catch (error) {
      console.error('Error in createBookClub:', error);
      return null;
    }
  }

  static async getBookClubs(): Promise<BookClub[]> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('get_book_clubs', {
          auth_user_id: authUserId
        });

      if (error) {
        console.error('Error getting book clubs:', error);
        return [];
      }

      // Transform database data to match UI interface
      const transformedData: BookClub[] = (data || []).map((club: any) => ({
        id: club.id,
        name: club.name,
        description: club.description,
        currentBookTitle: club.current_book_title,
        currentBookAuthor: club.current_book_author,
        memberCount: club.member_count || 0,
        maxMembers: club.max_members,
        personalityTraits: club.target_personality_traits || [],
        meetingTime: club.meeting_info ? club.meeting_info.split(' - ')[0] : undefined,
        nextMeetingDate: club.meeting_info && club.meeting_info.includes(' - ') ? club.meeting_info.split(' - ')[1] : undefined,
        isPrivate: !club.is_public,
        tags: club.tags || [],
        createdBy: club.created_by,
        createdAt: club.created_at,
        isMember: club.is_member || false,
        userRole: club.user_role || '',
        creatorName: 'Unknown' // We'll need to get this from a join or separate query
      }));

      return transformedData;
    } catch (error) {
      console.error('Error in getBookClubs:', error);
      return [];
    }
  }

  static async joinBookClub(clubId: string): Promise<boolean> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('join_book_club', {
          auth_user_id: authUserId,
          club_id: clubId
        });

      if (error) {
        console.error('Error joining book club:', error);
        return false;
      }

      return data;
    } catch (error) {
      console.error('Error in joinBookClub:', error);
      return false;
    }
  }

  static async leaveBookClub(clubId: string): Promise<boolean> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('leave_book_club', {
          auth_user_id: authUserId,
          club_id: clubId
        });

      if (error) {
        console.error('Error leaving book club:', error);
        return false;
      }

      return data;
    } catch (error) {
      console.error('Error in leaveBookClub:', error);
      return false;
    }
  }

  static async getBookClubDetails(clubId: string): Promise<BookClub | null> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('get_book_club_details', {
          auth_user_id: authUserId,
          club_id_param: clubId
        });

      if (error) {
        console.error('Error getting book club details:', error);
        return null;
      }

      if (!data || data.length === 0) {
        return null;
      }

      const club = data[0];
      return {
        id: club.id,
        name: club.name,
        description: club.description,
        currentBookTitle: club.current_book_title,
        currentBookAuthor: club.current_book_author,
        memberCount: club.member_count || 0,
        maxMembers: club.max_members,
        personalityTraits: club.target_personality_traits || [],
        meetingTime: club.meeting_info ? club.meeting_info.split(' - ')[0] : undefined,
        nextMeetingDate: club.meeting_info && club.meeting_info.includes(' - ') ? club.meeting_info.split(' - ')[1] : undefined,
        isPrivate: !club.is_public,
        tags: club.tags || [],
        createdBy: club.created_by,
        createdAt: club.created_at,
        isMember: club.is_member || false,
        userRole: club.user_role || '',
        creatorName: club.creator_name || 'Unknown'
      };
    } catch (error) {
      console.error('Error in getBookClubDetails:', error);
      return null;
    }
  }

  static async getBookClubMembers(clubId: string): Promise<any[]> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('get_book_club_members', {
          auth_user_id: authUserId,
          club_id_param: clubId
        });

      if (error) {
        console.error('Error getting book club members:', error);
        return [];
      }

      return data || [];
    } catch (error) {
      console.error('Error in getBookClubMembers:', error);
      return [];
    }
  }

  static async addBookClubMessage(clubId: string, content: string): Promise<string | null> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('add_book_club_message', {
          auth_user_id: authUserId,
          club_id_param: clubId,
          content_param: content
        });

      if (error) {
        console.error('Error adding book club message:', error);
        return null;
      }

      return data;
    } catch (error) {
      console.error('Error in addBookClubMessage:', error);
      return null;
    }
  }

  static async getBookClubMessages(clubId: string, limit: number = 50, offset: number = 0): Promise<any[]> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('get_book_club_messages', {
          auth_user_id: authUserId,
          club_id_param: clubId
        });

      if (error) {
        console.error('Error getting book club messages:', error);
        return [];
      }

      return data || [];
    } catch (error) {
      console.error('Error in getBookClubMessages:', error);
      return [];
    }
  }

  // =====================================================
  // DISCUSSION FUNCTIONS
  // =====================================================

  static async createDiscussion(discussionData: CreateDiscussionData): Promise<Discussion | null> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('create_discussion', {
          auth_user_id: authUserId,
          discussion_title: discussionData.title,
          discussion_content: discussionData.content,
          book_title: discussionData.bookTitle || null,
          book_author: discussionData.bookAuthor || null,
          discussion_tags: discussionData.tags || []
        });

      if (error) {
        console.error('Error creating discussion:', error);
        return null;
      }

      console.log('Discussion created successfully:', data);
      return data;
    } catch (error) {
      console.error('Error in createDiscussion:', error);
      return null;
    }
  }

  static async getDiscussions(): Promise<Discussion[]> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('get_discussions', {
          auth_user_id: authUserId
        });

      if (error) {
        console.error('Error getting discussions:', error);
        return [];
      }

      // Transform database data to match UI interface
      const transformedData: Discussion[] = (data || []).map((discussion: any) => ({
        id: discussion.id,
        title: discussion.title,
        content: discussion.content,
        bookTitle: discussion.book_title,
        bookAuthor: discussion.book_author,
        tags: discussion.tags || [],
        createdBy: discussion.created_by,
        createdAt: discussion.created_at,
        participantCount: discussion.participant_count || 0,
        lastActivity: discussion.last_message_at || discussion.created_at,
        isParticipant: discussion.is_participant || false,
        creatorName: 'Unknown' // We'll need to get this from a join or separate query
      }));

      return transformedData;
    } catch (error) {
      console.error('Error in getDiscussions:', error);
      return [];
    }
  }

  static async joinDiscussion(discussionId: string): Promise<boolean> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('join_discussion', {
          auth_user_id: authUserId,
          discussion_id: discussionId
        });

      if (error) {
        console.error('Error joining discussion:', error);
        return false;
      }

      return data;
    } catch (error) {
      console.error('Error in joinDiscussion:', error);
      return false;
    }
  }

  static async addDiscussionMessage(discussionId: string, content: string): Promise<DiscussionMessage | null> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('add_discussion_message', {
          auth_user_id: authUserId,
          discussion_id: discussionId,
          message_content: content
        });

      if (error) {
        console.error('Error adding discussion message:', error);
        return null;
      }

      return data;
    } catch (error) {
      console.error('Error in addDiscussionMessage:', error);
      return null;
    }
  }

  static async getDiscussionMessages(discussionId: string, limit: number = 50, offset: number = 0): Promise<DiscussionMessage[]> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('get_discussion_messages', {
          auth_user_id: authUserId,
          discussion_id: discussionId,
          limit_count: limit,
          offset_count: offset
        });

      if (error) {
        console.error('Error getting discussion messages:', error);
        return [];
      }

      return data || [];
    } catch (error) {
      console.error('Error in getDiscussionMessages:', error);
      return [];
    }
  }

  // =====================================================
  // FRIEND FUNCTIONS
  // =====================================================

  static async sendFriendRequest(targetUserId: string): Promise<boolean> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('send_friend_request', {
          auth_user_id: authUserId,
          target_user_id: targetUserId
        });

      if (error) {
        console.error('Error sending friend request:', error);
        return false;
      }

      return data;
    } catch (error) {
      console.error('Error in sendFriendRequest:', error);
      return false;
    }
  }

  static async acceptFriendRequest(requesterUserId: string): Promise<boolean> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('accept_friend_request', {
          auth_user_id: authUserId,
          requester_user_id: requesterUserId
        });

      if (error) {
        console.error('Error accepting friend request:', error);
        return false;
      }

      return data;
    } catch (error) {
      console.error('Error in acceptFriendRequest:', error);
      return false;
    }
  }

  static async getFriendConnections(): Promise<FriendConnection[]> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('get_friend_connections', {
          auth_user_id: authUserId
        });

      if (error) {
        console.error('Error getting friend connections:', error);
        return [];
      }

      return data || [];
    } catch (error) {
      console.error('Error in getFriendConnections:', error);
      return [];
    }
  }

  static async generateFriendRecommendations(): Promise<number> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('generate_friend_recommendations', {
          auth_user_id: authUserId
        });

      if (error) {
        console.error('Error generating friend recommendations:', error);
        return 0;
      }

      return data || 0;
    } catch (error) {
      console.error('Error in generateFriendRecommendations:', error);
      return 0;
    }
  }

  static async getFriendRecommendations(): Promise<FriendRecommendation[]> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('get_friend_recommendations', {
          auth_user_id: authUserId
        });

      if (error) {
        console.error('Error getting friend recommendations:', error);
        return [];
      }

      return data || [];
    } catch (error) {
      console.error('Error in getFriendRecommendations:', error);
      return [];
    }
  }

  // =====================================================
  // UTILITY FUNCTIONS
  // =====================================================

  static async checkUserHasPersonalityProfile(): Promise<boolean> {
    try {
      const authUserId = await this.getCurrentUserId();
      
      const { data, error } = await supabase
        .rpc('user_has_personality_profile', {
          auth_user_id: authUserId
        });

      if (error) {
        console.error('Error checking personality profile:', error);
        return false;
      }

      return data || false;
    } catch (error) {
      console.error('Error in checkUserHasPersonalityProfile:', error);
      return false;
    }
  }

  // UI Helper Functions
  static getPersonalityTraitColor(trait: string): string {
    const colors: { [key: string]: string } = {
      'openness': 'from-purple-500 to-purple-600',
      'conscientiousness': 'from-blue-500 to-blue-600',
      'extraversion': 'from-green-500 to-green-600',
      'agreeableness': 'from-pink-500 to-pink-600',
      'emotional_stability': 'from-yellow-500 to-yellow-600',
      'rational_thinking': 'from-indigo-500 to-indigo-600',
      'core_values': 'from-red-500 to-red-600',
      'lifestyle': 'from-teal-500 to-teal-600',
      'social_style': 'from-orange-500 to-orange-600',
      'self_expression': 'from-cyan-500 to-cyan-600'
    };
    return colors[trait.toLowerCase()] || 'from-gray-500 to-gray-600';
  }

  static getMatchScoreColor(score: number): string {
    if (score >= 90) return 'text-green-400';
    if (score >= 80) return 'text-blue-400';
    if (score >= 70) return 'text-yellow-400';
    if (score >= 60) return 'text-orange-400';
    return 'text-red-400';
  }

  static getMatchScoreLabel(score: number): string {
    if (score >= 90) return 'Excellent Match';
    if (score >= 80) return 'Great Match';
    if (score >= 70) return 'Good Match';
    if (score >= 60) return 'Fair Match';
    return 'Poor Match';
  }

  static formatDate(dateString: string): string {
    const date = new Date(dateString);
    const now = new Date();
    const diffInHours = (now.getTime() - date.getTime()) / (1000 * 60 * 60);

    if (diffInHours < 1) {
      return 'Just now';
    } else if (diffInHours < 24) {
      return `${Math.floor(diffInHours)}h ago`;
    } else if (diffInHours < 168) { // 7 days
      return `${Math.floor(diffInHours / 24)}d ago`;
    } else {
      return date.toLocaleDateString();
    }
  }
}