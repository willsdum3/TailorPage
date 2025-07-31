import { PersonalityProfile } from '../types';

export interface TraitAnalysis {
  name: string;
  score: number;
  maxScore: number;
  percentage: number;
  level: 'Very Low' | 'Low' | 'Moderate' | 'High' | 'Very High';
  description: string;
  strengths: string[];
  readingPreferences: string[];
  color: string;
}

export const analyzePersonality = (profile: PersonalityProfile): TraitAnalysis[] => {
  const maxScore = 25; // 5 questions per trait, max 5 points each
  
  return [
    {
      name: 'Openness to Experience',
      score: profile.openness,
      maxScore,
      percentage: (profile.openness / maxScore) * 100,
      level: getTraitLevel(profile.openness),
      description: getOpennessDescription(profile.openness),
      strengths: getOpennessStrengths(profile.openness),
      readingPreferences: getOpennessReadingPreferences(profile.openness),
      color: getTraitColor(profile.openness)
    },
    {
      name: 'Conscientiousness',
      score: profile.conscientiousness,
      maxScore,
      percentage: (profile.conscientiousness / maxScore) * 100,
      level: getTraitLevel(profile.conscientiousness),
      description: getConscientiousnessDescription(profile.conscientiousness),
      strengths: getConscientiousnessStrengths(profile.conscientiousness),
      readingPreferences: getConscientiousnessReadingPreferences(profile.conscientiousness),
      color: getTraitColor(profile.conscientiousness)
    },
    {
      name: 'Extraversion',
      score: profile.extraversion,
      maxScore,
      percentage: (profile.extraversion / maxScore) * 100,
      level: getTraitLevel(profile.extraversion),
      description: getExtraversionDescription(profile.extraversion),
      strengths: getExtraversionStrengths(profile.extraversion),
      readingPreferences: getExtraversionReadingPreferences(profile.extraversion),
      color: getTraitColor(profile.extraversion)
    },
    {
      name: 'Agreeableness',
      score: profile.agreeableness,
      maxScore,
      percentage: (profile.agreeableness / maxScore) * 100,
      level: getTraitLevel(profile.agreeableness),
      description: getAgreeablenessDescription(profile.agreeableness),
      strengths: getAgreeablenessStrengths(profile.agreeableness),
      readingPreferences: getAgreeablenessReadingPreferences(profile.agreeableness),
      color: getTraitColor(profile.agreeableness)
    },
    {
      name: 'Emotional Stability',
      score: profile.emotionalStability,
      maxScore,
      percentage: (profile.emotionalStability / maxScore) * 100,
      level: getTraitLevel(profile.emotionalStability),
      description: getEmotionalStabilityDescription(profile.emotionalStability),
      strengths: getEmotionalStabilityStrengths(profile.emotionalStability),
      readingPreferences: getEmotionalStabilityReadingPreferences(profile.emotionalStability),
      color: getTraitColor(profile.emotionalStability)
    }
  ];
};

const getTraitLevel = (score: number): 'Very Low' | 'Low' | 'Moderate' | 'High' | 'Very High' => {
  if (score <= 8) return 'Very Low';
  if (score <= 12) return 'Low';
  if (score <= 16) return 'Moderate';
  if (score <= 20) return 'High';
  return 'Very High';
};

const getTraitColor = (score: number): string => {
  if (score <= 8) return 'from-red-500 to-red-600';
  if (score <= 12) return 'from-yellow-500 to-orange-500';
  if (score <= 16) return 'from-blue-500 to-blue-600';
  if (score <= 20) return 'from-green-500 to-green-600';
  return 'from-emerald-500 to-emerald-600';
};

// Openness to Experience
const getOpennessDescription = (score: number): string => {
  if (score <= 8) return 'You prefer familiar experiences and established routines. You find comfort in the known and appreciate practical, concrete information.';
  if (score <= 12) return 'You have a balanced approach to new experiences, enjoying some variety while also appreciating familiar comforts.';
  if (score <= 16) return 'You are curious and open to new ideas, enjoying creative activities and exploring different perspectives.';
  if (score <= 20) return 'You are highly adventurous and imaginative, constantly seeking new experiences and creative outlets.';
  return 'You are exceptionally open-minded and creative, with a deep appreciation for abstract thinking and unconventional ideas.';
};

const getOpennessStrengths = (score: number): string[] => {
  if (score <= 8) return ['Practical thinking', 'Reliability', 'Consistency', 'Attention to detail'];
  if (score <= 12) return ['Balanced perspective', 'Adaptability', 'Practical creativity'];
  if (score <= 16) return ['Creativity', 'Curiosity', 'Flexibility', 'Imagination'];
  if (score <= 20) return ['Innovation', 'Adventure-seeking', 'Abstract thinking', 'Artistic appreciation'];
  return ['Exceptional creativity', 'Boundary-pushing thinking', 'Deep imagination', 'Philosophical depth'];
};

const getOpennessReadingPreferences = (score: number): string[] => {
  if (score <= 8) return ['Practical guides', 'Biographies', 'Historical fiction', 'Contemporary fiction'];
  if (score <= 12) return ['Contemporary fiction', 'Mystery', 'Biography', 'Self-help'];
  if (score <= 16) return ['Literary fiction', 'Science fiction', 'Fantasy', 'Philosophy'];
  if (score <= 20) return ['Experimental fiction', 'Fantasy', 'Science fiction', 'Philosophical works'];
  return ['Avant-garde literature', 'Experimental fiction', 'Abstract philosophy', 'Magical realism'];
};

// Conscientiousness
const getConscientiousnessDescription = (score: number): string => {
  if (score <= 8) return 'You prefer a more spontaneous and flexible approach to life, enjoying the freedom to adapt to changing circumstances.';
  if (score <= 12) return 'You balance planning with flexibility, maintaining some structure while allowing for spontaneity.';
  if (score <= 16) return 'You are organized and goal-oriented, with a strong sense of responsibility and attention to detail.';
  if (score <= 20) return 'You are highly disciplined and methodical, with excellent planning skills and a strong work ethic.';
  return 'You are exceptionally organized and systematic, with an outstanding ability to plan, execute, and achieve long-term goals.';
};

const getConscientiousnessStrengths = (score: number): string[] => {
  if (score <= 8) return ['Flexibility', 'Adaptability', 'Spontaneity', 'Creativity under pressure'];
  if (score <= 12) return ['Balance', 'Adaptability', 'Practical planning'];
  if (score <= 16) return ['Organization', 'Reliability', 'Goal-setting', 'Attention to detail'];
  if (score <= 20) return ['Discipline', 'Planning', 'Efficiency', 'Dependability'];
  return ['Exceptional organization', 'Strategic thinking', 'Systematic approach', 'Outstanding reliability'];
};

const getConscientiousnessReadingPreferences = (score: number): string[] => {
  if (score <= 8) return ['Adventure fiction', 'Fantasy', 'Contemporary romance', 'Creative non-fiction'];
  if (score <= 12) return ['Contemporary fiction', 'Mystery', 'Adventure', 'Self-help'];
  if (score <= 16) return ['Self-help', 'Biography', 'History', 'Business books'];
  if (score <= 20) return ['Business', 'Psychology', 'History', 'Classic literature'];
  return ['Academic texts', 'Business strategy', 'Historical analysis', 'Scientific literature'];
};

// Extraversion
const getExtraversionDescription = (score: number): string => {
  if (score <= 8) return 'You are thoughtful and reflective, preferring deep one-on-one conversations and meaningful solitude.';
  if (score <= 12) return 'You have a balanced social approach, enjoying both social interaction and quiet reflection time.';
  if (score <= 16) return 'You are outgoing and sociable, energized by social interactions and group activities.';
  if (score <= 20) return 'You are highly extroverted, thriving in social situations and naturally taking on leadership roles.';
  return 'You are exceptionally outgoing and energetic, with a natural ability to connect with others and inspire groups.';
};

const getExtraversionStrengths = (score: number): string[] => {
  if (score <= 8) return ['Deep thinking', 'Focus', 'Creativity', 'Empathy'];
  if (score <= 12) return ['Balance', 'Adaptability', 'Thoughtful communication'];
  if (score <= 16) return ['Social skills', 'Communication', 'Leadership', 'Networking'];
  if (score <= 20) return ['Charisma', 'Motivation', 'Team building', 'Public speaking'];
  return ['Exceptional charisma', 'Natural leadership', 'Inspirational communication', 'Group dynamics mastery'];
};

const getExtraversionReadingPreferences = (score: number): string[] => {
  if (score <= 8) return ['Literary fiction', 'Philosophy', 'Memoir', 'Poetry'];
  if (score <= 12) return ['Contemporary fiction', 'Biography', 'Self-help', 'Mystery'];
  if (score <= 16) return ['Contemporary romance', 'Adventure fiction', 'Biography', 'Self-help'];
  if (score <= 20) return ['Business', 'Adventure', 'Contemporary fiction', 'Biography'];
  return ['Leadership books', 'Adventure stories', 'Business strategy', 'Motivational content'];
};

// Agreeableness
const getAgreeablenessDescription = (score: number): string => {
  if (score <= 8) return 'You are independent and assertive, valuing directness and personal achievement over social harmony.';
  if (score <= 12) return 'You balance cooperation with independence, being considerate while maintaining your own perspective.';
  if (score <= 16) return 'You are empathetic and cooperative, naturally considering others\' perspectives and avoiding conflict.';
  if (score <= 20) return 'You are highly compassionate and considerate, with a strong desire to help others and maintain harmony.';
  return 'You are exceptionally empathetic and altruistic, with an outstanding ability to understand and support others.';
};

const getAgreeablenessStrengths = (score: number): string[] => {
  if (score <= 8) return ['Independence', 'Directness', 'Achievement focus', 'Decisiveness'];
  if (score <= 12) return ['Balance', 'Fairness', 'Practical empathy'];
  if (score <= 16) return ['Empathy', 'Cooperation', 'Conflict resolution', 'Teamwork'];
  if (score <= 20) return ['Compassion', 'Altruism', 'Mediation skills', 'Supportiveness'];
  return ['Exceptional empathy', 'Deep compassion', 'Natural healing', 'Community building'];
};

const getAgreeablenessReadingPreferences = (score: number): string[] => {
  if (score <= 8) return ['Thriller', 'Business', 'Political biography', 'Adventure'];
  if (score <= 12) return ['Contemporary fiction', 'Mystery', 'Biography', 'Self-help'];
  if (score <= 16) return ['Contemporary fiction', 'Romance', 'Biography', 'Psychology'];
  if (score <= 20) return ['Memoir', 'Contemporary fiction', 'Psychology', 'Social commentary'];
  return ['Memoir', 'Social justice literature', 'Psychology', 'Community-focused content'];
};

// Emotional Stability
const getEmotionalStabilityDescription = (score: number): string => {
  if (score <= 8) return 'You are emotionally sensitive and reactive, experiencing feelings deeply and being attuned to emotional nuances.';
  if (score <= 12) return 'You have a balanced emotional approach, experiencing normal emotional responses while maintaining perspective.';
  if (score <= 16) return 'You are emotionally stable and resilient, handling stress well and maintaining composure under pressure.';
  if (score <= 20) return 'You are highly emotionally stable, with excellent stress management and a calm, composed demeanor.';
  return 'You are exceptionally emotionally stable, with outstanding resilience and an ability to remain calm in any situation.';
};

const getEmotionalStabilityStrengths = (score: number): string[] => {
  if (score <= 8) return ['Emotional depth', 'Creativity', 'Empathy', 'Artistic sensitivity'];
  if (score <= 12) return ['Emotional awareness', 'Balance', 'Authentic expression'];
  if (score <= 16) return ['Stress management', 'Resilience', 'Composure', 'Problem-solving'];
  if (score <= 20) return ['Calm under pressure', 'Leadership in crisis', 'Emotional intelligence', 'Stability'];
  return ['Exceptional resilience', 'Crisis management', 'Emotional mastery', 'Unshakeable composure'];
};

const getEmotionalStabilityReadingPreferences = (score: number): string[] => {
  if (score <= 8) return ['Romance', 'Contemporary fiction', 'Self-help', 'Poetry'];
  if (score <= 12) return ['Contemporary fiction', 'Mystery', 'Self-help', 'Biography'];
  if (score <= 16) return ['Thriller', 'Mystery', 'Adventure', 'Business'];
  if (score <= 20) return ['Psychological thriller', 'Dystopian fiction', 'Business', 'Adventure'];
  return ['Intense psychological content', 'Crisis management', 'Leadership in adversity', 'High-stakes fiction'];
}; 