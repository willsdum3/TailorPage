import React, { useState } from 'react';
import { Menu, X, User, Heart, MessageCircle, BookOpen, LogOut } from 'lucide-react';
import { User as UserType } from '../types';
import Logo from './Logo';

interface BurgerMenuProps {
  onNavigate: (page: string) => void;
  user: UserType | null;
  onLoginRequired: () => void;
  onAuthPrompt?: (mode: 'login' | 'signup', feature?: string) => void;
  onLogout?: () => void;
}

const BurgerMenu: React.FC<BurgerMenuProps> = ({ onNavigate, user, onLoginRequired, onAuthPrompt, onLogout }) => {
  const [isOpen, setIsOpen] = useState(false);

  const toggleMenu = () => {
    setIsOpen(!isOpen);
  };

  const handleNavigation = (page: string) => {
    console.log('Navigation requested to:', page); // Debug log
    
    // Check if user needs to be logged in for certain pages
    if (page === 'profile' && !user) {
      setIsOpen(false);
      onAuthPrompt?.('login', 'access profile');
      return;
    }
    
    if (page === 'tailor-mates' && !user) {
      setIsOpen(false);
      onAuthPrompt?.('signup', 'access Tailor Mates');
      return;
    }
    
    onNavigate(page);
    setIsOpen(false);
  };

  const menuItems = [
    { id: 'profile', label: 'Profile', icon: User, requiresAuth: true },
    { id: 'tailor-mates', label: 'Tailor Mates', icon: MessageCircle, requiresAuth: false }
  ];

  return (
    <>
      {/* Burger Menu Button */}
      <button
        onClick={toggleMenu}
        className="fixed top-6 right-6 z-50 bg-white/10 backdrop-blur-md border border-white/20 hover:bg-white/20 text-white p-3 rounded-xl transition-all duration-300 transform hover:scale-105"
        aria-label="Toggle menu"
      >
        {isOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
      </button>

      {/* Overlay */}
      {isOpen && (
        <div
          className="fixed inset-0 bg-black/50 backdrop-blur-sm z-40"
          onClick={() => setIsOpen(false)}
        />
      )}

      {/* Menu Panel */}
      <div
        className={`fixed top-0 right-0 h-full w-80 bg-slate-900/95 backdrop-blur-xl border-l border-white/20 z-40 transform transition-transform duration-300 ease-in-out ${
          isOpen ? 'translate-x-0' : 'translate-x-full'
        }`}
      >
        <div className="p-6 pt-20 h-full overflow-y-auto">
          <div className="mb-8 pb-6 border-b border-white/10">
            <button 
              onClick={() => handleNavigation('welcome')}
              className="w-full text-left hover:opacity-80 transition-opacity duration-300"
            >
              <Logo size="md" showText={true} />
            </button>
          </div>
          
          <div className="mb-8">
            <h2 className="text-2xl font-bold text-white mb-2">Navigation</h2>
            <p className="text-white/70">Explore more features</p>
          </div>

          <nav className="space-y-2 flex-1">
            {menuItems.map((item) => {
              const IconComponent = item.icon;
              const isDisabled = item.requiresAuth && !user;
              const isTailorMates = item.id === 'tailor-mates';
              const isProfile = item.id === 'profile';
              
              return (
                <button
                  key={item.id}
                  onClick={() => handleNavigation(item.id)}
                  className={`w-full flex items-center space-x-4 px-5 py-4 text-left rounded-2xl transition-all duration-300 group ${
                    isDisabled 
                      ? 'text-white/30 cursor-not-allowed' 
                      : isTailorMates
                        ? 'text-white hover:bg-gradient-to-r hover:from-pink-500/20 hover:to-purple-500/20 transform hover:scale-105 border border-pink-500/30'
                        : isProfile && user
                          ? 'text-white hover:bg-white/5 hover:border-white/20 border border-transparent transform hover:scale-102'
                          : 'text-white hover:bg-white/10 transform hover:scale-105'
                  }`}
                >
                  <div className={`flex items-center justify-center ${
                    isDisabled 
                      ? 'bg-white/10 w-10 h-10 rounded-lg' 
                      : isTailorMates
                        ? 'bg-gradient-to-r from-pink-500 to-purple-600 group-hover:from-pink-600 group-hover:to-purple-700 w-10 h-10 rounded-lg'
                        : isProfile && user
                          ? 'w-12 h-12 rounded-2xl bg-gradient-to-r from-amber-500/20 to-orange-600/20 border border-amber-500/30 group-hover:border-amber-500/50 group-hover:from-amber-500/30 group-hover:to-orange-600/30'
                          : 'bg-gradient-to-r from-amber-500 to-orange-600 group-hover:from-amber-600 group-hover:to-orange-700 w-10 h-10 rounded-lg'
                  }`}>
                    {isProfile && user?.imageUrl ? (
                      <img 
                        src={user.imageUrl} 
                        alt={user.name || user.username} 
                        className="w-10 h-10 rounded-xl object-cover border border-white/20"
                      />
                    ) : (
                      <IconComponent className="w-5 h-5 text-white" />
                    )}
                  </div>
                  <div className="flex-1">
                    <span className={`font-semibold ${
                      isProfile && user ? 'text-lg' : 'font-medium'
                    }`}>
                      {isProfile && user ? (user.name || user.username) : item.label}
                    </span>
                    {isProfile && user && (
                      <div className="text-xs text-white/60 mt-1 font-medium">Profile</div>
                    )}
                    {isTailorMates && (
                      <div className="text-xs text-pink-300 mt-1">Virtual Book Club</div>
                    )}
                    {isDisabled && (
                      <div className="text-xs text-white/40 mt-1">Log in required</div>
                    )}
                  </div>
                </button>
              );
            })}
          </nav>

          {/* Logout Button - Only show when user is logged in */}
          {user && onLogout && (
            <div className="mt-auto pt-6 border-t border-white/10">
              <button
                onClick={() => {
                  setIsOpen(false);
                  onLogout();
                }}
                className="w-full flex items-center space-x-4 px-5 py-4 text-left rounded-2xl transition-all duration-300 group text-red-400 hover:bg-red-500/20 hover:text-red-300 transform hover:scale-105"
              >
                <div className="flex items-center justify-center bg-red-500/20 group-hover:bg-red-500/30 w-10 h-10 rounded-lg">
                  <LogOut className="w-5 h-5" />
                </div>
                <div className="flex-1">
                  <span className="font-semibold">Sign Out</span>
                  <div className="text-xs text-red-300/70 mt-1">Log out of your account</div>
                </div>
              </button>
            </div>
          )}
        </div>
      </div>
    </>
  );
};

export default BurgerMenu;