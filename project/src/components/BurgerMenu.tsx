import React, { useState } from 'react';
import { Menu, X, User, Heart, TrendingUp, Users, Star, MessageCircle } from 'lucide-react';
import { User as UserType } from '../types';
import Logo from './Logo';

interface BurgerMenuProps {
  onNavigate: (page: string) => void;
  user: UserType | null;
  onLoginRequired: () => void;
}

const BurgerMenu: React.FC<BurgerMenuProps> = ({ onNavigate, user, onLoginRequired }) => {
  const [isOpen, setIsOpen] = useState(false);

  const toggleMenu = () => {
    setIsOpen(!isOpen);
  };

  const handleNavigation = (page: string) => {
    console.log('Navigation requested to:', page); // Debug log
    // Check if user needs to be logged in for certain pages
    if ((page === 'profile' || page === 'favourites') && !user) {
      setIsOpen(false);
      onLoginRequired();
      return;
    }
    
    onNavigate(page);
    setIsOpen(false);
  };

  const menuItems = [
    { id: 'profile', label: 'Profile', icon: User, requiresAuth: true },
    { id: 'favourites', label: 'Favourites', icon: Heart, requiresAuth: true },
    { id: 'trending-books', label: 'Trending Books', icon: TrendingUp, requiresAuth: false },
    { id: 'trending-authors', label: 'Trending Authors', icon: Users, requiresAuth: false },
    { id: 'celebrity-books', label: 'Celebrity Tester', icon: Star, requiresAuth: false },
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
        <div className="p-6 pt-20">
          <div className="mb-8 pb-6 border-b border-white/10">
            <button 
              onClick={() => handleNavigation('home')}
              className="w-full text-left hover:opacity-80 transition-opacity duration-300"
            >
              <Logo size="md" showText={true} />
            </button>
          </div>
          
          <div className="mb-8">
            <h2 className="text-2xl font-bold text-white mb-2">Navigation</h2>
            <p className="text-white/70">Explore more features</p>
          </div>

          <nav className="space-y-2">
            {menuItems.map((item) => {
              const IconComponent = item.icon;
              const isDisabled = item.requiresAuth && !user;
              
              return (
                <button
                  key={item.id}
                  onClick={() => handleNavigation(item.id)}
                  className={`w-full flex items-center space-x-3 px-4 py-3 text-left rounded-xl transition-all duration-300 group ${
                    isDisabled 
                      ? 'text-white/30 cursor-not-allowed' 
                      : 'text-white hover:bg-white/10 transform hover:scale-105'
                  }`}
                >
                  <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${
                    isDisabled 
                      ? 'bg-white/10' 
                      : 'bg-gradient-to-r from-amber-500 to-orange-600 group-hover:from-amber-600 group-hover:to-orange-700'
                  }`}>
                    <IconComponent className="w-5 h-5 text-white" />
                  </div>
                  <div className="flex-1">
                    <span className="font-medium">{item.label}</span>
                    {isDisabled && (
                      <div className="text-xs text-white/40 mt-1">Log in required</div>
                    )}
                  </div>
                </button>
              );
            })}
          </nav>

        </div>
      </div>
    </>
  );
};

export default BurgerMenu;