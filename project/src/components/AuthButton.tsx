import React from 'react';
import { LogIn, User } from 'lucide-react';
import { User as UserType } from '../types';

interface AuthButtonProps {
  user: UserType | null;
  onLogin: () => void;
  position?: 'top-left' | 'top-center' | 'top-right';
}

const AuthButton: React.FC<AuthButtonProps> = ({ user, onLogin, position = 'top-left' }) => {
  const getPositionClasses = () => {
    switch (position) {
      case 'top-center':
        return 'fixed top-6 left-1/2 transform -translate-x-1/2 z-40';
      case 'top-right':
        return 'fixed top-6 right-20 z-40'; // Right of burger menu
      case 'top-left':
      default:
        return 'fixed top-6 left-6 z-40';
    }
  };

  if (user) {
    return (
      <div className={`${getPositionClasses()}`}>
        <div className="bg-white/10 backdrop-blur-md border border-white/20 rounded-xl px-4 py-2 flex items-center space-x-2">
          {user.imageUrl ? (
            <img 
              src={user.imageUrl} 
              alt="Profile" 
              className="w-8 h-8 rounded-lg object-cover"
            />
          ) : (
            <div className="w-8 h-8 bg-gradient-to-r from-amber-500 to-orange-600 rounded-lg flex items-center justify-center">
              <User className="w-4 h-4 text-white" />
            </div>
          )}
          <span className="text-white font-medium">{user.name || user.username}</span>
        </div>
      </div>
    );
  }

  return (
    <button
      onClick={onLogin}
      className={getPositionClasses()}
    >
      <div className="bg-white/10 backdrop-blur-md border border-white/20 hover:bg-white/20 text-white px-6 py-3 rounded-xl font-medium transition-all duration-300 transform hover:scale-105 inline-flex items-center space-x-2">
        <LogIn className="w-5 h-5" />
        <span>Log In</span>
      </div>
    </button>
  );
};

export default AuthButton;