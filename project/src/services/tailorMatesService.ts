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
  // Book Club Functions
  static async getBookClubs(clerkUserId: string): Promise<BookClub[]> {
    const { data, error } = await supabase.rpc('get_book_clubs', {
      user_clerk_id: clerkUserId
    });

    if (error) {
      console.error('Error fetching book clubs:', error);
      throw new Error('Failed to fetch book clubs');
    }

    return data || [];
  }

  static async createBookClub(clubData: CreateBookClubData, clerkUserId: string): Promise<string> {
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
      throw new Error('Failed to create book club');
    }

    return data;
  }

  static async joinBookClub(clubId: string, clerkUserId: string): Promise<boolean> {
    const { data, error } = await supabase.rpc('join_book_club', {
      user_clerk_id: clerkUserId,
      club_id: clubId
    });

    if (error) {
      console.error('Error joining book club:', error);
      throw new Error('Failed to join book club');
    }

    return data;
  }

  static async leaveBookClub(clubId: string, clerkUserId: string): Promise<boolean> {
    const { data, error } = await supabase.rpc('leave_book_club', {
      user_clerk_id: clerkUserId,
      club_id: clubId
    });

    if (error) {
      console.error('Error leaving book club:', error);
      throw new Error('Failed to leave book club');
    }

    return data;
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
