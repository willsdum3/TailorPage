export interface Question {
  id: number;
  text: string;
  trait: keyof PersonalityProfile;
  type: 'statement' | 'book';
}

export interface BookQuestion {
  id: number;
  title: string;
  author: string;
  description: string;
  trait: keyof PersonalityProfile;
  coverImageUrl?: string;
}

export type LikertResponse = 1 | 2 | 3 | 4 | 5; // 1 = Highly Likely, 5 = Highly Unlikely

export type BookResponse = 'yes' | 'no';

export interface PersonalityProfile {
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

export interface DetailedPersonalityProfile {
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

export interface BookRecommendation {
  title: string;
  author: string;
  genre: string;
  description: string;
  amazonLink: string;
  reason: string;
  id: string;
  coverImageUrl?: string;
}

export interface FavoriteBook extends BookRecommendation {
  dateAdded: string;
}

export interface User {
  id: string;
  name: string;
  username: string;
  email: string;
  imageUrl?: string;
}

export interface LoginCredentials {
  email: string;
  username: string;
  password: string;
}

export interface SignupData {
  name: string;
  username: string;
  email: string;
  password: string;
}

// Tailor Mates Types
export interface BookClub {
  id: string;
  name: string;
  description: string;
  currentBookTitle?: string;
  currentBookAuthor?: string;
  memberCount: number;
  maxMembers: number;
  personalityTraits: string[];
  meetingTime?: string;
  nextMeetingDate?: string;
  isPrivate: boolean;
  tags: string[];
  createdBy: string;
  createdAt: string;
  isMember: boolean;
  userRole: string;
  creatorName: string;
}

export interface Discussion {
  id: string;
  title: string;
  content: string;
  bookTitle?: string;
  bookAuthor?: string;
  tags: string[];
  createdBy: string;
  createdAt: string;
  participantCount: number;
  lastActivity: string;
  isParticipant: boolean;
  creatorName: string;
}

export interface DiscussionMessage {
  id: string;
  content: string;
  createdAt: string;
  userId: string;
  userName: string;
  userImageUrl?: string;
  isEdited: boolean;
}

export interface FriendConnection {
  id: string;
  friendId: string;
  friendName: string;
  friendUsername: string;
  friendImageUrl?: string;
  status: 'pending' | 'accepted' | 'rejected';
  personalityMatchScore: number;
  createdAt: string;
}

export interface FriendRecommendation {
  id: string;
  recommendedUserId: string;
  recommendedUserName: string;
  recommendedUserUsername: string;
  recommendedUserImageUrl?: string;
  matchScore: number;
  matchReasons: string[];
  createdAt: string;
}

export interface CreateBookClubData {
  name: string;
  description: string;
  currentBookTitle?: string;
  currentBookAuthor?: string;
  maxMembers: number;
  personalityTraits: string[];
  meetingTime?: string;
  nextMeetingDate?: string;
  isPrivate: boolean;
  tags: string[];
}

export interface CreateDiscussionData {
  title: string;
  content: string;
  bookTitle?: string;
  bookAuthor?: string;
  tags: string[];
}