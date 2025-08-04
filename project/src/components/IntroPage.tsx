import React from 'react';
import Logo from './Logo';

interface IntroPageProps {
  onLogin: () => void;
  onSignup: () => void;
}

const IntroPage: React.FC<IntroPageProps> = ({ onLogin, onSignup }) => {
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900">
      <div className="flex h-screen">
        {/* Left Section - Logo */}
        <div className="flex-1 flex items-center justify-center relative">
          {/* Background Elements */}
          <div className="absolute top-20 left-20 w-72 h-72 bg-purple-500/10 rounded-full blur-3xl" />
          <div className="absolute bottom-20 right-20 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl" />
          <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-amber-500/5 rounded-full blur-3xl" />
          
                     <div className="text-center relative z-10">
             <Logo size="xl" showText={false} />
             <p className="mt-6 text-white/80 text-lg font-medium">
               AI-Powered Book Recommendations
             </p>
           </div>
        </div>

        {/* Right Section - Authentication */}
        <div className="flex-1 flex items-center justify-center bg-white/10 backdrop-blur-xl border-l border-white/20 px-8">
          <div className="w-full max-w-md">
            {/* Header */}
            <div className="mb-8">
              <h1 className="text-3xl font-bold text-white mb-2">
                Discover Your Perfect Books
              </h1>
              <p className="text-white/70">
                Join today and get personalized recommendations
              </p>
            </div>

            {/* Sign Up Button */}
            <button
              onClick={onSignup}
              className="w-full bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 text-white font-semibold py-3 px-4 rounded-lg transition-all duration-300 transform hover:scale-105 hover:shadow-lg mb-4"
            >
              Create account
            </button>

            {/* Terms */}
            <p className="text-xs text-white/60 mb-6">
              By signing up, you agree to the{' '}
              <a href="#" className="text-amber-400 hover:text-amber-300 hover:underline">Terms of Service</a>
              {' '}and{' '}
              <a href="#" className="text-amber-400 hover:text-amber-300 hover:underline">Privacy Policy</a>
            </p>

            {/* Divider */}
            <div className="relative mb-6">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-white/20"></div>
              </div>
              <div className="relative flex justify-center text-sm">
                <span className="px-2 bg-transparent text-white/60">Already have an account?</span>
              </div>
            </div>

            {/* Sign In Button */}
            <button
              onClick={onLogin}
              className="w-full bg-white/10 hover:bg-white/20 backdrop-blur-sm border border-white/20 text-white font-semibold py-3 px-4 rounded-lg transition-all duration-300 transform hover:scale-105"
            >
              Sign in
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default IntroPage; 