export interface Question {
  id: number;
  text: string;
  trait: keyof PersonalityProfile;
}

export type LikertResponse = 1 | 2 | 3 | 4 | 5; // 1 = Highly Likely, 5 = Highly Unlikely

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
}

export interface FavoriteBook extends BookRecommendation {
  dateAdded: string;
}

export interface User {
  id: string;
  name: string;
  username: string;
  email: string;
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