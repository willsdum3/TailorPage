import React, { useState } from 'react';
import { X, User, Mail, Lock, UserPlus, LogIn, Chrome } from 'lucide-react';
import { LoginCredentials, SignupData, User as UserType } from '../types';

interface AuthModalProps {
  isOpen: boolean;
  onClose: () => void;
  onLogin: (credentials: LoginCredentials) => void;
  onSignup: (data: SignupData) => void;
}

const AuthModal: React.FC<AuthModalProps> = ({ isOpen, onClose, onLogin, onSignup }) => {
  const [isLoginMode, setIsLoginMode] = useState(true);
  const [formData, setFormData] = useState({
    name: '',
    username: '',
    email: '',
    password: ''
  });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isLoading, setIsLoading] = useState(false);

  const handleSSOSignup = async (provider: string) => {
    setIsLoading(true);
    
    try {
      // Simulate SSO authentication
      await new Promise(resolve => setTimeout(resolve, 1500));
      
      // Mock successful SSO signup
      const mockUser: SignupData = {
        name: `${provider} User`,
        username: `${provider.toLowerCase()}user${Date.now()}`,
        email: `user@${provider.toLowerCase()}.com`,
        password: 'sso-generated'
      };
      
      await onSignup(mockUser);
    } catch (error) {
      setErrors({ general: `${provider} authentication failed. Please try again.` });
    } finally {
      setIsLoading(false);
    }
  };

  const handleSSOLogin = async (provider: string) => {
    setIsLoading(true);
    
    try {
      // Simulate SSO authentication
      await new Promise(resolve => setTimeout(resolve, 1500));
      
      // Mock successful SSO login
      const mockCredentials: LoginCredentials = {
        username: `${provider.toLowerCase()}user`,
        password: 'sso-generated'
      };
      
      await onLogin(mockCredentials);
    } catch (error) {
      setErrors({ general: `${provider} authentication failed. Please try again.` });
    } finally {
      setIsLoading(false);
    }
  };

  if (!isOpen) return null;

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    // Clear error when user starts typing
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: '' }));
    }
  };

  const validateForm = () => {
    const newErrors: Record<string, string> = {};

    if (!formData.username.trim()) {
      newErrors.username = 'Username is required';
    }

    if (!formData.password.trim()) {
      newErrors.password = 'Password is required';
    } else if (formData.password.length < 6) {
      newErrors.password = 'Password must be at least 6 characters';
    }

    if (!isLoginMode) {
      if (!formData.name.trim()) {
        newErrors.name = 'Name is required';
      }

      if (!formData.email.trim()) {
        newErrors.email = 'Email is required';
      } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
        newErrors.email = 'Please enter a valid email address';
      }
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) return;

    setIsLoading(true);

    try {
      if (isLoginMode) {
        await onLogin({
          username: formData.username,
          password: formData.password
        });
      } else {
        await onSignup({
          name: formData.name,
          username: formData.username,
          email: formData.email,
          password: formData.password
        });
      }
      
      // Reset form and close modal on success
      setFormData({ name: '', username: '', email: '', password: '' });
      setErrors({});
      onClose();
    } catch (error) {
      setErrors({ general: 'Authentication failed. Please try again.' });
    } finally {
      setIsLoading(false);
    }
  };

  const toggleMode = () => {
    setIsLoginMode(!isLoginMode);
    setFormData({ name: '', username: '', email: '', password: '' });
    setErrors({});
  };

  return (
    <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4 overflow-y-auto">
      <div className="bg-slate-900/95 backdrop-blur-xl border border-white/20 rounded-2xl w-full max-w-md shadow-2xl my-8 max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between p-6 border-b border-white/10">
          <h2 className="text-2xl font-bold text-white">
            {isLoginMode ? 'Welcome Back' : 'Create Account'}
          </h2>
          <button
            onClick={onClose}
            className="text-white/60 hover:text-white transition-colors duration-200 p-1 hover:bg-white/10 rounded-lg"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          {errors.general && (
            <div className="bg-red-500/10 border border-red-500/20 rounded-xl p-3">
              <p className="text-red-400 text-sm">{errors.general}</p>
            </div>
          )}

          {!isLoginMode && (
            <div>
              <label htmlFor="name" className="block text-sm font-medium text-white/90 mb-2">
                Full Name
              </label>
              <div className="relative">
                <User className="absolute left-4 top-1/2 transform -translate-y-1/2 w-5 h-5 text-white/40" />
                <input
                  type="text"
                  id="name"
                  name="name"
                  value={formData.name}
                  onChange={handleInputChange}
                  className="w-full pl-12 pr-4 py-2.5 bg-white/5 border border-white/20 rounded-xl text-white placeholder-white/40 focus:outline-none focus:ring-2 focus:ring-amber-500/50 focus:border-amber-500/50 transition-all duration-200"
                  placeholder="Enter your full name"
                />
              </div>
              {errors.name && <p className="text-red-400 text-sm mt-2">{errors.name}</p>}
            </div>
          )}

          <div>
            <label htmlFor="username" className="block text-sm font-medium text-white/90 mb-2">
              Username
            </label>
            <div className="relative">
              <User className="absolute left-4 top-1/2 transform -translate-y-1/2 w-5 h-5 text-white/40" />
              <input
                type="text"
                id="username"
                name="username"
                value={formData.username}
                onChange={handleInputChange}
                className="w-full pl-12 pr-4 py-2.5 bg-white/5 border border-white/20 rounded-xl text-white placeholder-white/40 focus:outline-none focus:ring-2 focus:ring-amber-500/50 focus:border-amber-500/50 transition-all duration-200"
                placeholder="Enter your username"
              />
            </div>
            {errors.username && <p className="text-red-400 text-sm mt-2">{errors.username}</p>}
          </div>

          {!isLoginMode && (
            <div>
              <label htmlFor="email" className="block text-sm font-medium text-white/90 mb-2">
                Email Address
              </label>
              <div className="relative">
                <Mail className="absolute left-4 top-1/2 transform -translate-y-1/2 w-5 h-5 text-white/40" />
                <input
                  type="email"
                  id="email"
                  name="email"
                  value={formData.email}
                  onChange={handleInputChange}
                  className="w-full pl-12 pr-4 py-2.5 bg-white/5 border border-white/20 rounded-xl text-white placeholder-white/40 focus:outline-none focus:ring-2 focus:ring-amber-500/50 focus:border-amber-500/50 transition-all duration-200"
                  placeholder="Enter your email address"
                />
              </div>
              {errors.email && <p className="text-red-400 text-sm mt-2">{errors.email}</p>}
            </div>
          )}

          <div>
            <label htmlFor="password" className="block text-sm font-medium text-white/90 mb-2">
              Password
            </label>
            <div className="relative">
              <Lock className="absolute left-4 top-1/2 transform -translate-y-1/2 w-5 h-5 text-white/40" />
              <input
                type="password"
                id="password"
                name="password"
                value={formData.password}
                onChange={handleInputChange}
                className="w-full pl-12 pr-4 py-2.5 bg-white/5 border border-white/20 rounded-xl text-white placeholder-white/40 focus:outline-none focus:ring-2 focus:ring-amber-500/50 focus:border-amber-500/50 transition-all duration-200"
                placeholder="Enter your password"
              />
            </div>
            {errors.password && <p className="text-red-400 text-sm mt-2">{errors.password}</p>}
          </div>

          <button
            type="submit"
            disabled={isLoading}
            className="w-full bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 disabled:from-amber-500/50 disabled:to-orange-600/50 text-white py-2.5 rounded-xl font-semibold transition-all duration-300 transform hover:scale-105 disabled:transform-none disabled:cursor-not-allowed flex items-center justify-center space-x-2"
          >
            {isLoading ? (
              <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
            ) : (
              <>
                {isLoginMode ? <LogIn className="w-5 h-5" /> : <UserPlus className="w-5 h-5" />}
                <span>{isLoginMode ? 'Log In' : 'Create Account'}</span>
              </>
            )}
          </button>

          <div className="relative">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-white/10" />
            </div>
            <div className="relative flex justify-center text-sm">
              <span className="px-2 bg-slate-900/95 text-white/60">
                Or
              </span>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-2">
            <button
              type="button"
              onClick={() => isLoginMode ? handleSSOLogin('Google') : handleSSOSignup('Google')}
              disabled={isLoading}
              className="flex items-center justify-center px-3 py-2.5 border border-white/20 rounded-xl text-white hover:bg-white/5 transition-all duration-300 transform hover:scale-105 disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none"
            >
              <svg className="w-5 h-5 mr-2" viewBox="0 0 24 24">
                <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
              </svg>
              <span className="text-xs font-medium">Continue with Google</span>
            </button>

            <button
              type="button"
              onClick={() => isLoginMode ? handleSSOLogin('Apple') : handleSSOSignup('Apple')}
              disabled={isLoading}
              className="flex items-center justify-center px-3 py-2.5 border border-white/20 rounded-xl text-white hover:bg-white/5 transition-all duration-300 transform hover:scale-105 disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none"
            >
              <svg className="w-5 h-5 mr-2" viewBox="0 0 24 24" fill="currentColor">
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
              </svg>
              <span className="text-xs font-medium">Continue with Apple</span>
            </button>

            <button
              type="button"
              onClick={() => isLoginMode ? handleSSOLogin('Facebook') : handleSSOSignup('Facebook')}
              disabled={isLoading}
              className="flex items-center justify-center px-3 py-2.5 border border-white/20 rounded-xl text-white hover:bg-white/5 transition-all duration-300 transform hover:scale-105 disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none"
            >
              <svg className="w-5 h-5 mr-2" viewBox="0 0 24 24" fill="#1877F2">
                <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
              </svg>
              <span className="text-xs font-medium">Continue with Facebook</span>
            </button>

            <button
              type="button"
              onClick={() => isLoginMode ? handleSSOLogin('Microsoft') : handleSSOSignup('Microsoft')}
              disabled={isLoading}
              className="flex items-center justify-center px-3 py-2.5 border border-white/20 rounded-xl text-white hover:bg-white/5 transition-all duration-300 transform hover:scale-105 disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none"
            >
              <svg className="w-5 h-5 mr-2" viewBox="0 0 24 24">
                <path fill="#F25022" d="M1 1h10v10H1z"/>
                <path fill="#00A4EF" d="M13 1h10v10H13z"/>
                <path fill="#7FBA00" d="M1 13h10v10H1z"/>
                <path fill="#FFB900" d="M13 13h10v10H13z"/>
              </svg>
              <span className="text-xs font-medium">Continue with Microsoft</span>
            </button>
          </div>

          <div className="text-center pt-3 border-t border-white/10">
            <p className="text-white/70">
              {isLoginMode ? "Don't have an account?" : "Already have an account?"}
              <button
                type="button"
                onClick={toggleMode}
                className="ml-2 text-amber-400 hover:text-amber-300 font-medium transition-colors duration-200"
              >
                {isLoginMode ? 'Sign Up' : 'Log In'}
              </button>
            </p>
          </div>
        </form>
      </div>
    </div>
  );
};

export default AuthModal;