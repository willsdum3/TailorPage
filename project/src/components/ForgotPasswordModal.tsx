import React, { useState } from 'react';
import { X, Mail, ArrowLeft, Check, Eye, EyeOff, Lock } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { supabase, supabaseAdmin } from '../lib/supabase';

interface ForgotPasswordModalProps {
  isOpen: boolean;
  onClose: () => void;
  onBackToLogin: () => void;
}

export const ForgotPasswordModal: React.FC<ForgotPasswordModalProps> = ({ 
  isOpen, 
  onClose, 
  onBackToLogin 
}) => {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');
  const [emailSent, setEmailSent] = useState(false);
  const [showDirectReset, setShowDirectReset] = useState(false);

  const { resetPassword } = useAuth();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!email.trim()) {
      setError('Please enter your email address');
      return;
    }

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      setError('Please enter a valid email address');
      return;
    }

    setLoading(true);
    setError('');
    setMessage('');

    try {
      console.log('🔄 Sending password reset email to:', email);
      
      const { error } = await resetPassword(email);

      if (error) {
        console.error('❌ Password reset failed:', error);
        setError(error.message || 'Failed to send reset email. Please try again.');
      } else {
        console.log('✅ Password reset email sent successfully');
        setEmailSent(true);
        setMessage('Password reset email sent! Check your inbox and follow the instructions to reset your password.');
      }
    } catch (err: any) {
      console.error('❌ Unexpected error during password reset:', err);
      setError('An unexpected error occurred. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    setEmail('');
    setError('');
    setMessage('');
    setEmailSent(false);
    onClose();
  };

  const handleBackToLogin = () => {
    setEmail('');
    setError('');
    setMessage('');
    setEmailSent(false);
    onBackToLogin();
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-xl shadow-2xl w-full max-w-md">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-200">
          <div className="flex items-center">
            {!emailSent && (
              <button
                onClick={handleBackToLogin}
                className="mr-3 p-1 hover:bg-gray-100 rounded-lg transition-colors"
              >
                <ArrowLeft className="w-5 h-5 text-gray-600" />
              </button>
            )}
            <h2 className="text-xl font-semibold text-gray-900">
              {emailSent ? 'Check Your Email' : 'Reset Password'}
            </h2>
          </div>
          <button
            onClick={handleClose}
            className="p-1 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <X className="w-5 h-5 text-gray-600" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6">
          {showDirectReset ? (
            <DirectPasswordResetForm 
              email={email}
              onBack={() => setShowDirectReset(false)}
              onSuccess={() => {
                setShowDirectReset(false);
                onClose();
              }}
            />
          ) : emailSent ? (
            <div className="text-center">
              <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <Check className="w-8 h-8 text-green-600" />
              </div>
              
              <h3 className="text-lg font-medium text-gray-900 mb-2">
                Email Sent Successfully!
              </h3>
              
              <p className="text-gray-600 mb-6">
                We've sent a password reset link to <strong>{email}</strong>. 
                Please check your email and follow the instructions to reset your password.
              </p>
              <p className="text-sm text-gray-500 mb-6">
                ⏰ The reset link will expire in 1 hour for security reasons.
              </p>
              
              <div className="space-y-3">
                <button
                  onClick={handleBackToLogin}
                  className="w-full bg-blue-600 hover:bg-blue-700 text-white py-2 px-4 rounded-lg font-medium transition-colors"
                >
                  Back to Sign In
                </button>
                
                <button
                  onClick={() => {
                    setEmailSent(false);
                    setMessage('');
                  }}
                  className="w-full text-gray-600 hover:text-gray-800 py-2 px-4 rounded-lg font-medium transition-colors"
                >
                  Send to Different Email
                </button>
                
                <button
                  onClick={() => {
                    setShowDirectReset(true);
                    setEmailSent(false);
                  }}
                  className="w-full bg-orange-600 hover:bg-orange-700 text-white py-2 px-4 rounded-lg font-medium transition-colors"
                >
                  🔑 Direct Password Reset (If Email Link Fails)
                </button>
              </div>
            </div>
          ) : (
            <div>
              <div className="text-center mb-6">
                <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Mail className="w-8 h-8 text-blue-600" />
                </div>
                
                <h3 className="text-lg font-medium text-gray-900 mb-2">
                  Forgot Your Password?
                </h3>
                
                              <p className="text-gray-600">
                No worries! Enter your email address and we'll send you a link to reset your password.
              </p>
              <p className="text-sm text-gray-500 mt-2">
                Note: The reset link will expire in 1 hour for security reasons.
              </p>
              </div>

              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-2">
                    Email Address
                  </label>
                  <input
                    type="email"
                    id="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    placeholder="Enter your email address"
                    required
                    disabled={loading}
                  />
                </div>

                {error && (
                  <div className="bg-red-50 border border-red-200 rounded-lg p-3">
                    <p className="text-red-600 text-sm">{error}</p>
                  </div>
                )}

                {message && (
                  <div className="bg-green-50 border border-green-200 rounded-lg p-3">
                    <p className="text-green-600 text-sm">{message}</p>
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
                      Sending...
                    </>
                  ) : (
                    'Send Reset Link'
                  )}
                </button>
              </form>

              <div className="mt-6 text-center">
                <button
                  onClick={handleBackToLogin}
                  className="text-gray-600 hover:text-gray-800 text-sm font-medium"
                >
                  Back to Sign In
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

// Direct Password Reset Form Component
interface DirectPasswordResetFormProps {
  email: string;
  onBack: () => void;
  onSuccess: () => void;
}

const DirectPasswordResetForm: React.FC<DirectPasswordResetFormProps> = ({ 
  email, 
  onBack, 
  onSuccess 
}) => {
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');

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

    setLoading(true);

    try {
      console.log('🔄 Attempting direct password reset for email:', email);
      
      // First, try to find the user by email in the users table
      const { data: users, error: userError } = await supabase
        .from('users')
        .select('auth_user_id')
        .eq('email', email);

      console.log('🔍 Users table lookup result:', { users, userError });

      if (userError || !users || users.length === 0) {
        console.log('⚠️ User not found in users table, trying alternative approach...');
        
        // Alternative approach: Try to get user by email from auth system directly
        try {
          const { data: authUsers, error: authError } = await supabaseAdmin.auth.admin.listUsers();
          
          if (authError) {
            console.error('❌ Error listing auth users:', authError);
            setError('Unable to verify email address. Please check your email and try again.');
            setLoading(false);
            return;
          }

          const authUser = authUsers.users.find(user => user.email === email);
          
          if (!authUser) {
            setError('No account found with this email address. Please check your email and try again.');
            setLoading(false);
            return;
          }

          console.log('✅ Found user in auth system:', authUser.id);

          // Update password using auth user ID
          const { error: updateError } = await supabaseAdmin.auth.admin.updateUserById(
            authUser.id,
            { password: password }
          );

          if (updateError) {
            console.error('❌ Direct password update failed:', updateError);
            setError(updateError.message || 'Failed to update password. Please try again.');
          } else {
            console.log('✅ Direct password updated successfully');
            setMessage('Password updated successfully! You can now sign in with your new password.');
            
            // Clear the form
            setPassword('');
            setConfirmPassword('');
            
            // Call success callback after 2 seconds
            setTimeout(() => {
              onSuccess();
            }, 2000);
          }
        } catch (authErr) {
          console.error('❌ Error with alternative auth lookup:', authErr);
          setError('Unable to verify email address. Please check your email and try again.');
        }
      } else {
        // Handle array result - take the first user if multiple found
        const user = Array.isArray(users) ? users[0] : users;
        console.log('✅ Found user in users table:', user.auth_user_id);

        // For direct password reset, we need to use the admin client
        const { error: updateError } = await supabaseAdmin.auth.admin.updateUserById(
          user.auth_user_id,
          { password: password }
        );

        if (updateError) {
          console.error('❌ Direct password update failed:', updateError);
          setError(updateError.message || 'Failed to update password. Please try again.');
        } else {
          console.log('✅ Direct password updated successfully');
          setMessage('Password updated successfully! You can now sign in with your new password.');
          
          // Clear the form
          setPassword('');
          setConfirmPassword('');
          
          // Call success callback after 2 seconds
          setTimeout(() => {
            onSuccess();
          }, 2000);
        }
      }
    } catch (err: any) {
      console.error('❌ Unexpected error during direct password reset:', err);
      setError('An unexpected error occurred. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <div className="text-center mb-6">
        <div className="w-16 h-16 bg-orange-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <Lock className="w-8 h-8 text-orange-600" />
        </div>
        
        <h3 className="text-lg font-medium text-gray-900 mb-2">
          Direct Password Reset
        </h3>
        
        <p className="text-gray-600 mb-2">
          Reset password for: <strong>{email}</strong>
        </p>
        <p className="text-sm text-gray-500">
          This bypasses the email link system and directly updates your password.
        </p>
      </div>

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
              className="w-full px-3 py-2 pr-10 border border-gray-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent"
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
              className="w-full px-3 py-2 pr-10 border border-gray-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent"
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

        {message && (
          <div className="bg-green-50 border border-green-200 rounded-lg p-3">
            <p className="text-green-600 text-sm">{message}</p>
          </div>
        )}

        <div className="space-y-3">
          <button
            type="submit"
            disabled={loading}
            className="w-full bg-orange-600 hover:bg-orange-700 disabled:bg-orange-400 text-white py-2 px-4 rounded-lg font-medium transition-colors flex items-center justify-center"
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
          
          <button
            type="button"
            onClick={onBack}
            className="w-full text-gray-600 hover:text-gray-800 py-2 px-4 rounded-lg font-medium transition-colors"
          >
            Back to Email Options
          </button>
        </div>
      </form>
    </div>
  );
};
