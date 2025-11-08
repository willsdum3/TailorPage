import React, { useState, useEffect } from 'react';
import { Mail, CheckCircle, XCircle, Clock, Users, MessageSquare } from 'lucide-react';
import { TailorMatesService } from '../services/tailorMatesService';
import { ClubInvitation } from '../types';

interface ClubInvitationsNotificationsProps {
  onInvitationResponse?: () => void;
  refreshToken?: any;
  showEmptyState?: boolean;
  title?: string;
  subtitle?: string;
  className?: string;
}

const ClubInvitationsNotifications: React.FC<ClubInvitationsNotificationsProps> = ({ 
  onInvitationResponse,
  refreshToken,
  showEmptyState = false,
  title = 'Club Invitations',
  subtitle,
  className = ''
}) => {
  const [invitations, setInvitations] = useState<ClubInvitation[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [respondingTo, setRespondingTo] = useState<string | null>(null);

  useEffect(() => {
    loadInvitations();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [refreshToken]);

  const loadInvitations = async () => {
    try {
      setIsLoading(true);
      const userInvitations = await TailorMatesService.getUserClubInvitations();
      setInvitations(userInvitations);
    } catch (error) {
      console.error('Error loading invitations:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleResponse = async (invitationId: string, response: 'accepted' | 'declined') => {
    try {
      setRespondingTo(invitationId);
      const result = await TailorMatesService.respondToClubInvitation(invitationId, response);
      
      if (result.success) {
        // Remove the invitation from the list since it's been responded to
        setInvitations(prev => prev.filter(inv => inv.id !== invitationId));
        onInvitationResponse?.();
        
        // Show success message
        alert(result.message);
      } else {
        alert(result.message);
      }
    } catch (error) {
      console.error('Error responding to invitation:', error);
      alert('Failed to respond to invitation. Please try again.');
    } finally {
      setRespondingTo(null);
    }
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffInHours = (now.getTime() - date.getTime()) / (1000 * 60 * 60);

    if (diffInHours < 1) {
      return 'Just now';
    } else if (diffInHours < 24) {
      return `${Math.floor(diffInHours)}h ago`;
    } else if (diffInHours < 168) { // 7 days
      return `${Math.floor(diffInHours / 24)}d ago`;
    } else {
      return date.toLocaleDateString();
    }
  };

  const isExpiring = (expiresAt: string) => {
    const expirationDate = new Date(expiresAt);
    const now = new Date();
    const hoursUntilExpiry = (expirationDate.getTime() - now.getTime()) / (1000 * 60 * 60);
    return hoursUntilExpiry <= 24 && hoursUntilExpiry > 0;
  };

  if (isLoading) {
    return (
      <div className={`bg-white border border-gray-200 rounded-xl p-6 ${className}`}>
        <div className="flex items-center justify-center">
          <div className="animate-spin w-6 h-6 border-2 border-blue-500 border-t-transparent rounded-full"></div>
          <span className="ml-3 text-gray-600">Loading invitations...</span>
        </div>
      </div>
    );
  }

  if (invitations.length === 0) {
    if (!showEmptyState) {
      return null; // Silent mode for inline banner
    }

    return (
      <div className={`bg-white border border-gray-200 rounded-xl p-8 text-center ${className}`}>
        <div className="w-16 h-16 rounded-full bg-gradient-to-r from-blue-100 to-purple-100 flex items-center justify-center mx-auto mb-4">
          <Mail className="w-8 h-8 text-blue-500" />
        </div>
        <h3 className="text-xl font-semibold text-gray-900 mb-2">No Invitations Yet</h3>
        <p className="text-gray-600 max-w-md mx-auto">
          When another reader invites you to a club, it will appear here so you can accept or decline with a single click.
        </p>
      </div>
    );
  }

  return (
    <div className={`bg-white border border-gray-200 rounded-xl overflow-hidden ${className}`}>
      <div className="bg-gradient-to-r from-blue-50 to-purple-50 p-4 border-b border-gray-200">
        <div className="flex items-center space-x-3">
          <div className="w-8 h-8 bg-gradient-to-r from-blue-500 to-purple-600 rounded-lg flex items-center justify-center">
            <Mail className="w-4 h-4 text-white" />
          </div>
          <div>
            <h3 className="text-lg font-semibold text-gray-900">{title}</h3>
            <p className="text-sm text-gray-600">
              {subtitle
                ? subtitle
                : `You have ${invitations.length} pending invitation${invitations.length !== 1 ? 's' : ''}`}
            </p>
          </div>
        </div>
      </div>

      {/* Invitations List */}
      <div className="divide-y divide-gray-200">
        {invitations.map((invitation) => (
          <div key={invitation.id} className="p-6">
            <div className="flex items-start justify-between">
              <div className="flex-1">
                {/* Club Info */}
                <div className="flex items-center space-x-3 mb-3">
                  {invitation.inviterAvatarUrl ? (
                    <img
                      src={invitation.inviterAvatarUrl}
                      alt={invitation.inviterName || 'Club invitation'}
                      className="w-12 h-12 rounded-xl object-cover border border-white shadow-sm"
                    />
                  ) : (
                    <div className="w-12 h-12 bg-gradient-to-r from-pink-500 to-purple-600 rounded-xl flex items-center justify-center">
                      <Users className="w-5 h-5 text-white" />
                    </div>
                  )}
                  <div>
                    <h4 className="text-lg font-semibold text-gray-900">{invitation.clubName}</h4>
                    <p className="text-sm text-gray-600">
                      Invited by @{invitation.inviterUsername || 'unknown'}
                      {invitation.inviterName ? ` (${invitation.inviterName})` : ''}
                    </p>
                  </div>
                </div>

                {/* Club Description */}
                <p className="text-gray-700 mb-3 line-clamp-2">
                  {invitation.clubDescription || 'This club has not provided a description yet.'}
                </p>

                {/* Personal Message */}
                {invitation.message && (
                  <div className="bg-gray-50 rounded-lg p-3 mb-3">
                    <div className="flex items-start space-x-2">
                      <MessageSquare className="w-4 h-4 text-gray-500 mt-0.5" />
                      <p className="text-sm text-gray-700 italic">"{invitation.message}"</p>
                    </div>
                  </div>
                )}

                {/* Timing Info */}
                <div className="flex items-center space-x-4 text-sm text-gray-500 mb-4">
                  <span>Invited {formatDate(invitation.createdAt)}</span>
                  {isExpiring(invitation.expiresAt) && (
                    <div className="flex items-center space-x-1 text-orange-600">
                      <Clock className="w-4 h-4" />
                      <span className="font-medium">Expires soon</span>
                    </div>
                  )}
                </div>

                {/* Action Buttons */}
                <div className="flex items-center space-x-3">
                  <button
                    onClick={() => handleResponse(invitation.id, 'accepted')}
                    disabled={respondingTo === invitation.id}
                    className="bg-gradient-to-r from-green-500 to-green-600 text-white px-4 py-2 rounded-lg font-medium hover:from-green-600 hover:to-green-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center space-x-2 transition-all"
                  >
                    {respondingTo === invitation.id ? (
                      <>
                        <div className="animate-spin w-4 h-4 border-2 border-white border-t-transparent rounded-full"></div>
                        <span>Accepting...</span>
                      </>
                    ) : (
                      <>
                        <CheckCircle className="w-4 h-4" />
                        <span>Accept</span>
                      </>
                    )}
                  </button>
                  
                  <button
                    onClick={() => handleResponse(invitation.id, 'declined')}
                    disabled={respondingTo === invitation.id}
                    className="bg-gray-100 text-gray-700 px-4 py-2 rounded-lg font-medium hover:bg-gray-200 disabled:opacity-50 disabled:cursor-not-allowed flex items-center space-x-2 transition-all"
                  >
                    {respondingTo === invitation.id ? (
                      <>
                        <div className="animate-spin w-4 h-4 border-2 border-gray-500 border-t-transparent rounded-full"></div>
                        <span>Declining...</span>
                      </>
                    ) : (
                      <>
                        <XCircle className="w-4 h-4" />
                        <span>Decline</span>
                      </>
                    )}
                  </button>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default ClubInvitationsNotifications;
