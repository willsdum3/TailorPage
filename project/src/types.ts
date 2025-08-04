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