import { supabase } from '../lib/supabase';
import { 
  BookClub, 
  Discussion, 
  DiscussionMessage, 
  FriendConnection, 
  FriendRecommendation,
  CreateBookClubData,
  CreateBookClubServiceData,
  CreateDiscussionData,
  ClubInvitation,
  UserSearchResult,
  SentInvitation
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
        creatorName: club.creator_name || 'Unknown'
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
  // ADMIN FUNCTIONS
  // =====================================================

  static async inviteUserToBookClub(clubId: string, invitedUserId: string): Promise<{ success: boolean; message: string }> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('invite_user_to_book_club', {
          auth_user_id: authUserId,
          club_id_param: clubId,
          invited_user_id: invitedUserId
        });

      if (error) {
        console.error('Error inviting user:', error);
        return { success: false, message: 'Failed to invite user' };
      }

      return data[0] || { success: false, message: 'Unknown error' };
    } catch (error) {
      console.error('Error in inviteUserToBookClub:', error);
      return { success: false, message: 'Failed to invite user' };
    }
  }

  static async removeUserFromBookClub(clubId: string, userIdToRemove: string): Promise<{ success: boolean; message: string }> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('remove_user_from_book_club', {
          auth_user_id: authUserId,
          club_id_param: clubId,
          user_to_remove_id: userIdToRemove
        });

      if (error) {
        console.error('Error removing user:', error);
        return { success: false, message: 'Failed to remove user' };
      }

      return data[0] || { success: false, message: 'Unknown error' };
    } catch (error) {
      console.error('Error in removeUserFromBookClub:', error);
      return { success: false, message: 'Failed to remove user' };
    }
  }

  static async promoteUserToAdmin(clubId: string, userIdToPromote: string): Promise<{ success: boolean; message: string }> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('promote_user_to_admin', {
          auth_user_id: authUserId,
          club_id_param: clubId,
          user_to_promote_id: userIdToPromote
        });

      if (error) {
        console.error('Error promoting user:', error);
        return { success: false, message: 'Failed to promote user' };
      }

      return data[0] || { success: false, message: 'Unknown error' };
    } catch (error) {
      console.error('Error in promoteUserToAdmin:', error);
      return { success: false, message: 'Failed to promote user' };
    }
  }

  static async updateBookClubDetails(
    clubId: string, 
    updates: {
      name?: string;
      description?: string;
      currentBookTitle?: string;
      currentBookAuthor?: string;
      meetingInfo?: string;
    }
  ): Promise<{ success: boolean; message: string }> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('update_book_club_details', {
          auth_user_id: authUserId,
          club_id_param: clubId,
          new_name: updates.name || null,
          new_description: updates.description || null,
          new_current_book_title: updates.currentBookTitle || null,
          new_current_book_author: updates.currentBookAuthor || null,
          new_meeting_info: updates.meetingInfo || null
        });

      if (error) {
        console.error('Error updating club details:', error);
        return { success: false, message: 'Failed to update club details' };
      }

      return data[0] || { success: false, message: 'Unknown error' };
    } catch (error) {
      console.error('Error in updateBookClubDetails:', error);
      return { success: false, message: 'Failed to update club details' };
    }
  }

  // =====================================================
  // POLL FUNCTIONS
  // =====================================================

  static async createBookSelectionPoll(
    clubId: string,
    title: string,
    description: string,
    bookOptions: Array<{
      title: string;
      author: string;
      coverUrl?: string;
      description?: string;
    }>,
    closesAt?: Date
  ): Promise<{ success: boolean; message: string; pollId?: string }> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('create_book_selection_poll', {
          auth_user_id: authUserId,
          club_id_param: clubId,
          poll_title: title,
          poll_description: description,
          book_options: bookOptions, // Send as array, not stringified
          closes_at: closesAt?.toISOString() || null
        });

      if (error) {
        console.error('Error creating poll:', error);
        return { success: false, message: 'Failed to create poll' };
      }

      const result = data[0] || { success: false, message: 'Unknown error' };
      return {
        success: result.success,
        message: result.message,
        pollId: result.poll_id
      };
    } catch (error) {
      console.error('Error in createBookSelectionPoll:', error);
      return { success: false, message: 'Failed to create poll' };
    }
  }

  static async voteOnPoll(pollId: string, optionIndex: number): Promise<{ success: boolean; message: string }> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      console.log('Voting on poll:', { pollId, optionIndex, authUserId });

      const { data, error } = await supabase
        .rpc('vote_on_poll', {
          auth_user_id: authUserId,
          poll_id_param: pollId,
          option_index: optionIndex
        });

      console.log('Vote response:', { data, error });

      if (error) {
        console.error('Error voting on poll:', error);
        return { success: false, message: `Failed to vote: ${error.message}` };
      }

      const result = data[0] || { success: false, message: 'Unknown error' };
      console.log('Vote result:', result);
      return result;
    } catch (error) {
      console.error('Error in voteOnPoll:', error);
      return { success: false, message: `Failed to vote: ${error}` };
    }
  }

  static async getClubPolls(clubId: string): Promise<any[]> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('get_club_polls', {
          auth_user_id: authUserId,
          club_id_param: clubId
        });

      if (error) {
        console.error('Error getting polls:', error);
        return [];
      }

      return data || [];
    } catch (error) {
      console.error('Error in getClubPolls:', error);
      return [];
    }
  }

  static async getPollResults(pollId: string): Promise<any> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('get_poll_results', {
          auth_user_id: authUserId,
          poll_id_param: pollId
        });

      if (error) {
        console.error('Error getting poll results:', error);
        return null;
      }

      return data[0] || null;
    } catch (error) {
      console.error('Error in getPollResults:', error);
      return null;
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

  static async toggleBookClubVisibility(clubId: string, isPublic: boolean): Promise<{ success: boolean; message: string }> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      console.log('Toggling club visibility:', { clubId, isPublic, authUserId });

      const { data, error } = await supabase
        .rpc('toggle_book_club_visibility', {
          auth_user_id: authUserId,
          club_id_param: clubId,
          is_public_param: isPublic
        });

      console.log('Toggle visibility response:', { data, error });

      if (error) {
        console.error('Error toggling club visibility:', error);
        return { success: false, message: `Failed to update club visibility: ${error.message}` };
      }

      const result = data[0] || { success: false, message: 'Unknown error' };
      console.log('Toggle visibility result:', result);
      return result;
    } catch (error) {
      console.error('Error in toggleBookClubVisibility:', error);
      return { success: false, message: 'Failed to update club visibility' };
    }
  }

  // =====================================================
  // CLUB INVITATION FUNCTIONS
  // =====================================================

  // Search users by username
  static async searchUsersByUsername(searchTerm: string): Promise<UserSearchResult[]> {
    try {
      if (!searchTerm || searchTerm.trim().length < 2) {
        return [];
      }

      const { data, error } = await supabase
        .rpc('search_users_by_username', {
          search_term: searchTerm.trim(),
          limit_count: 10
        });

      if (error) {
        console.error('Error searching users:', error);
        return [];
      }

      // Transform database results to match TypeScript interface
      const transformedResults: UserSearchResult[] = (data || []).map((user: any) => ({
        id: user.id,
        username: user.username,
        name: user.name,
        avatarUrl: user.avatar_url // Map snake_case to camelCase
      }));

      console.log('Transformed search results:', transformedResults);
      return transformedResults;
    } catch (error) {
      console.error('Error in searchUsersByUsername:', error);
      return [];
    }
  }

  // Invite user to club by username
  static async inviteUserToClub(clubId: string, username: string, message?: string): Promise<{ success: boolean; message: string; data?: any }> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      console.log('Inviting user to club:', { clubId, username, authUserId });

      const { data, error } = await supabase
        .rpc('invite_user_to_club', {
          auth_user_id: authUserId,
          club_id_param: clubId,
          username_param: username,
          message_param: message || null
        });

      console.log('Invite user response:', { data, error });

      if (error) {
        console.error('Error inviting user:', error);
        return { success: false, message: `Failed to send invitation: ${error.message}` };
      }

      if (data && data.success) {
        return { 
          success: true, 
          message: data.message || 'Invitation sent successfully!',
          data: data
        };
      } else {
        return { 
          success: false, 
          message: data?.error || 'Failed to send invitation' 
        };
      }
    } catch (error) {
      console.error('Error in inviteUserToClub:', error);
      return { success: false, message: 'Failed to send invitation' };
    }
  }

  // Get user's received club invitations
  static async getUserClubInvitations(): Promise<ClubInvitation[]> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('get_user_club_invitations', {
          auth_user_id: authUserId
        });

      if (error) {
        console.error('Error getting user invitations:', error);
        return [];
      }

      // Transform database data to match UI interface
      const transformedData: ClubInvitation[] = (data || []).map((invitation: any) => ({
        id: invitation.id,
        clubId: invitation.club_id,
        clubName: invitation.club_name,
        clubDescription: invitation.club_description,
        inviterName: invitation.inviter_name,
        inviterUsername: invitation.inviter_username,
        message: invitation.message,
        createdAt: invitation.created_at,
        expiresAt: invitation.expires_at,
        status: invitation.status
      }));

      return transformedData;
    } catch (error) {
      console.error('Error in getUserClubInvitations:', error);
      return [];
    }
  }

  // Respond to club invitation
  static async respondToClubInvitation(invitationId: string, response: 'accepted' | 'declined'): Promise<{ success: boolean; message: string; data?: any }> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      console.log('Responding to club invitation:', { invitationId, response, authUserId });

      const { data, error } = await supabase
        .rpc('respond_to_club_invitation', {
          auth_user_id: authUserId,
          invitation_id_param: invitationId,
          response: response
        });

      console.log('Respond to invitation response:', { data, error });

      if (error) {
        console.error('Error responding to invitation:', error);
        return { success: false, message: `Failed to respond to invitation: ${error.message}` };
      }

      if (data && data.success) {
        return { 
          success: true, 
          message: data.message || `Invitation ${response} successfully!`,
          data: data
        };
      } else {
        return { 
          success: false, 
          message: data?.error || 'Failed to respond to invitation' 
        };
      }
    } catch (error) {
      console.error('Error in respondToClubInvitation:', error);
      return { success: false, message: 'Failed to respond to invitation' };
    }
  }

  // Get sent invitations for a club (admin only)
  static async getClubSentInvitations(clubId: string): Promise<SentInvitation[]> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('get_club_sent_invitations', {
          auth_user_id: authUserId,
          club_id_param: clubId
        });

      if (error) {
        console.error('Error getting club sent invitations:', error);
        return [];
      }

      // Transform database data to match UI interface
      const transformedData: SentInvitation[] = (data || []).map((invitation: any) => ({
        id: invitation.id,
        inviteeUsername: invitation.invitee_username,
        inviteeName: invitation.invitee_name,
        message: invitation.message,
        status: invitation.status,
        createdAt: invitation.created_at,
        expiresAt: invitation.expires_at
      }));

      return transformedData;
    } catch (error) {
      console.error('Error in getClubSentInvitations:', error);
      return [];
    }
  }

  // Check if user is admin of a club
  static async isClubAdmin(clubId: string): Promise<boolean> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      // Get user's role in the club
      const { data, error } = await supabase
        .from('club_memberships')
        .select('role')
        .eq('club_id', clubId)
        .eq('user_id', (await supabase
          .from('users')
          .select('id')
          .eq('auth_user_id', authUserId)
          .single()).data?.id)
        .single();

      if (error || !data) {
        return false;
      }

      return data.role === 'owner' || data.role === 'admin';
    } catch (error) {
      console.error('Error checking if user is club admin:', error);
      return false;
    }
  }
}