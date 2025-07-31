import React, { useEffect } from 'react';
import { ArrowLeft, Star, Zap, Heart, Target, Brain, Shield, TrendingUp, Lightbulb, Award } from 'lucide-react';
import { PersonalityProfile } from '../types';
import Logo from './Logo';
import { analyzePersonality } from '../utils/personalityAnalysis';

interface StrengthsDetailPageProps {
  profile: PersonalityProfile;
  onBack: () => void;
}

const StrengthsDetailPage: React.FC<StrengthsDetailPageProps> = ({ profile, onBack }) => {
  const personalityAnalysis = analyzePersonality(profile);
  
  // Get top traits by score (only traits tied for highest scores, max 3)
  const sortedTraits = [...personalityAnalysis].sort((a, b) => b.score - a.score);
  const highestScore = sortedTraits[0]?.score || 0;
  const strengths = sortedTraits
    .filter(trait => trait.score === highestScore)
    .slice(0, 3); // Limit to top 3 even if more are tied

  // Scroll to top when component mounts
  useEffect(() => {
    window.scrollTo(0, 0);
  }, []);

  const getStrengthIcon = (traitName: string) => {
    switch (traitName) {
      case 'Openness to Experience':
        return Brain;
      case 'Conscientiousness':
        return Target;
      case 'Extraversion':
        return Zap;
      case 'Agreeableness':
        return Heart;
      case 'Emotional Stability':
        return Shield;
      default:
        return Star;
    }
  };

  const getStrengthAdvice = (traitName: string) => {
    switch (traitName) {
      case 'Openness to Experience':
        return {
          title: "Embrace Your Curiosity",
          description: "Your natural curiosity and openness make you a great learner and innovator.",
          tips: [
            "Explore new hobbies and interests regularly",
            "Read diverse genres and perspectives",
            "Travel to new places when possible",
            "Engage in creative activities",
            "Learn new skills and languages"
          ],
          careerAdvice: "Consider roles in research, creative fields, or international work where your adaptability shines."
        };
      case 'Conscientiousness':
        return {
          title: "Leverage Your Discipline",
          description: "Your strong organizational skills and reliability are highly valued in any setting.",
          tips: [
            "Set clear, achievable goals",
            "Create structured routines",
            "Use productivity tools and systems",
            "Take on leadership roles",
            "Mentor others in organization"
          ],
          careerAdvice: "Excel in management, project coordination, or any role requiring attention to detail."
        };
      case 'Extraversion':
        return {
          title: "Harness Your Social Energy",
          description: "Your natural ability to connect with others is a powerful strength.",
          tips: [
            "Network actively in your field",
            "Join clubs and social groups",
            "Take on public speaking opportunities",
            "Mentor and support others",
            "Lead team activities and events"
          ],
          careerAdvice: "Thrive in sales, teaching, public relations, or any people-focused role."
        };
      case 'Agreeableness':
        return {
          title: "Use Your Empathy",
          description: "Your compassion and ability to understand others make you a natural mediator.",
          tips: [
            "Volunteer for community service",
            "Practice active listening",
            "Resolve conflicts diplomatically",
            "Support and encourage others",
            "Build strong, lasting relationships"
          ],
          careerAdvice: "Excel in counseling, healthcare, human resources, or any helping profession."
        };
      case 'Emotional Stability':
        return {
          title: "Maintain Your Calm",
          description: "Your emotional resilience is a rare and valuable trait in today's world.",
          tips: [
            "Practice stress management techniques",
            "Maintain healthy work-life balance",
            "Support others during difficult times",
            "Stay composed under pressure",
            "Model emotional intelligence"
          ],
          careerAdvice: "Excel in high-pressure environments, crisis management, or leadership roles."
        };
      default:
        return {
          title: "Your Unique Strength",
          description: "This trait gives you a special advantage in many areas of life.",
          tips: [
            "Identify how this strength helps you daily",
            "Find ways to develop it further",
            "Share your expertise with others",
            "Use it to overcome challenges",
            "Celebrate this part of yourself"
          ],
          careerAdvice: "Look for opportunities that align with this natural strength."
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
            <Award className="w-4 h-4 text-amber-400" />
            <span className="text-sm font-medium text-white/80">Your Strengths</span>
          </div>
          
                     <h1 className="text-6xl md:text-7xl font-bold text-white mb-8 leading-tight">
             Your Unique
             <span className="block bg-gradient-to-r from-amber-400 to-orange-500 bg-clip-text text-transparent">
               Strengths
             </span>
           </h1>
          
          <p className="text-xl text-white/70 mb-8 max-w-3xl mx-auto leading-relaxed">
            Discover what makes you special and how to leverage your natural talents for personal and professional success.
          </p>
        </div>

        {/* Strengths Overview */}
        <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 mb-8">
          <div className="text-center mb-8">
            <h2 className="text-3xl font-bold text-white mb-4">
              Your Top {strengths.length === 1 ? 'Strength' : 'Strengths'}
            </h2>
            <p className="text-white/70">These are the traits that set you apart and drive your success</p>
          </div>
          
          <div className={`grid gap-6 ${strengths.length === 1 ? 'md:grid-cols-1 md:justify-items-center' : strengths.length === 2 ? 'md:grid-cols-2 md:col-span-2 md:mx-auto md:max-w-4xl' : 'md:grid-cols-2 lg:grid-cols-3'}`}>
            {strengths.map((trait) => {
              const IconComponent = getStrengthIcon(trait.name);
              const advice = getStrengthAdvice(trait.name);
              
              return (
                <div key={trait.name} className={`bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6 hover:bg-white/10 transition-all duration-300 ${strengths.length === 1 ? 'md:max-w-md' : ''}`}>
                  <div className="flex items-center space-x-3 mb-4">
                    <div className={`w-12 h-12 bg-gradient-to-r ${trait.color} rounded-lg flex items-center justify-center`}>
                      <IconComponent className="w-6 h-6 text-white" />
                    </div>
                    <div>
                      <h3 className="font-semibold text-white">{trait.name}</h3>
                      <div className="flex items-center space-x-2">
                        <div className="flex-1 bg-white/20 rounded-full h-2 w-16">
                          <div 
                            className={`bg-gradient-to-r ${trait.color} h-2 rounded-full`}
                            style={{ width: `${trait.percentage}%` }}
                          />
                        </div>
                        <span className="text-white/80 text-sm font-medium">{trait.score}/25</span>
                      </div>
                    </div>
                  </div>
                  
                  <h4 className="text-lg font-semibold text-amber-400 mb-2">{advice.title}</h4>
                  <p className="text-white/70 text-sm mb-4">{advice.description}</p>
                  
                  <div className="space-y-2">
                    <h5 className="text-white font-medium text-sm">Quick Tips:</h5>
                    <ul className="space-y-1">
                      {advice.tips.slice(0, 3).map((tip, index) => (
                        <li key={index} className="text-white/60 text-xs flex items-start space-x-2">
                          <Star className="w-3 h-3 text-amber-400 mt-0.5 flex-shrink-0" />
                          <span>{tip}</span>
                        </li>
                      ))}
                    </ul>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Detailed Advice Sections */}
        <div className="space-y-8">
          {strengths.map((trait) => {
            const IconComponent = getStrengthIcon(trait.name);
            const advice = getStrengthAdvice(trait.name);
            
            return (
              <div key={trait.name} className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8">
                <div className="flex items-center space-x-4 mb-6">
                  <div className={`w-16 h-16 bg-gradient-to-r ${trait.color} rounded-xl flex items-center justify-center`}>
                    <IconComponent className="w-8 h-8 text-white" />
                  </div>
                  <div>
                    <h2 className="text-3xl font-bold text-white">{trait.name}</h2>
                    <p className="text-white/70">Score: {trait.score}/25 ({trait.level} Level)</p>
                  </div>
                </div>
                
                <div className="grid md:grid-cols-2 gap-8">
                  <div>
                    <h3 className="text-xl font-semibold text-amber-400 mb-4">How to Leverage This Strength</h3>
                    <p className="text-white/70 mb-6">{advice.description}</p>
                    
                    <div className="space-y-4">
                      <h4 className="text-white font-semibold">Actionable Tips:</h4>
                      <ul className="space-y-3">
                        {advice.tips.map((tip, index) => (
                          <li key={index} className="flex items-start space-x-3">
                            <div className="w-2 h-2 bg-amber-400 rounded-full mt-2 flex-shrink-0"></div>
                            <span className="text-white/80">{tip}</span>
                          </li>
                        ))}
                      </ul>
                    </div>
                  </div>
                  
                  <div>
                    <h3 className="text-xl font-semibold text-amber-400 mb-4">Career & Life Applications</h3>
                    <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6">
                      <h4 className="text-white font-semibold mb-3">Professional Advice:</h4>
                      <p className="text-white/70 mb-4">{advice.careerAdvice}</p>
                      
                      <h4 className="text-white font-semibold mb-3">Personal Development:</h4>
                      <ul className="space-y-2">
                        <li className="text-white/70 text-sm">• Use this strength to build confidence</li>
                        <li className="text-white/70 text-sm">• Help others develop similar qualities</li>
                        <li className="text-white/70 text-sm">• Balance it with other areas of growth</li>
                        <li className="text-white/70 text-sm">• Celebrate your unique perspective</li>
                      </ul>
                    </div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        {/* Call to Action */}
        <div className="bg-gradient-to-r from-amber-500/20 to-orange-600/20 backdrop-blur-xl border border-amber-500/30 rounded-2xl p-8 text-center mt-12">
          <div className="mb-6">
            <Lightbulb className="w-12 h-12 text-amber-400 mx-auto mb-4" />
            <h2 className="text-3xl font-bold text-white mb-4">Ready to Grow Further?</h2>
            <p className="text-white/80 mb-8 max-w-2xl mx-auto">
              Understanding your strengths is just the beginning. Explore your growth areas to become even more well-rounded and successful.
            </p>
          </div>
          
          <button
            onClick={onBack}
            className="bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-300 transform hover:scale-105 hover:shadow-2xl inline-flex items-center space-x-2"
          >
            <TrendingUp className="w-5 h-5" />
            <span>Explore Growth Areas</span>
          </button>
        </div>
      </div>
    </div>
  );
};

export default StrengthsDetailPage; 