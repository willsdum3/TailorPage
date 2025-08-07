import React from 'react';

interface LogoProps {
  size?: 'sm' | 'md' | 'lg';
  showText?: boolean;
  className?: string;
}

const sizeClasses = {
  sm: 'w-12 h-12',
  md: 'w-20 h-20',
  lg: 'w-32 h-32'
};

const textSizeClasses = {
  sm: 'text-lg',
  md: 'text-xl',
  lg: 'text-2xl'
};

const Logo: React.FC<LogoProps> = ({ size = 'md', showText = true, className = '' }) => {
  return (
    <div className={`flex items-center space-x-3 ${className}`}>
      <img
        src={'/tailorpagelogoupdate.png'}
        alt="Tailor Page Logo"
        className={`${sizeClasses[size]} rounded-xl object-contain bg-white`}
        style={{ boxShadow: '0 2px 8px rgba(0,0,0,0.08)' }}
      />
      {showText && (
        <div>
          <h1 className={`${textSizeClasses[size]} font-bold text-white leading-tight`}>
            Tailor Page
          </h1>
          {size === 'lg' && (
            <p className="text-sm text-white/70">AI Book Recommendations</p>
          )}
        </div>
      )}
    </div>
  );
};

export default Logo;