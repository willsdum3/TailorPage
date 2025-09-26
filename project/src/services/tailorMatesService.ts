import { supabase } from '../lib/supabase';
import { 
  BookClub, 
  Discussion, 
  DiscussionMessage, 
  FriendConnection, 
  FriendRecommendation,
  FriendConversation,
  FriendMessage,
  Notification,
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

  // Helper function to get current user's internal user ID from users table
  static async getCurrentInternalUserId(): Promise<string> {
    const authUserId = await this.getCurrentUserId();
    const { data: user, error } = await supabase
      .from('users')
      .select('id')
      .eq('auth_user_id', authUserId)
      .single();

    if (error || !user) {
      throw new Error('User not found in database');
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

  static async deleteBookClub(clubId: string): Promise<{success: boolean, error?: string}> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('delete_book_club', {
          p_auth_user_id: authUserId,
          p_book_club_id: clubId
        });

      if (error) {
        console.error('Error deleting book club:', error);
        return { success: false, error: error.message };
      }

      // Parse the JSON response from the database function
      const result = typeof data === 'string' ? JSON.parse(data) : data;
      
      if (result.success) {
        return { success: true };
      } else {
        return { success: false, error: result.error };
      }
    } catch (error) {
      console.error('Error in deleteBookClub:', error);
      return { success: false, error: 'Failed to delete book club' };
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

      console.log('Promoting user to admin:', { clubId, userIdToPromote, authUserId });

      const { data, error } = await supabase
        .rpc('promote_user_to_admin', {
          auth_user_id: authUserId,
          club_id_param: clubId,
          user_to_promote_id: userIdToPromote
        });

      console.log('Promote user response:', { data, error });

      if (error) {
        console.error('Error promoting user:', error);
        return { success: false, message: `Failed to promote user: ${error.message}` };
      }

      // Handle JSON response from the new database function
      if (data && data.success) {
        return { 
          success: true, 
          message: data.message || 'User promoted to admin successfully!'
        };
      } else {
        return { 
          success: false, 
          message: data?.error || 'Failed to promote user' 
        };
      }
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

      // Automatically run poll maintenance when loading polls (silent cleanup)
      try {
        await this.maintainPollHygiene();
        console.log('Poll maintenance completed automatically');
      } catch (maintenanceError) {
        console.warn('Poll maintenance failed, continuing with poll loading:', maintenanceError);
      }

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
          tags: discussionData.tags || []
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
        lastActivity: discussion.last_activity || discussion.created_at,
        isParticipant: discussion.is_participant || false,
        creatorName: discussion.creator_name || 'Unknown',
        creatorUsername: discussion.creator_username,
        isCreatedByUser: discussion.is_created_by_user || false
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

  static async leaveDiscussion(discussionId: string): Promise<boolean> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('leave_discussion', {
          p_auth_user_id: authUserId,
          p_discussion_id: discussionId
        });

      if (error) {
        console.error('Error leaving discussion:', error);
        return false;
      }

      return data;
    } catch (error) {
      console.error('Error in leaveDiscussion:', error);
      return false;
    }
  }

  static async deleteDiscussion(discussionId: string): Promise<{success: boolean, error?: string}> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('delete_discussion', {
          p_auth_user_id: authUserId,
          p_discussion_id: discussionId
        });

      if (error) {
        console.error('Error deleting discussion:', error);
        return { success: false, error: error.message };
      }

      // Parse the JSON response from the database function
      const result = typeof data === 'string' ? JSON.parse(data) : data;
      
      if (result.success) {
        return { success: true };
      } else {
        return { success: false, error: result.error };
      }
    } catch (error) {
      console.error('Error in deleteDiscussion:', error);
      return { success: false, error: 'Failed to delete discussion' };
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

      // Debug logging (simplified)
      console.log('addDiscussionMessage response:', data);

      // Parse JSON response from database function
      if (data && typeof data === 'object' && data.error) {
        console.error('Database function returned error:', data.error);
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
          p_discussion_id: discussionId,
          limit_count: limit,
          offset_count: offset
        });

      if (error) {
        console.error('Error getting discussion messages:', error);
        return [];
      }

      // Debug logging (simplified)
      console.log('getDiscussionMessages response:', data, 'type:', typeof data);

      // Parse JSON response from database function
      if (data && typeof data === 'string') {
        try {
          const parsed = JSON.parse(data);
          console.log('getDiscussionMessages parsed result:', parsed);
          return parsed;
        } catch (parseError) {
          console.error('Error parsing discussion messages JSON:', parseError);
          return [];
        }
      }
      
      // If data is already an array, return it directly
      const result = Array.isArray(data) ? data : (data ? [data] : []);
      console.log('getDiscussionMessages final result:', result);
      return result;
    } catch (error) {
      console.error('Error in getDiscussionMessages:', error);
      return [];
    }
  }

  // =====================================================
  // FRIEND FUNCTIONS
  // =====================================================


  static async getFriendRequests(): Promise<FriendConnection[]> {
    try {
      const currentUserId = await this.getCurrentInternalUserId();

      const { data, error } = await supabase
        .rpc('get_friend_requests', {
          p_auth_user_id: currentUserId
        });

      if (error) {
        console.error('Error getting friend requests:', error);
        return [];
      }

      // Map snake_case database fields to camelCase frontend fields
      return (data || []).map((request: any) => ({
        id: request.id,
        friendId: request.friend_id,
        friendName: request.friend_name,
        friendUsername: request.friend_username,
        friendImageUrl: request.friend_image_url,
        status: request.status,
        personalityMatchScore: request.personality_match_score,
        createdAt: request.created_at
      }));
    } catch (error) {
      console.error('Error in getFriendRequests:', error);
      return [];
    }
  }

  static async acceptFriendRequest(requesterUserId: string): Promise<{success: boolean, error?: string}> {
    try {
      const currentUserId = await this.getCurrentInternalUserId();

      const { data, error } = await supabase
        .rpc('accept_friend_request', {
          p_auth_user_id: currentUserId,
          p_requester_user_id: requesterUserId
        });

      if (error) {
        console.error('Error accepting friend request:', error);
        return { success: false, error: error.message };
      }

      // Parse JSON response
      const result = typeof data === 'string' ? JSON.parse(data) : data;
      
      if (result.success) {
        return { success: true };
      } else {
        return { success: false, error: result.error };
      }
    } catch (error) {
      console.error('Error in acceptFriendRequest:', error);
      return { success: false, error: 'Failed to accept friend request' };
    }
  }

  static async rejectFriendRequest(requesterUserId: string): Promise<{success: boolean, error?: string}> {
    try {
      const currentUserId = await this.getCurrentInternalUserId();

      const { data, error } = await supabase
        .rpc('reject_friend_request', {
          p_auth_user_id: currentUserId,
          p_requester_user_id: requesterUserId
        });

      if (error) {
        console.error('Error rejecting friend request:', error);
        return { success: false, error: error.message };
      }

      // Parse JSON response
      const result = typeof data === 'string' ? JSON.parse(data) : data;
      
      if (result.success) {
        return { success: true };
      } else {
        return { success: false, error: result.error };
      }
    } catch (error) {
      console.error('Error in rejectFriendRequest:', error);
      return { success: false, error: 'Failed to reject friend request' };
    }
  }

  static async getFriendConnections(): Promise<FriendConnection[]> {
    try {
      const currentUserId = await this.getCurrentInternalUserId();
      console.log('getFriendConnections - currentUserId:', currentUserId);

      const { data, error } = await supabase
        .rpc('get_friend_connections', {
          p_auth_user_id: currentUserId
        });

      console.log('getFriendConnections - RPC response:', { data, error });

      if (error) {
        console.error('Error getting friend connections:', error);
        return [];
      }

      // Map snake_case database fields to camelCase frontend fields
      const mappedData = (data || []).map((connection: any) => ({
        id: connection.id,
        friendId: connection.friend_id,
        friendName: connection.friend_name,
        friendUsername: connection.friend_username,
        friendImageUrl: connection.friend_image_url,
        status: connection.status,
        personalityMatchScore: connection.personality_match_score,
        createdAt: connection.created_at
      }));

      // Filter out blocked users
      const filteredData = [];
      const currentAuthUserId = await this.getCurrentUserId();
      
      for (const connection of mappedData) {
        if (connection.status === 'accepted') {
          try {
            // Check if this friend is blocked by current user or has blocked current user
            // Try to determine if friendId is internal ID or auth user ID
            let friendAuthUserId = connection.friendId;
            
            // First, try to get auth_user_id assuming friendId is an internal ID
            const authUserIdFromInternal = await this.getAuthUserIdFromInternalId(connection.friendId);
            if (authUserIdFromInternal) {
              friendAuthUserId = authUserIdFromInternal;
            }
            // If that fails, assume friendId is already an auth user ID
            
            const isBlocked = await this.isUserBlocked(currentAuthUserId, friendAuthUserId);
            const isBlockedBy = await this.isUserBlocked(friendAuthUserId, currentAuthUserId);
            
            if (!isBlocked && !isBlockedBy) {
              filteredData.push(connection);
            }
          } catch (error) {
            console.error('Error checking blocking status for friend:', connection.friendId, error);
            // If blocking check fails, include the friend (fallback)
            filteredData.push(connection);
          }
        } else {
          // Keep non-accepted connections (pending requests, etc.)
          filteredData.push(connection);
        }
      }

      console.log('getFriendConnections - filtered data:', filteredData);
      return filteredData;
    } catch (error) {
      console.error('Error in getFriendConnections:', error);
      return [];
    }
  }

  static async generateFriendRecommendations(): Promise<number> {
    try {
      const currentUserId = await this.getCurrentUserId();

      const { data, error } = await supabase
        .rpc('generate_friend_recommendations', {
          p_auth_user_id: currentUserId
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
      const currentUserId = await this.getCurrentUserId();

      const { data, error } = await supabase
        .rpc('get_friend_recommendations', {
          p_auth_user_id: currentUserId
        });

      if (error) {
        console.error('Error getting friend recommendations:', error);
        return [];
      }

      // Map snake_case database fields to camelCase frontend fields
      return (data || []).map((recommendation: any) => ({
        id: recommendation.id,
        recommendedUserId: recommendation.recommended_user_id,
        recommendedUserName: recommendation.recommended_user_name,
        recommendedUserUsername: recommendation.recommended_user_username,
        recommendedUserImageUrl: recommendation.recommended_user_image_url,
        matchScore: recommendation.match_score,
        matchReasons: recommendation.match_reasons || [],
        createdAt: recommendation.created_at
      }));
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

  // Demote admin to member
  static async demoteAdminToMember(clubId: string, userId: string): Promise<{ success: boolean; message: string; data?: any }> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      console.log('Demoting admin to member:', { clubId, userId, authUserId });

      const { data, error } = await supabase
        .rpc('demote_admin_to_member', {
          auth_user_id: authUserId,
          club_id_param: clubId,
          user_id_param: userId
        });

      console.log('Demote admin response:', { data, error });

      if (error) {
        console.error('Error demoting admin:', error);
        return { success: false, message: `Failed to demote admin: ${error.message}` };
      }

      if (data && data.success) {
        return { 
          success: true, 
          message: data.message || 'Admin demoted to member successfully!',
          data: data
        };
      } else {
        return { 
          success: false, 
          message: data?.error || 'Failed to demote admin' 
        };
      }
    } catch (error) {
      console.error('Error in demoteAdminToMember:', error);
      return { success: false, message: 'Failed to demote admin' };
    }
  }


  // =====================================================
  // POLL CLEANUP FUNCTIONS
  // =====================================================

  // Run poll maintenance (close expired polls and cleanup old ones)
  static async maintainPollHygiene(): Promise<{ success: boolean; message: string; data?: any }> {
    try {
      console.log('Running poll maintenance...');

      const { data, error } = await supabase
        .rpc('maintain_poll_hygiene');

      console.log('Poll maintenance response:', { data, error });

      if (error) {
        console.error('Error maintaining polls:', error);
        return { success: false, message: `Failed to maintain polls: ${error.message}` };
      }

      if (data && data.success) {
        return { 
          success: true, 
          message: data.message || 'Poll maintenance completed successfully!',
          data: data
        };
      } else {
        return { 
          success: false, 
          message: data?.error || 'Failed to maintain polls' 
        };
      }
    } catch (error) {
      console.error('Error in maintainPollHygiene:', error);
      return { success: false, message: 'Failed to maintain polls' };
    }
  }

  // Get poll cleanup statistics
  static async getPollCleanupStats(): Promise<any> {
    try {
      const { data, error } = await supabase
        .rpc('get_poll_cleanup_stats');

      if (error) {
        console.error('Error getting poll stats:', error);
        return null;
      }

      return data;
    } catch (error) {
      console.error('Error in getPollCleanupStats:', error);
      return null;
    }
  }

  // Clean up expired polls manually (admin function)
  static async cleanupExpiredPolls(): Promise<{ success: boolean; message: string; data?: any }> {
    try {
      console.log('Cleaning up expired polls...');

      const { data, error } = await supabase
        .rpc('cleanup_expired_polls');

      console.log('Cleanup response:', { data, error });

      if (error) {
        console.error('Error cleaning up polls:', error);
        return { success: false, message: `Failed to cleanup polls: ${error.message}` };
      }

      if (data && data.success) {
        return { 
          success: true, 
          message: data.message || 'Poll cleanup completed successfully!',
          data: data
        };
      } else {
        return { 
          success: false, 
          message: data?.error || 'Failed to cleanup polls' 
        };
      }
    } catch (error) {
      console.error('Error in cleanupExpiredPolls:', error);
      return { success: false, message: 'Failed to cleanup polls' };
    }
  }

  // =====================================================
  // FRIENDS MESSAGING SYSTEM
  // =====================================================

  static async getFriendConversations(): Promise<FriendConversation[]> {
    try {
      const authUserId = await this.getCurrentUserId();

      const { data, error } = await supabase
        .rpc('get_friend_conversations', {
          p_auth_user_id: authUserId
        });

      if (error) {
        console.error('Error getting friend conversations:', error);
        return [];
      }

      // Map snake_case database fields to camelCase frontend fields
      return (data || []).map((conversation: any) => ({
        id: conversation.id,
        friendId: conversation.friend_id,
        friendName: conversation.friend_name,
        friendUsername: conversation.friend_username,
        friendImageUrl: conversation.friend_image_url,
        lastMessage: conversation.last_message,
        lastMessageAt: conversation.last_message_at,
        unreadCount: conversation.unread_count,
        createdAt: conversation.created_at
      }));
    } catch (error) {
      console.error('Error in getFriendConversations:', error);
      return [];
    }
  }

  static async getFriendMessages(conversationId: string): Promise<FriendMessage[]> {
    try {
      const authUserId = await this.getCurrentUserId();

      const { data, error } = await supabase
        .rpc('get_friend_messages', {
          p_auth_user_id: authUserId,
          p_conversation_id: conversationId,
          p_limit: 50,
          p_offset: 0
        });

      if (error) {
        console.error('Error getting friend messages:', error);
        return [];
      }

      // Map snake_case database fields to camelCase frontend fields
      return (data || []).map((message: any) => ({
        id: message.id,
        conversationId: message.conversation_id,
        senderId: message.sender_id,
        senderName: message.sender_name,
        senderUsername: message.sender_username,
        senderImageUrl: message.sender_image_url,
        content: message.content,
        messageType: message.message_type,
        bookRecommendation: message.book_recommendation || null,
        createdAt: message.created_at,
        isEdited: message.is_edited || false
      }));
    } catch (error) {
      console.error('Error in getFriendMessages:', error);
      return [];
    }
  }

  static async sendFriendMessage(friendId: string, content: string): Promise<FriendMessage | null> {
    try {
      const authUserId = await this.getCurrentUserId();

      const { data, error } = await supabase
        .rpc('send_friend_message', {
          p_auth_user_id: authUserId,
          p_friend_id: friendId,
          p_content: content
        });

      if (error) {
        console.error('Error sending friend message:', error);
        return null;
      }

      // Parse JSON response
      const result = typeof data === 'string' ? JSON.parse(data) : data;
      
      if (result.success) {
        return result.message;
      } else {
        console.error('Failed to send message:', result.error);
        return null;
      }
    } catch (error) {
      console.error('Error in sendFriendMessage:', error);
      return null;
    }
  }

  static async markConversationAsRead(conversationId: string): Promise<boolean> {
    try {
      const authUserId = await this.getCurrentUserId();

      const { data, error } = await supabase
        .rpc('mark_conversation_as_read', {
          p_auth_user_id: authUserId,
          p_conversation_id: conversationId
        });

      if (error) {
        console.error('Error marking conversation as read:', error);
        return false;
      }

      return data?.success || false;
    } catch (error) {
      console.error('Error in markConversationAsRead:', error);
      return false;
    }
  }

  static async sendBookRecommendation(
    friendId: string, 
    bookTitle: string, 
    bookAuthor: string, 
    description?: string, 
    amazonUrl?: string,
    coverImageUrl?: string
  ): Promise<FriendMessage | null> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('send_book_recommendation', {
          p_auth_user_id: authUserId,
          p_friend_id: friendId,
          p_book_title: bookTitle,
          p_book_author: bookAuthor,
          p_description: description,
          p_amazon_url: amazonUrl,
          p_cover_image_url: coverImageUrl
        });

      if (error) {
        console.error('Error sending book recommendation:', error);
        return null;
      }

      // Parse JSON response
      const result = typeof data === 'string' ? JSON.parse(data) : data;
      
      if (result.success) {
        return result.message;
      } else {
        console.error('Failed to send book recommendation:', result.error);
        return null;
      }
    } catch (error) {
      console.error('Error in sendBookRecommendation:', error);
      return null;
    }
  }

  // =====================================================
  // FRIENDS MANAGEMENT SYSTEM
  // =====================================================

  static async sendFriendRequest(targetUserId: string, message?: string): Promise<{success: boolean, error?: string}> {
    try {
      const currentUserId = await this.getCurrentInternalUserId();
      
      // Prevent users from sending friend requests to themselves
      if (currentUserId === targetUserId) {
        return { success: false, error: 'You cannot send a friend request to yourself' };
      }

      const { data, error } = await supabase
        .rpc('send_friend_request', {
          p_auth_user_id: currentUserId,
          p_target_user_id: targetUserId,
          p_message: message
        });

      if (error) {
        console.error('Error sending friend request:', error);
        return { success: false, error: error.message };
      }

      // Parse JSON response
      const result = typeof data === 'string' ? JSON.parse(data) : data;
      
      if (result.success) {
        return { success: true };
      } else {
        return { success: false, error: result.error };
      }
    } catch (error) {
      console.error('Error in sendFriendRequest:', error);
      return { success: false, error: 'Failed to send friend request' };
    }
  }

  static async removeFriend(friendId: string): Promise<{success: boolean, error?: string}> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      console.log('Removing friend with internal ID:', friendId);

      // Use the new function that handles user ID lookup internally
      console.log('Calling RPC with params:', { p_auth_user_id: authUserId, p_friend_internal_id: friendId });
      console.log('authUserId type:', typeof authUserId, 'value:', authUserId);
      console.log('friendId type:', typeof friendId, 'value:', friendId);
      
      const { data, error } = await supabase
        .rpc('remove_friend_by_internal_id', {
          p_auth_user_id: authUserId,
          p_friend_internal_id: friendId
        });

      console.log('RPC response - data:', data, 'error:', error);
      console.log('RPC response - data type:', typeof data);
      console.log('RPC response - data keys:', data ? Object.keys(data) : 'null');

      if (error) {
        console.error('Error removing friend:', error);
        return { success: false, error: error.message };
      }

      // Handle response data
      console.log('Remove friend result:', data);
      console.log('Remove friend result.success:', data?.success);
      console.log('Remove friend result.error:', data?.error);
      
      if (data && data.success === true) {
        console.log('Returning success: true');
        return { success: true };
      } else {
        console.log('Returning success: false, error:', data?.error || 'Unknown error');
        return { success: false, error: data?.error || 'Unknown error' };
      }
    } catch (error) {
      console.error('Error in removeFriend:', error);
      return { success: false, error: 'Failed to remove friend' };
    }
  }

  static async blockFriend(friendId: string): Promise<{success: boolean, error?: string}> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      console.log('Blocking friend with ID:', friendId);
      console.log('Current user auth ID:', authUserId);

      // Use the flexible function that can handle both internal IDs and auth user IDs
      const { data, error } = await supabase
        .rpc('block_friend_flexible', {
          p_blocker_auth_user_id: authUserId,
          p_blocked_user_id: friendId
        });

      if (error) {
        console.error('Error blocking friend:', error);
        return { success: false, error: error.message };
      }

      // Parse JSON response
      const result = typeof data === 'string' ? JSON.parse(data) : data;
      console.log('Block friend result:', result);
      
      if (result.success) {
        console.log('Blocking and removal completed:', result);
        return { success: true };
      } else {
        return { success: false, error: result.error };
      }
    } catch (error) {
      console.error('Error in blockFriend:', error);
      return { success: false, error: 'Failed to block friend' };
    }
  }

  static async getBlockedUsers(): Promise<FriendConnection[]> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      console.log('Getting blocked users for auth user ID:', authUserId);

      const { data, error } = await supabase
        .rpc('get_blocked_users', {
          p_auth_user_id: authUserId
        });

      if (error) {
        console.error('Error getting blocked users:', error);
        return [];
      }

      console.log('Blocked users data:', data);

      // Transform the data to match FriendConnection interface
      const blockedUsers: FriendConnection[] = (data || []).map((blocked: any) => ({
        id: blocked.id,
        friendId: blocked.id,
        friendName: blocked.blocked_user_name || 'Unknown',
        friendUsername: blocked.blocked_user_username || 'unknown',
        friendImageUrl: blocked.blocked_user_image_url || null,
        status: 'blocked' as const,
        personalityMatchScore: 0,
        createdAt: blocked.created_at || new Date().toISOString()
      }));

      console.log('Transformed blocked users:', blockedUsers);
      return blockedUsers;
    } catch (error) {
      console.error('Error in getBlockedUsers:', error);
      return [];
    }
  }

  // Helper function to convert auth user ID to internal user ID
  static async getInternalUserId(authUserId: string): Promise<string | null> {
    try {
      const { data, error } = await supabase
        .from('users')
        .select('id')
        .eq('auth_user_id', authUserId)
        .single();

      if (error) {
        console.error('Error getting internal user ID:', error);
        return null;
      }

      return data?.id || null;
    } catch (error) {
      console.error('Error in getInternalUserId:', error);
      return null;
    }
  }

  // Helper function to convert internal user ID to auth user ID
  static async getAuthUserIdFromInternalId(internalId: string): Promise<string | null> {
    try {
      const { data, error } = await supabase
        .from('users')
        .select('auth_user_id')
        .eq('id', internalId)
        .single();

      if (error) {
        console.error('Error getting auth user ID from internal ID:', error);
        return null;
      }

      return data?.auth_user_id || null;
    } catch (error) {
      console.error('Error in getAuthUserIdFromInternalId:', error);
      return null;
    }
  }

  // Check if a user is blocked by another user using database function
  static async isUserBlocked(blockerUserId: string, blockedUserId: string): Promise<boolean> {
    try {
      const { data, error } = await supabase
        .rpc('is_user_blocked', {
          p_blocker_auth_user_id: blockerUserId,
          p_blocked_auth_user_id: blockedUserId
        });

      if (error) {
        console.error('Error checking if user is blocked:', error);
        return false;
      }

      return data || false;
    } catch (error) {
      console.error('Error in isUserBlocked:', error);
      return false;
    }
  }

  // Check if current user is blocked by another user
  static async isCurrentUserBlockedBy(otherUserId: string): Promise<boolean> {
    try {
      const currentUserId = await this.getCurrentUserId();
      return await this.isUserBlocked(otherUserId, currentUserId);
    } catch (error) {
      console.error('Error in isCurrentUserBlockedBy:', error);
      return false;
    }
  }

  // Check if current user has blocked another user
  static async hasCurrentUserBlocked(otherUserId: string): Promise<boolean> {
    try {
      const currentUserId = await this.getCurrentUserId();
      return await this.isUserBlocked(currentUserId, otherUserId);
    } catch (error) {
      console.error('Error in hasCurrentUserBlocked:', error);
      return false;
    }
  }

  // Remove blocked user from book clubs and discussions where blocker is admin/creator
  static async removeBlockedUserFromClubsAndDiscussions(blockerUserId: string, blockedUserId: string): Promise<void> {
    try {
      console.log('Removing blocked user from clubs and discussions...');
      console.log('Blocker user ID:', blockerUserId);
      console.log('Blocked user ID:', blockedUserId);

      // First get the club IDs where blocker is admin/owner
      const { data: adminClubs, error: clubQueryError } = await supabase
        .from('club_memberships')
        .select('club_id')
        .eq('user_id', blockerUserId)
        .in('role', ['admin', 'owner']);

      if (clubQueryError) {
        console.error('Error querying admin clubs:', clubQueryError);
      } else if (adminClubs && adminClubs.length > 0) {
        const clubIds = adminClubs.map(club => club.club_id);
        
        // Remove from book clubs where blocker is admin/owner
        const { error: clubError } = await supabase
          .from('club_memberships')
          .delete()
          .eq('user_id', blockedUserId)
          .in('club_id', clubIds);

        if (clubError) {
          console.error('Error removing from book clubs:', clubError);
        } else {
          console.log('Successfully removed from book clubs');
        }
      }

      // Get discussion IDs where blocker is creator
      const { data: createdDiscussions, error: discussionQueryError } = await supabase
        .from('discussions')
        .select('id')
        .eq('created_by', blockerUserId);

      if (discussionQueryError) {
        console.error('Error querying created discussions:', discussionQueryError);
      } else if (createdDiscussions && createdDiscussions.length > 0) {
        const discussionIds = createdDiscussions.map(discussion => discussion.id);
        
        // Remove from discussions where blocker is creator
        const { error: discussionError } = await supabase
          .from('discussion_participants')
          .delete()
          .eq('user_id', blockedUserId)
          .in('discussion_id', discussionIds);

        if (discussionError) {
          console.error('Error removing from discussions:', discussionError);
        } else {
          console.log('Successfully removed from discussions');
        }
      }

    } catch (error) {
      console.error('Error in removeBlockedUserFromClubsAndDiscussions:', error);
      throw error;
    }
  }

  // =====================================================
  // NOTIFICATIONS SYSTEM
  // =====================================================

  static async getNotifications(limit: number = 50, offset: number = 0, unreadOnly: boolean = false): Promise<Notification[]> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('get_notifications', {
          p_auth_user_id: authUserId,
          p_limit: limit,
          p_offset: offset,
          p_unread_only: unreadOnly
        });

      if (error) {
        console.error('Error getting notifications:', error);
        return [];
      }

      // Parse JSON response if needed
      const notifications = typeof data === 'string' ? JSON.parse(data) : data;
      return notifications || [];
    } catch (error) {
      console.error('Error in getNotifications:', error);
      return [];
    }
  }

  static async markNotificationAsRead(notificationId: string): Promise<{success: boolean, error?: string}> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('mark_notification_as_read', {
          p_auth_user_id: authUserId,
          p_notification_id: notificationId
        });

      if (error) {
        console.error('Error marking notification as read:', error);
        return { success: false, error: error.message };
      }

      // Parse JSON response
      const result = typeof data === 'string' ? JSON.parse(data) : data;
      
      if (result.success) {
        return { success: true };
      } else {
        return { success: false, error: result.error };
      }
    } catch (error) {
      console.error('Error in markNotificationAsRead:', error);
      return { success: false, error: 'Failed to mark notification as read' };
    }
  }

  static async markAllNotificationsAsRead(): Promise<{success: boolean, error?: string}> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('mark_all_notifications_as_read', {
          p_auth_user_id: authUserId
        });

      if (error) {
        console.error('Error marking all notifications as read:', error);
        return { success: false, error: error.message };
      }

      // Parse JSON response
      const result = typeof data === 'string' ? JSON.parse(data) : data;
      
      if (result.success) {
        return { success: true };
      } else {
        return { success: false, error: result.error };
      }
    } catch (error) {
      console.error('Error in markAllNotificationsAsRead:', error);
      return { success: false, error: 'Failed to mark all notifications as read' };
    }
  }

  static async deleteNotification(notificationId: string): Promise<{success: boolean, error?: string}> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('delete_notification', {
          p_auth_user_id: authUserId,
          p_notification_id: notificationId
        });

      if (error) {
        console.error('Error deleting notification:', error);
        return { success: false, error: error.message };
      }

      // Parse JSON response
      const result = typeof data === 'string' ? JSON.parse(data) : data;
      
      if (result.success) {
        return { success: true };
      } else {
        return { success: false, error: result.error };
      }
    } catch (error) {
      console.error('Error in deleteNotification:', error);
      return { success: false, error: 'Failed to delete notification' };
    }
  }

  static async getUnreadNotificationCount(): Promise<number> {
    try {
      const authUserId = await this.getCurrentUserId();
      await this.ensureUserExists(authUserId);

      const { data, error } = await supabase
        .rpc('get_unread_notification_count', {
          p_auth_user_id: authUserId
        });

      if (error) {
        console.error('Error getting unread notification count:', error);
        return 0;
      }

      return data || 0;
    } catch (error) {
      console.error('Error in getUnreadNotificationCount:', error);
      return 0;
    }
  }
}