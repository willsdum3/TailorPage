import React, { useEffect } from 'react';
import { ArrowLeft, TrendingUp, Brain, Target, Zap, Heart, Shield, Moon, Activity, Users, BookOpen, Coffee, CheckCircle, Apple } from 'lucide-react';
import { PersonalityProfile } from '../types';
import Logo from './Logo';
import { analyzePersonality } from '../utils/personalityAnalysis';

interface GrowthAreasDetailPageProps {
  profile: PersonalityProfile;
  onBack: () => void;
}

const GrowthAreasDetailPage: React.FC<GrowthAreasDetailPageProps> = ({ profile, onBack }) => {
  const personalityAnalysis = analyzePersonality(profile);
  
  // Get growth areas (lowest-scoring traits, max 3)
  const sortedTraits = [...personalityAnalysis].sort((a, b) => a.score - b.score);
  const lowestScore = sortedTraits[0]?.score || 0;
  const growthAreas = sortedTraits
    .filter(trait => trait.score === lowestScore)
    .slice(0, 3); // Limit to top 3 even if more are tied

  // Scroll to top when component mounts
  useEffect(() => {
    window.scrollTo(0, 0);
  }, []);
  
  // If no specific growth areas, provide universal improvement areas
  const universalGrowthAreas = [
    {
      name: 'Sleep Quality',
      icon: Moon,
      color: 'from-blue-500 to-purple-600',
      description: 'Improving your sleep habits can enhance all aspects of your life',
      tips: [
        'Establish a consistent sleep schedule',
        'Create a relaxing bedtime routine',
        'Avoid screens 1 hour before bed',
        'Keep your bedroom cool and dark',
        'Limit caffeine after 2 PM'
      ],
      benefits: ['Better mood and energy', 'Improved focus and memory', 'Stronger immune system', 'Better stress management']
    },
    {
      name: 'Physical Activity',
      icon: Activity,
      color: 'from-green-500 to-teal-600',
      description: 'Regular exercise boosts both physical and mental well-being',
      tips: [
        'Start with 10-15 minutes daily',
        'Find activities you enjoy',
        'Set realistic fitness goals',
        'Include both cardio and strength training',
        'Make it social when possible'
      ],
      benefits: ['Increased energy levels', 'Better sleep quality', 'Reduced stress and anxiety', 'Improved confidence']
    },
    {
      name: 'Healthy Nutrition',
      icon: Apple,
      color: 'from-emerald-500 to-green-600',
      description: 'Eating nutritious food fuels your body and mind for optimal performance',
      tips: [
        'Plan meals ahead of time',
        'Include protein, healthy fats, and complex carbs',
        'Eat plenty of fruits and vegetables',
        'Stay hydrated throughout the day',
        'Limit processed foods and added sugars'
      ],
      benefits: ['Sustained energy levels', 'Better mental clarity', 'Stronger immune system', 'Improved mood and focus']
    },
    {
      name: 'Social Connections',
      icon: Users,
      color: 'from-pink-500 to-rose-600',
      description: 'Building meaningful relationships enriches your life experience',
      tips: [
        'Reach out to old friends regularly',
        'Join clubs or groups with shared interests',
        'Practice active listening in conversations',
        'Show genuine interest in others',
        'Be vulnerable and authentic'
      ],
      benefits: ['Reduced feelings of loneliness', 'Better emotional support', 'Increased happiness', 'Improved communication skills']
    },
    {
      name: 'Learning & Growth',
      icon: BookOpen,
      color: 'from-amber-500 to-orange-600',
      description: 'Continuous learning keeps your mind sharp and opens new opportunities',
      tips: [
        'Read for 20 minutes daily',
        'Take online courses in areas of interest',
        'Learn a new skill or hobby',
        'Attend workshops or seminars',
        'Practice critical thinking'
      ],
      benefits: ['Enhanced problem-solving skills', 'Increased career opportunities', 'Better cognitive function', 'Greater self-confidence']
    },
    {
      name: 'Stress Management',
      icon: Coffee,
      color: 'from-indigo-500 to-purple-600',
      description: 'Developing healthy coping mechanisms improves overall well-being',
      tips: [
        'Practice deep breathing exercises',
        'Try meditation or mindfulness',
        'Set boundaries and say no when needed',
        'Take regular breaks throughout the day',
        'Engage in hobbies you enjoy'
      ],
      benefits: ['Better emotional regulation', 'Improved relationships', 'Enhanced productivity', 'Better physical health']
    }
  ];

  const getGrowthAdvice = (traitName: string) => {
    switch (traitName) {
      case 'Openness to Experience':
        return {
          title: "Expand Your Horizons",
          description: "Developing openness can lead to new opportunities and personal growth.",
          tips: [
            "Try new foods and cuisines regularly",
            "Visit museums, galleries, or cultural events",
            "Read books from different genres",
            "Travel to new places when possible",
            "Engage in creative activities like art or music"
          ],
          challenges: "You might prefer familiar routines and established ways of doing things.",
          benefits: "Increased creativity, better problem-solving, and more life opportunities."
        };
      case 'Conscientiousness':
        return {
          title: "Build Better Habits",
          description: "Improving organization and discipline can enhance your productivity and success.",
          tips: [
            "Use a planner or digital calendar",
            "Break large tasks into smaller steps",
            "Set specific, achievable goals",
            "Create daily routines and stick to them",
            "Use productivity apps and tools"
          ],
          challenges: "You might struggle with procrastination and disorganization.",
          benefits: "Better time management, increased reliability, and greater achievement."
        };
      case 'Extraversion':
        return {
          title: "Develop Social Confidence",
          description: "Building social skills can improve your relationships and career opportunities.",
          tips: [
            "Start with small social interactions",
            "Practice active listening skills",
            "Join groups with shared interests",
            "Attend networking events",
            "Volunteer for community activities"
          ],
          challenges: "You might prefer solitude and find social situations draining.",
          benefits: "Better networking, stronger relationships, and increased opportunities."
        };
      case 'Agreeableness':
        return {
          title: "Balance Empathy with Assertiveness",
          description: "Learning to be both kind and firm can improve your relationships and self-respect.",
          tips: [
            "Practice setting healthy boundaries",
            "Learn to say no when necessary",
            "Express your needs clearly",
            "Stand up for yourself respectfully",
            "Balance helping others with self-care"
          ],
          challenges: "You might avoid conflict and put others' needs before your own.",
          benefits: "Healthier relationships, better self-esteem, and reduced resentment."
        };
      case 'Emotional Stability':
        return {
          title: "Build Emotional Resilience",
          description: "Developing emotional stability can improve your mental health and relationships.",
          tips: [
            "Practice stress management techniques",
            "Develop healthy coping mechanisms",
            "Seek support when needed",
            "Maintain a regular sleep schedule",
            "Engage in regular physical activity"
          ],
          challenges: "You might experience frequent mood swings and stress easily.",
          benefits: "Better mental health, improved relationships, and enhanced decision-making."
        };
      default:
        return {
          title: "Personal Development",
          description: "Focus on continuous improvement in areas that matter to you.",
          tips: [
            "Identify specific areas for improvement",
            "Set realistic goals and track progress",
            "Seek feedback from trusted friends",
            "Practice self-reflection regularly",
            "Celebrate small wins along the way"
          ],
          challenges: "Change takes time and consistent effort.",
          benefits: "Personal growth, increased confidence, and better life satisfaction."
        };
    }
  };

  return (
    <div className="min-h-screen relative overflow-hidden">
      {/* Background Elements */}
      <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900" />
      
      <div className="max-w-6xl mx-auto relative z-10 pt-32 pb-8 px-4">
        {/* Header */}
        <div className="text-center mb-12">
          <button
            onClick={onBack}
            className="mb-8 bg-white/10 backdrop-blur-sm border border-white/20 hover:bg-white/20 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105 inline-flex items-center space-x-2"
          >
            <ArrowLeft className="w-4 h-4" />
            <span>Back to Profile</span>
          </button>
          
          <div className="mb-8">
            <Logo size="lg" showText={true} />
          </div>
          
          <div className="inline-flex items-center space-x-2 bg-white/10 backdrop-blur-sm border border-white/20 rounded-full px-4 py-2 mb-6">
            <TrendingUp className="w-4 h-4 text-amber-400" />
            <span className="text-sm font-medium text-white/80">Growth Areas</span>
          </div>
          
          <h1 className="text-5xl md:text-6xl font-bold text-white mb-6 leading-tight">
            Your Growth
            <span className="block bg-gradient-to-r from-amber-400 to-orange-500 bg-clip-text text-transparent">
              Journey
            </span>
          </h1>
          
          <p className="text-xl text-white/70 mb-8 max-w-3xl mx-auto leading-relaxed">
            Discover personalized strategies to improve your well-being and unlock your full potential.
          </p>
        </div>

        {/* Personalized Growth Areas */}
        {growthAreas.length > 0 && (
          <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 mb-8">
            <div className="text-center mb-8">
              <h2 className="text-3xl font-bold text-white mb-4">Your Specific Growth Areas</h2>
              <p className="text-white/70">Based on your personality profile, here are areas where you can grow</p>
            </div>
            
            <div className="space-y-8">
              {growthAreas.map((trait) => {
                const advice = getGrowthAdvice(trait.name);
                
                return (
                  <div key={trait.name} className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6">
                    <div className="flex items-center space-x-4 mb-4">
                      <div className={`w-12 h-12 bg-gradient-to-r ${trait.color} rounded-lg flex items-center justify-center`}>
                        <TrendingUp className="w-6 h-6 text-white" />
                      </div>
                      <div>
                        <h3 className="text-xl font-semibold text-white">{trait.name}</h3>
                        <p className="text-white/70">Score: {trait.score}/25 ({trait.level} Level)</p>
                      </div>
                    </div>
                    
                    <div className="grid md:grid-cols-2 gap-6">
                      <div>
                        <h4 className="text-lg font-semibold text-amber-400 mb-3">{advice.title}</h4>
                        <p className="text-white/70 mb-4">{advice.description}</p>
                        
                        <div className="space-y-3">
                          <h5 className="text-white font-semibold">Action Steps:</h5>
                          <ul className="space-y-2">
                            {advice.tips.map((tip, index) => (
                              <li key={index} className="flex items-start space-x-3">
                                <CheckCircle className="w-4 h-4 text-green-400 mt-0.5 flex-shrink-0" />
                                <span className="text-white/80 text-sm">{tip}</span>
                              </li>
                            ))}
                          </ul>
                        </div>
                      </div>
                      
                      <div>
                        <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-4">
                          <h5 className="text-white font-semibold mb-3">Understanding Your Challenge:</h5>
                          <p className="text-white/70 text-sm mb-4">{advice.challenges}</p>
                          
                          <h5 className="text-white font-semibold mb-3">Benefits of Growth:</h5>
                          <p className="text-white/70 text-sm">{advice.benefits}</p>
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* Universal Growth Areas */}
        <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 mb-8">
          <div className="text-center mb-8">
            <h2 className="text-3xl font-bold text-white mb-4">Universal Growth Areas</h2>
            <p className="text-white/70">Everyone can benefit from improving these fundamental aspects of well-being</p>
          </div>
          
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {universalGrowthAreas.map((area) => {
              const IconComponent = area.icon;
              
              return (
                <div key={area.name} className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6 hover:bg-white/10 transition-all duration-300">
                  <div className="flex items-center space-x-3 mb-4">
                    <div className={`w-12 h-12 bg-gradient-to-r ${area.color} rounded-lg flex items-center justify-center`}>
                      <IconComponent className="w-6 h-6 text-white" />
                    </div>
                    <h3 className="font-semibold text-white">{area.name}</h3>
                  </div>
                  
                  <p className="text-white/70 text-sm mb-4">{area.description}</p>
                  
                  <div className="space-y-3">
                    <h4 className="text-white font-semibold text-sm">Quick Tips:</h4>
                    <ul className="space-y-2">
                      {area.tips.slice(0, 3).map((tip, index) => (
                        <li key={index} className="text-white/60 text-xs flex items-start space-x-2">
                          <CheckCircle className="w-3 h-3 text-green-400 mt-0.5 flex-shrink-0" />
                          <span>{tip}</span>
                        </li>
                      ))}
                    </ul>
                    
                    <div className="pt-3 border-t border-white/10">
                      <h4 className="text-white font-semibold text-sm mb-2">Benefits:</h4>
                      <ul className="space-y-1">
                        {area.benefits.slice(0, 2).map((benefit, index) => (
                          <li key={index} className="text-white/60 text-xs">• {benefit}</li>
                        ))}
                      </ul>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Detailed Universal Advice */}
        <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 mb-8">
          <div className="text-center mb-8">
            <h2 className="text-3xl font-bold text-white mb-4">Building Better Habits</h2>
            <p className="text-white/70">Practical strategies for creating lasting positive changes</p>
          </div>
          
          <div className="grid md:grid-cols-2 gap-8">
            <div>
              <h3 className="text-xl font-semibold text-amber-400 mb-4">The Science of Habit Formation</h3>
              <div className="space-y-4">
                <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-4">
                  <h4 className="text-white font-semibold mb-2">Start Small</h4>
                  <p className="text-white/70 text-sm">Begin with tiny changes that are easy to maintain. A 1% improvement daily leads to massive results over time.</p>
                </div>
                
                <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-4">
                  <h4 className="text-white font-semibold mb-2">Stack Habits</h4>
                  <p className="text-white/70 text-sm">Link new habits to existing routines. For example, meditate right after brushing your teeth.</p>
                </div>
                
                <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-4">
                  <h4 className="text-white font-semibold mb-2">Track Progress</h4>
                  <p className="text-white/70 text-sm">Use a habit tracker or journal to monitor your consistency and celebrate small wins.</p>
                </div>
              </div>
            </div>
            
            <div>
              <h3 className="text-xl font-semibold text-amber-400 mb-4">Creating Your Action Plan</h3>
              <div className="space-y-4">
                <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-4">
                  <h4 className="text-white font-semibold mb-2">Set SMART Goals</h4>
                  <p className="text-white/70 text-sm">Specific, Measurable, Achievable, Relevant, and Time-bound goals increase your chances of success.</p>
                </div>
                
                <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-4">
                  <h4 className="text-white font-semibold mb-2">Build Support Systems</h4>
                  <p className="text-white/70 text-sm">Share your goals with friends, join communities, or find accountability partners.</p>
                </div>
                
                <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-4">
                  <h4 className="text-white font-semibold mb-2">Practice Self-Compassion</h4>
                  <p className="text-white/70 text-sm">Be kind to yourself when you slip up. Progress isn't linear, and setbacks are part of growth.</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Call to Action */}
        <div className="bg-gradient-to-r from-amber-500/20 to-orange-600/20 backdrop-blur-xl border border-amber-500/30 rounded-2xl p-8 text-center">
          <div className="mb-6">
            <TrendingUp className="w-12 h-12 text-amber-400 mx-auto mb-4" />
            <h2 className="text-3xl font-bold text-white mb-4">Ready to Start Your Growth Journey?</h2>
            <p className="text-white/80 mb-8 max-w-2xl mx-auto">
              Remember, personal growth is a lifelong journey. Start with one small change today and build momentum over time.
            </p>
          </div>
          
          <button
            onClick={onBack}
            className="bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-300 transform hover:scale-105 hover:shadow-2xl inline-flex items-center space-x-2"
          >
            <CheckCircle className="w-5 h-5" />
            <span>Start Growing Today</span>
          </button>
        </div>
      </div>
    </div>
  );
};

export default GrowthAreasDetailPage; 