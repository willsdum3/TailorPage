import React from 'react';
import { BookOpen, Sparkles } from 'lucide-react';

interface LogoProps {
  size?: 'sm' | 'md' | 'lg';
  showText?: boolean;
  className?: string;
}

const Logo: React.FC<LogoProps> = ({ size = 'md', showText = true, className = '' }) => {
  const sizeClasses = {
    sm: 'w-8 h-8',
    md: 'w-12 h-12',
    lg: 'w-16 h-16'
  };

  const textSizeClasses = {
    sm: 'text-lg',
    md: 'text-xl',
    lg: 'text-2xl'
  };

  const iconSizeClasses = {
    sm: 'w-4 h-4',
    md: 'w-6 h-6',
    lg: 'w-8 h-8'
  };

  return (
    <div className={`flex items-center space-x-3 ${className}`}>
      <div className={`${sizeClasses[size]} bg-gradient-to-r from-amber-500 to-orange-600 rounded-xl flex items-center justify-center relative overflow-hidden group`}>
        <BookOpen className={`${iconSizeClasses[size]} text-white z-10`} />
        <Sparkles className="w-3 h-3 text-white/60 absolute top-1 right-1 animate-pulse" />
      </div>
      {showText && (
        <div>
          <h1 className={`${textSizeClasses[size]} font-bold text-white leading-tight`}>
            Tailor Page
          </h1>
          {size === 'lg' && (
            <p className="text-sm text-white/70">Personalised Book Recommendations</p>
          )}
        </div>
      )}
    </div>
  );
};

export default Logo;