import React, { useState, useEffect } from 'react';
import { Eye, EyeOff, Check, X, Lock } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { ForgotPasswordModal } from './ForgotPasswordModal';
import { useAuth } from '../contexts/AuthContext';

type AppPage = 'welcome' | 'quiz' | 'results' | 'generated' | 'celebrity-books' | 'trending-books' | 'trending-authors' | 'tailor-mates' | 'favourites' | 'learn-more' | 'profile' | 'book-cover-test' | 'reset-password';

interface ResetPasswordPageProps {
  onNavigate?: (page: AppPage) => void;
}

export const ResetPasswordPage: React.FC<ResetPasswordPageProps> = ({ onNavigate }) => {
  const { resetPassword } = useAuth();
  
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');
  const [isValidSession, setIsValidSession] = useState(false);
  const [checkingSession, setCheckingSession] = useState(true);
  const [showForgotPasswordModal, setShowForgotPasswordModal] = useState(false);

  // Check if we have a valid reset session
  useEffect(() => {
    const checkSession = async () => {
      try {
        console.log('🔄 Checking for password reset session...');
        
        // Check URL parameters for recovery tokens
        const urlParams = new URLSearchParams(window.location.search);
        const hash = window.location.hash;
        
        console.log('🔍 URL params:', urlParams.toString());
        console.log('🔍 URL hash:', hash);
        
        // Check for recovery parameters in URL first
        const hasRecoveryToken = hash.includes('type=recovery') || 
                                urlParams.get('type') === 'recovery' ||
                                hash.includes('access_token') ||
                                urlParams.get('access_token');
        
        // Also check if we're on the reset-password page (might be a direct link)
        const isOnResetPage = window.location.pathname.includes('reset-password');
        
        if (hasRecoveryToken || isOnResetPage) {
          console.log('✅ Recovery token found in URL');
          
          // First check if there are explicit error parameters in the URL
          if (hash.includes('error=')) {
            const errorParams = new URLSearchParams(hash.substring(1));
            const errorCode = errorParams.get('error_code');
            const errorDescription = errorParams.get('error_description');
            
            console.log('❌ Error found in URL:', { errorCode, errorDescription });
            
            if (errorCode === 'otp_expired') {
              setError('This password reset link has expired. Please request a new password reset.');
            } else if (errorCode === 'access_denied') {
              setError('This password reset link is invalid or has expired. Please request a new password reset.');
            } else {
              setError('This password reset link is invalid or has expired. Please request a new password reset.');
            }
            setCheckingSession(false);
            return;
          }
          
          // If no explicit error in URL, try to get the session - this will process the recovery token
          const { data: { session }, error } = await supabase.auth.getSession();
          
          if (error) {
            console.error('❌ Error processing recovery token:', error);
            
            // Check if it's a specific error we can handle
            if (error.message?.includes('expired') || error.message?.includes('invalid')) {
              setError('This password reset link has expired. Please request a new password reset.');
            } else {
              setError('Invalid or expired reset link. Please request a new password reset.');
            }
            setCheckingSession(false);
            return;
          }

          if (session && session.user) {
            console.log('✅ Valid recovery session found for user:', session.user.email);
            setIsValidSession(true);
            setMessage(''); // Don't set message so form shows
          } else {
            console.log('❌ No valid session found after processing recovery token');
            setError('Invalid or expired reset link. Please request a new password reset.');
          }
        } else {
          console.log('❌ No recovery token found in URL');
          console.log('🔍 Debug info:', {
            hash: window.location.hash,
            search: window.location.search,
            pathname: window.location.pathname,
            fullUrl: window.location.href
          });
          
          setError('Invalid reset link. Please use the link from your email.');
        }
      } catch (err) {
        console.error('❌ Unexpected error checking session:', err);
        setError('An error occurred. Please try again.');
      } finally {
        setCheckingSession(false);
      }
    };

    checkSession();
  }, []);

  const validatePassword = (password: string) => {
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!/(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/.test(password)) {
      return 'Password must contain at least one uppercase letter, one lowercase letter, and one number';
    }
    return null;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    setError('');
    setMessage('');

    // Validate passwords
    const passwordError = validatePassword(password);
    if (passwordError) {
      setError(passwordError);
      return;
    }

    if (password !== confirmPassword) {
      setError('Passwords do not match');
      return;
    }

    if (!isValidSession) {
      setError('Invalid session. Please request a new password reset.');
      return;
    }

    setLoading(true);

    try {
      console.log('🔄 Updating password for recovery session...');
      
      // First, verify we still have a valid session
      const { data: { session }, error: sessionError } = await supabase.auth.getSession();
      
      if (sessionError || !session) {
        console.error('❌ No valid session for password update:', sessionError);
        setError('Session expired. Please request a new password reset.');
        setLoading(false);
        return;
      }

      // Update the password
      const { error } = await supabase.auth.updateUser({
        password: password
      });

      if (error) {
        console.error('❌ Password update failed:', error);
        setError(error.message || 'Failed to update password. Please try again.');
      } else {
        console.log('✅ Password updated successfully');
        setMessage('Password updated successfully! You can now sign in with your new password.');
        
        // Clear the form
        setPassword('');
        setConfirmPassword('');
        
        // Sign out the user to clear the recovery session
        await supabase.auth.signOut();
        
        // Redirect to welcome page after 3 seconds
        setTimeout(() => {
          if (onNavigate) {
            onNavigate('welcome');
          } else {
            window.location.href = '/';
          }
        }, 3000);
      }
    } catch (err: any) {
      console.error('❌ Unexpected error during password update:', err);
      setError('An unexpected error occurred. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleBackToHome = () => {
    if (onNavigate) {
      onNavigate('welcome');
    } else {
      window.location.href = '/';
    }
  };

  if (checkingSession) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
        <div className="bg-white rounded-xl shadow-lg p-8 max-w-md w-full text-center">
          <div className="w-12 h-12 border-4 border-blue-200 border-t-blue-600 rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-gray-600">Verifying reset link...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl shadow-lg w-full max-w-md">
        {/* Header */}
        <div className="p-6 border-b border-gray-200">
          <div className="flex items-center justify-center mb-4">
            <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center">
              <Lock className="w-6 h-6 text-blue-600" />
            </div>
          </div>
          <h1 className="text-2xl font-bold text-gray-900 text-center">
            Reset Your Password
          </h1>
          <p className="text-gray-600 text-center mt-2">
            Enter your new password below
          </p>
        </div>

        {/* Content */}
        <div className="p-6">
          {!isValidSession ? (
            <div className="text-center">
              <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <X className="w-8 h-8 text-red-600" />
              </div>
              
              <h3 className="text-lg font-medium text-gray-900 mb-2">
                {error.includes('expired') ? 'Reset Link Expired' : 'Invalid Reset Link'}
              </h3>
              
              <p className="text-gray-600 mb-4">
                {error}
              </p>
              
              {error.includes('expired') && (
                <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-3 mb-4">
                  <p className="text-yellow-800 text-sm">
                    💡 <strong>Tip:</strong> Password reset links expire after 1 hour for security. 
                    Request a new one below to continue.
                  </p>
                </div>
              )}
              
              <div className="space-y-3">
                <button
                  onClick={() => setShowForgotPasswordModal(true)}
                  className="w-full bg-blue-600 hover:bg-blue-700 text-white py-2 px-4 rounded-lg font-medium transition-colors"
                >
                  Request New Password Reset
                </button>
                
                <button
                  onClick={handleBackToHome}
                  className="w-full text-gray-600 hover:text-gray-800 py-2 px-4 rounded-lg font-medium transition-colors"
                >
                  Back to Home
                </button>
              </div>
            </div>
          ) : message ? (
            <div className="text-center">
              <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <Check className="w-8 h-8 text-green-600" />
              </div>
              
              <h3 className="text-lg font-medium text-gray-900 mb-2">
                Password Updated!
              </h3>
              
              <p className="text-gray-600 mb-6">
                Your password has been successfully updated. You will be redirected to the home page shortly.
              </p>
              
              <button
                onClick={handleBackToHome}
                className="w-full bg-blue-600 hover:bg-blue-700 text-white py-2 px-4 rounded-lg font-medium transition-colors"
              >
                Continue to Home
              </button>
            </div>
          ) : (
            <div>
              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-2">
                    New Password
                  </label>
                <div className="relative">
                  <input
                    type={showPassword ? "text" : "password"}
                    id="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="w-full px-3 py-2 pr-10 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    placeholder="Enter new password"
                    required
                    disabled={loading}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600"
                  >
                    {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                  </button>
                </div>
              </div>

              <div>
                <label htmlFor="confirmPassword" className="block text-sm font-medium text-gray-700 mb-2">
                  Confirm New Password
                </label>
                <div className="relative">
                  <input
                    type={showConfirmPassword ? "text" : "password"}
                    id="confirmPassword"
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    className="w-full px-3 py-2 pr-10 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    placeholder="Confirm new password"
                    required
                    disabled={loading}
                  />
                  <button
                    type="button"
                    onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                    className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600"
                  >
                    {showConfirmPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                  </button>
                </div>
              </div>

              {error && (
                <div className="bg-red-50 border border-red-200 rounded-lg p-3">
                  <p className="text-red-600 text-sm">{error}</p>
                </div>
              )}

              <button
                type="submit"
                disabled={loading}
                className="w-full bg-blue-600 hover:bg-blue-700 disabled:bg-blue-400 text-white py-2 px-4 rounded-lg font-medium transition-colors flex items-center justify-center"
              >
                {loading ? (
                  <>
                    <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin mr-2" />
                    Updating...
                  </>
                ) : (
                  'Update Password'
                )}
              </button>
            </form>
            </div>
          )}
        </div>
      </div>
      
      {/* Forgot Password Modal */}
      <ForgotPasswordModal
        isOpen={showForgotPasswordModal}
        onClose={() => setShowForgotPasswordModal(false)}
        onBackToLogin={() => {
          setShowForgotPasswordModal(false);
          handleBackToHome();
        }}
      />
    </div>
  );
};
