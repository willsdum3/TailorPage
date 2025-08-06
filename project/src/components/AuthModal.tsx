import React, { useState } from 'react';
import { X, User, Mail, Lock, UserPlus, LogIn, Chrome } from 'lucide-react';
import { useSignIn, useSignUp } from '@clerk/clerk-react';


interface AuthModalProps {
  isOpen: boolean;
  onClose: () => void;
  initialMode?: 'login' | 'signup';
}

const AuthModal: React.FC<AuthModalProps> = ({ isOpen, onClose, initialMode = 'login' }) => {
  const { signIn, setActive } = useSignIn();
  const { signUp, setActive: setActiveSignUp } = useSignUp();
  const [isLoginMode, setIsLoginMode] = useState(initialMode === 'login');
  const [showVerification, setShowVerification] = useState(false);
  const [verificationCode, setVerificationCode] = useState('');
  const [formData, setFormData] = useState({
    name: '',
    username: '',
    email: '',
    password: ''
  });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isLoading, setIsLoading] = useState(false);

  // Update mode when modal opens with different initialMode
  React.useEffect(() => {
    if (isOpen) {
      setIsLoginMode(initialMode === 'login');
    }
  }, [isOpen, initialMode]);

  const handleSSOAuth = async (provider: 'oauth_google' | 'oauth_apple' | 'oauth_facebook' | 'oauth_microsoft') => {
    if (!signIn) return;
    
    setIsLoading(true);
    
    try {
      // Use authenticateWithRedirect directly for OAuth flows
      await signIn.authenticateWithRedirect({
        strategy: provider,
        redirectUrl: window.location.origin,
        redirectUrlComplete: window.location.origin
      });
      
      // The redirect will handle the rest - no need to check status here
      // Loading state will persist until the page redirects
    } catch (error: any) {
      console.error('Authentication error:', error);
      
      // Log detailed error information
      console.log('Error details:', {
        code: error.code,
        message: error.message,
        errors: error.errors
      });
      
      setErrors({ 
        general: error.errors?.[0]?.message || `${provider.replace('oauth_', '')} authentication failed. Please try again.` 
      });
      setIsLoading(false);
    }
    // Don't set loading to false here - page will redirect
  };

  const handleVerificationSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!signUp || !verificationCode.trim()) {
      setErrors({ general: 'Please enter the verification code.' });
      return;
    }

    setIsLoading(true);

    try {
      console.log('Attempting verification with code:', verificationCode);
      
      const result = await signUp.attemptEmailAddressVerification({
        code: verificationCode,
      });

      console.log('Verification result:', result);
      console.log('Required fields:', result.requiredFields);
      console.log('Optional fields:', result.optionalFields);

      if (result.status === 'complete') {
        console.log('Verification complete, setting active session...');
        await setActiveSignUp({ session: result.createdSessionId });
        console.log('Session set, closing modal...');
        // Reset all states
        setShowVerification(false);
        setVerificationCode('');
        setFormData({ name: '', username: '', email: '', password: '' });
        setErrors({});
        onClose();
      } else if (result.status === 'missing_requirements') {
        console.log('Still missing requirements after verification');
        console.log('Missing fields:', result.requiredFields);
        
        // Handle missing required fields after verification
        try {
          const updateData: any = {};
          
          // Handle username requirement
          if (result.requiredFields?.includes('username')) {
            // Use the username from form data - it should be provided since it's required in signup form
            updateData.username = formData.username;
          }
          
          // Always try to set name information if we have it
          if (formData.name.trim()) {
            const nameParts = formData.name.trim().split(' ');
            const firstName = nameParts[0] || '';
            const lastName = nameParts.slice(1).join(' ') || '';
            
            // Only add if required or if we have meaningful data
            if (result.requiredFields?.includes('first_name') || firstName) {
              updateData.firstName = firstName;
            }
            if (result.requiredFields?.includes('last_name') || lastName) {
              updateData.lastName = lastName;
            }
          }
          
          console.log('Updating with missing fields:', updateData);
          
          const updateResult = await signUp.update(updateData);
          console.log('Update result:', updateResult);
          
          if (updateResult.status === 'complete') {
            await setActiveSignUp({ session: updateResult.createdSessionId });
            setShowVerification(false);
            setVerificationCode('');
            setFormData({ name: '', username: '', email: '', password: '' });
            setErrors({});
            onClose();
          } else {
            setErrors({ general: `Still missing requirements: ${updateResult.requiredFields?.join(', ')}` });
          }
        } catch (updateError: any) {
          console.error('Update error:', updateError);
          setErrors({ general: 'Failed to complete signup. Please try again.' });
        }
      } else {
        console.log('Verification incomplete, status:', result.status);
        setErrors({ general: 'Verification failed. Please try again.' });
      }
    } catch (error: any) {
      console.error('Verification error:', error);
      setErrors({
        general: error.errors?.[0]?.message || 'Verification failed. Please check your code and try again.'
      });
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

    if (isLoginMode) {
      // For login, require email or username
      if (!formData.email.trim()) {
        newErrors.email = 'Email or username is required for login';
      }
      // Don't validate email format in login mode since it could be a username
    } else {
      // For signup, require all fields
      if (!formData.name.trim()) {
        newErrors.name = 'Name is required';
      }

      if (!formData.username.trim()) {
        newErrors.username = 'Username is required';
      } else if (formData.username.length < 3) {
        newErrors.username = 'Username must be at least 3 characters';
      } else if (!/^[a-zA-Z0-9_]+$/.test(formData.username)) {
        newErrors.username = 'Username can only contain letters, numbers, and underscores';
      }

      if (!formData.email.trim()) {
        newErrors.email = 'Email is required';
      } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
        newErrors.email = 'Please enter a valid email address';
      }
    }

    if (!formData.password.trim()) {
      newErrors.password = 'Password is required';
    } else if (formData.password.length < 8) {
      newErrors.password = 'Password must be at least 8 characters';
    } else if (!/(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/.test(formData.password)) {
      newErrors.password = 'Password must contain at least one uppercase letter, one lowercase letter, and one number';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) return;
    if (!signIn || !signUp) return;

    setIsLoading(true);

    try {
      if (isLoginMode) {
        // Use the email field as identifier - can be email or username
        const result = await signIn.create({
          identifier: formData.email, // This field contains either email or username in login mode
          password: formData.password,
        });

        if (result.status === 'complete') {
          await setActive({ session: result.createdSessionId });
          onClose();
        }
      } else {
        // Sign up with Clerk - optimized payload for better performance
        const signUpData: any = {
          emailAddress: formData.email.trim().toLowerCase(), // Normalize email
          password: formData.password,
        };
        
        // Only include username if it's provided and valid
        if (formData.username && formData.username.trim()) {
          signUpData.username = formData.username.trim().toLowerCase();
        }
        
        // Don't include firstName/lastName - your Clerk org doesn't accept them
        // The name will be added to the user profile after signup if needed
        
        console.log('Clerk signup data:', signUpData);
        console.log('Starting Clerk signup...');
        
        // Add timeout and retry logic for better performance
        const createSignupWithTimeout = async (retryCount = 0) => {
          const maxRetries = 2;
          const timeout = 30000; // 30 seconds timeout
          
          try {
            const timeoutPromise = new Promise((_, reject) => 
              setTimeout(() => reject(new Error('Signup request timed out')), timeout)
            );
            
            const signupPromise = signUp.create(signUpData);
            
            const result = await Promise.race([signupPromise, timeoutPromise]);
            return result;
          } catch (error: any) {
            console.error(`Signup attempt ${retryCount + 1} failed:`, error);
            
            if (retryCount < maxRetries && (error.message?.includes('timeout') || error.message?.includes('network'))) {
              console.log(`Retrying signup... (attempt ${retryCount + 2}/${maxRetries + 1})`);
              setErrors({ general: `Connection slow, retrying... (attempt ${retryCount + 2}/${maxRetries + 1})` });
              await new Promise(resolve => setTimeout(resolve, 1000)); // Wait 1 second before retry
              return createSignupWithTimeout(retryCount + 1);
            }
            
            throw error;
          }
        };
        
        const result = await createSignupWithTimeout();
        console.log('Clerk signup result:', result);
        console.log('Signup status:', result.status);

        if (result.status === 'complete') {
          console.log('Signup complete, setting active session...');
          await setActiveSignUp({ session: result.createdSessionId });
          console.log('Session set, closing modal...');
          onClose();
        } else if (result.status === 'missing_requirements') {
          console.log('Email verification required');
          // Handle email verification if required
          await result.prepareEmailAddressVerification({ strategy: 'email_code' });
          setShowVerification(true);
          setErrors({ general: 'Please check your email for verification code and enter it below.' });
        } else {
          console.log('Unexpected signup status:', result.status);
          setErrors({ general: `Signup incomplete. Status: ${result.status}` });
        }
      }
      
      // Reset form on success
      setFormData({ name: '', username: '', email: '', password: '' });
      setErrors({});
    } catch (error: any) {
      console.error('Authentication error:', error);
      
      // Handle specific error types
      let errorMessage = 'Authentication failed. Please try again.';
      
      if (error.errors && error.errors.length > 0) {
        const firstError = error.errors[0];
        if (firstError.code === 'form_password_pwned') {
          errorMessage = 'This password has been found in a data breach. Please choose a different, more secure password.';
        } else if (firstError.code === 'form_password_validation_failed') {
          errorMessage = 'Password does not meet security requirements. Please use a stronger password.';
        } else {
          errorMessage = firstError.message || errorMessage;
        }
      }
      
      setErrors({ general: errorMessage });
    } finally {
      setIsLoading(false);
    }
  };

  const toggleMode = () => {
    setIsLoginMode(!isLoginMode);
    setFormData({ name: '', username: '', email: '', password: '' });
    setErrors({});
    setShowVerification(false);
    setVerificationCode('');
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

        <form onSubmit={showVerification ? handleVerificationSubmit : handleSubmit} className="p-6 space-y-4">
          {errors.general && (
            <div className={`${errors.general.includes('retrying') ? 'bg-blue-500/10 border-blue-500/20' : 'bg-red-500/10 border-red-500/20'} rounded-xl p-3`}>
              <p className={`text-sm ${errors.general.includes('retrying') ? 'text-blue-400' : 'text-red-400'}`}>
                {errors.general}
              </p>
            </div>
          )}

          {/* Loading progress indicator */}
          {isLoading && !showVerification && !isLoginMode && (
            <div className="bg-amber-500/10 border border-amber-500/20 rounded-xl p-3">
              <div className="flex items-center space-x-3">
                <div className="w-5 h-5 border-2 border-amber-400/30 border-t-amber-400 rounded-full animate-spin" />
                <div className="flex-1">
                  <p className="text-amber-400 text-sm font-medium">Creating your account...</p>
                  <p className="text-amber-400/70 text-xs mt-1">
                    This may take up to 30 seconds. Please don't close this window.
                  </p>
                </div>
              </div>
            </div>
          )}

          {/* CAPTCHA element for Clerk */}
          <div id="clerk-captcha" className="hidden"></div>

          {!showVerification && (
            <>
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

              {!isLoginMode && (
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
                      placeholder="Choose a username"
                    />
                  </div>
                  {errors.username && <p className="text-red-400 text-sm mt-2">{errors.username}</p>}
                </div>
              )}

              <div>
                <label htmlFor="email" className="block text-sm font-medium text-white/90 mb-2">
                  {isLoginMode ? 'Email or Username' : 'Email Address'}
                </label>
                <div className="relative">
                  <Mail className="absolute left-4 top-1/2 transform -translate-y-1/2 w-5 h-5 text-white/40" />
                  <input
                    type={isLoginMode ? "text" : "email"}
                    id="email"
                    name="email"
                    value={formData.email}
                    onChange={handleInputChange}
                    className="w-full pl-12 pr-4 py-2.5 bg-white/5 border border-white/20 rounded-xl text-white placeholder-white/40 focus:outline-none focus:ring-2 focus:ring-amber-500/50 focus:border-amber-500/50 transition-all duration-200"
                    placeholder={isLoginMode ? "Enter your email or username" : "Enter your email address"}
                  />
                </div>
                {errors.email && <p className="text-red-400 text-sm mt-2">{errors.email}</p>}
              </div>

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
                
                {/* Password Requirements */}
                {!isLoginMode && (
                  <div className="mt-2 p-3 bg-blue-500/10 border border-blue-500/20 rounded-lg">
                    <p className="text-blue-400 text-xs font-medium mb-2">Password Requirements:</p>
                    <div className="space-y-1">
                      <div className="flex items-center space-x-2">
                        <div className={`w-1.5 h-1.5 rounded-full ${formData.password.length >= 8 ? 'bg-green-400' : 'bg-white/30'}`}></div>
                        <span className={`text-xs ${formData.password.length >= 8 ? 'text-green-400' : 'text-white/60'}`}>
                          At least 8 characters
                        </span>
                      </div>
                      <div className="flex items-center space-x-2">
                        <div className={`w-1.5 h-1.5 rounded-full ${/[A-Z]/.test(formData.password) ? 'bg-green-400' : 'bg-white/30'}`}></div>
                        <span className={`text-xs ${/[A-Z]/.test(formData.password) ? 'text-green-400' : 'text-white/60'}`}>
                          One uppercase letter (A-Z)
                        </span>
                      </div>
                      <div className="flex items-center space-x-2">
                        <div className={`w-1.5 h-1.5 rounded-full ${/[a-z]/.test(formData.password) ? 'bg-green-400' : 'bg-white/30'}`}></div>
                        <span className={`text-xs ${/[a-z]/.test(formData.password) ? 'text-green-400' : 'text-white/60'}`}>
                          One lowercase letter (a-z)
                        </span>
                      </div>
                      <div className="flex items-center space-x-2">
                        <div className={`w-1.5 h-1.5 rounded-full ${/\d/.test(formData.password) ? 'bg-green-400' : 'bg-white/30'}`}></div>
                        <span className={`text-xs ${/\d/.test(formData.password) ? 'text-green-400' : 'text-white/60'}`}>
                          One number (0-9)
                        </span>
                      </div>
                      <div className="flex items-center space-x-2">
                        <div className="w-1.5 h-1.5 rounded-full bg-amber-400"></div>
                        <span className="text-xs text-white/60">
                          Not found in data breaches
                        </span>
                      </div>
                    </div>
                  </div>
                )}
                
                {errors.password && <p className="text-red-400 text-sm mt-2">{errors.password}</p>}
              </div>
            </>
          )}

          {/* Verification Code Input - Only shown when email verification is required */}
          {showVerification && (
            <>
              <div className="bg-blue-500/10 border border-blue-500/20 rounded-xl p-3 mb-4">
                <p className="text-blue-400 text-sm">
                  We've sent a verification code to <strong>{formData.email}</strong>. 
                  Please check your email and enter the code below.
                </p>
              </div>
              
              <div>
                <label htmlFor="verificationCode" className="block text-sm font-medium text-white/90 mb-2">
                  Verification Code
                </label>
                <div className="relative">
                  <Mail className="absolute left-4 top-1/2 transform -translate-y-1/2 w-5 h-5 text-white/40" />
                  <input
                    type="text"
                    id="verificationCode"
                    name="verificationCode"
                    value={verificationCode}
                    onChange={(e) => setVerificationCode(e.target.value)}
                    className="w-full pl-12 pr-4 py-2.5 bg-white/5 border border-white/20 rounded-xl text-white placeholder-white/40 focus:outline-none focus:ring-2 focus:ring-amber-500/50 focus:border-amber-500/50 transition-all duration-200"
                    placeholder="Enter the 6-digit code from your email"
                    maxLength={6}
                    autoFocus
                  />
                </div>
                <p className="text-white/60 text-xs mt-2">
                  Didn't receive the code? Check your spam folder or{' '}
                  <button
                    type="button"
                    onClick={() => {
                      setShowVerification(false);
                      setVerificationCode('');
                      setErrors({});
                    }}
                    className="text-amber-400 hover:text-amber-300 underline"
                  >
                    go back
                  </button>{' '}
                  to try again.
                </p>
              </div>
            </>
          )}

          <button
            type="submit"
            disabled={isLoading}
            className="w-full bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 disabled:from-amber-500/50 disabled:to-orange-600/50 text-white py-2.5 rounded-xl font-semibold transition-all duration-300 transform hover:scale-105 disabled:transform-none disabled:cursor-not-allowed flex items-center justify-center space-x-2"
          >
            {isLoading ? (
              <>
                <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                <span>
                  {showVerification ? 'Verifying...' : 
                   isLoginMode ? 'Signing in...' : 'Creating account...'}
                </span>
              </>
            ) : (
              <>
                {showVerification ? (
                  <>
                    <Mail className="w-5 h-5" />
                    <span>Verify Email</span>
                  </>
                ) : (
                  <>
                    {isLoginMode ? <LogIn className="w-5 h-5" /> : <UserPlus className="w-5 h-5" />}
                    <span>{isLoginMode ? 'Log In' : 'Create Account'}</span>
                  </>
                )}
              </>
            )}
          </button>

          {!showVerification && (
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
          )}

          {!showVerification && (
            <div className="grid grid-cols-2 gap-2">
            <button
              type="button"
              onClick={() => handleSSOAuth('oauth_google')}
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
              onClick={() => handleSSOAuth('oauth_apple')}
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
              onClick={() => handleSSOAuth('oauth_facebook')}
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
              onClick={() => handleSSOAuth('oauth_microsoft')}
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
          )}

                     {!showVerification && (
             <>
               <div className="relative">
                 <div className="absolute inset-0 flex items-center">
                   <div className="w-full border-t border-white/10" />
                 </div>
                 <div className="relative flex justify-center text-sm">
                   <span className="px-2 bg-slate-900/95 text-white/60">
                     {isLoginMode ? "Don't have an account?" : "Already have an account?"}
                   </span>
                 </div>
               </div>
               
               <div className="text-center">
                 <button
                   type="button"
                   onClick={toggleMode}
                   className="text-amber-400 hover:text-amber-300 font-medium transition-colors duration-200"
                 >
                   {isLoginMode ? 'Sign Up' : 'Log In'}
                 </button>
               </div>
             </>
           )}
        </form>
      </div>
    </div>
  );
};

export default AuthModal;