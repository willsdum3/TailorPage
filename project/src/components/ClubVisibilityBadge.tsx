import React from 'react';
import { Lock, Unlock } from 'lucide-react';

interface ClubVisibilityBadgeProps {
  isPrivate: boolean;
  className?: string;
}

const ClubVisibilityBadge: React.FC<ClubVisibilityBadgeProps> = ({ isPrivate, className = '' }) => {
  if (isPrivate) {
    return (
      <span className={`inline-flex items-center space-x-1 px-2 py-1 rounded-full text-xs font-medium bg-red-500/20 text-red-300 border border-red-500/30 ${className}`}>
        <Lock className="w-3 h-3" />
        <span>Private</span>
      </span>
    );
  }

  return (
    <span className={`inline-flex items-center space-x-1 px-2 py-1 rounded-full text-xs font-medium bg-green-500/20 text-green-300 border border-green-500/30 ${className}`}>
      <Unlock className="w-3 h-3" />
      <span>Public</span>
    </span>
  );
};

export default ClubVisibilityBadge;
