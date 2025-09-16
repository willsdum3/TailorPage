import React, { useState, useEffect } from 'react';
import { UserPlus, Users, Clock, CheckCircle, XCircle, AlertCircle, RefreshCw } from 'lucide-react';
import { TailorMatesService } from '../services/tailorMatesService';
import { SentInvitation } from '../types';
import InviteUserModal from './InviteUserModal';

interface ClubInvitationsManagerProps {
  clubId: string;
  clubName: string;
  isAdmin: boolean;
}

const ClubInvitationsManager: React.FC<ClubInvitationsManagerProps> = ({ 
  clubId, 
  clubName, 
  isAdmin 
}) => {
  const [sentInvitations, setSentInvitations] = useState<SentInvitation[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [showInviteModal, setShowInviteModal] = useState(false);

  useEffect(() => {
    if (isAdmin) {
      loadSentInvitations();
    }
  }, [clubId, isAdmin]);

  const loadSentInvitations = async () => {
    try {
      setIsLoading(true);
      const invitations = await TailorMatesService.getClubSentInvitations(clubId);
      setSentInvitations(invitations);
    } catch (error) {
      console.error('Error loading sent invitations:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleInviteSent = () => {
    // Refresh the invitations list
    loadSentInvitations();
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'pending':
        return <Clock className="w-4 h-4 text-yellow-400" />;
      case 'accepted':
        return <CheckCircle className="w-4 h-4 text-green-400" />;
      case 'declined':
        return <XCircle className="w-4 h-4 text-red-400" />;
      case 'cancelled':
        return <AlertCircle className="w-4 h-4 text-white/60" />;
      default:
        return <Clock className="w-4 h-4 text-white/60" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'pending':
        return 'text-yellow-300 bg-yellow-500/20 border-yellow-500/30';
      case 'accepted':
        return 'text-green-300 bg-green-500/20 border-green-500/30';
      case 'declined':
        return 'text-red-300 bg-red-500/20 border-red-500/30';
      case 'cancelled':
        return 'text-white/70 bg-white/10 border-white/20';
      default:
        return 'text-white/70 bg-white/10 border-white/20';
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

  const isExpired = (expiresAt: string) => {
    return new Date(expiresAt) < new Date();
  };

  if (!isAdmin) {
    return null;
  }

  return (
    <div className="space-y-6">
      {/* Header with Invite Button */}
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-3">
          <div className="w-8 h-8 bg-gradient-to-r from-amber-400 to-orange-500 rounded-lg flex items-center justify-center">
            <Users className="w-4 h-4 text-white" />
          </div>
          <div>
            <h3 className="text-lg font-semibold text-white">Club Invitations</h3>
            <p className="text-sm text-white/70">Manage invitations to your club</p>
          </div>
        </div>
        <div className="flex items-center space-x-2">
          <button
            onClick={loadSentInvitations}
            disabled={isLoading}
            className="p-2 text-white/60 hover:text-white hover:bg-white/10 rounded-lg transition-colors"
            title="Refresh invitations"
          >
            <RefreshCw className={`w-4 h-4 ${isLoading ? 'animate-spin' : ''}`} />
          </button>
          <button
            onClick={() => setShowInviteModal(true)}
            className="bg-gradient-to-r from-amber-400 to-orange-500 text-white px-4 py-2 rounded-lg font-medium hover:from-amber-500 hover:to-orange-600 flex items-center space-x-2 transition-all shadow-lg"
          >
            <UserPlus className="w-4 h-4" />
            <span>Invite User</span>
          </button>
        </div>
      </div>

      {/* Invitations List */}
      {isLoading ? (
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin w-8 h-8 border-2 border-amber-400 border-t-transparent rounded-full"></div>
        </div>
      ) : sentInvitations.length === 0 ? (
        <div className="text-center py-12">
          <Users className="w-16 h-16 mx-auto mb-4 text-white/30" />
          <h3 className="text-lg font-medium text-white mb-2">No Invitations Sent</h3>
          <p className="text-white/70 mb-6">Start building your book club by inviting readers!</p>
          <button
            onClick={() => setShowInviteModal(true)}
            className="bg-gradient-to-r from-amber-400 to-orange-500 text-white px-6 py-3 rounded-lg font-medium hover:from-amber-500 hover:to-orange-600 flex items-center space-x-2 mx-auto transition-all shadow-lg"
          >
            <UserPlus className="w-4 h-4" />
            <span>Send First Invitation</span>
          </button>
        </div>
      ) : (
        <div className="space-y-4">
          {sentInvitations.map((invitation) => (
            <div
              key={invitation.id}
              className="bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl p-4 hover:bg-white/15 transition-all"
            >
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center space-x-3 mb-2">
                    <div className="w-8 h-8 bg-white/20 rounded-full flex items-center justify-center">
                      <Users className="w-4 h-4 text-white/80" />
                    </div>
                    <div>
                      <h4 className="font-medium text-white">@{invitation.inviteeUsername}</h4>
                      <p className="text-sm text-white/70">{invitation.inviteeName}</p>
                    </div>
                  </div>
                  
                  {invitation.message && (
                    <div className="bg-white/10 rounded-lg p-3 mb-3 border border-white/10">
                      <p className="text-sm text-white/90">"{invitation.message}"</p>
                    </div>
                  )}
                  
                  <div className="flex items-center justify-between text-sm text-white/60">
                    <span>Sent {formatDate(invitation.createdAt)}</span>
                    {invitation.status === 'pending' && isExpired(invitation.expiresAt) && (
                      <span className="text-red-400 font-medium">Expired</span>
                    )}
                  </div>
                </div>
                
                <div className={`flex items-center space-x-2 px-3 py-1 rounded-full border text-sm font-medium ${getStatusColor(invitation.status)}`}>
                  {getStatusIcon(invitation.status)}
                  <span className="capitalize">{invitation.status}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Statistics */}
      {sentInvitations.length > 0 && (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl p-4 text-center">
            <div className="text-2xl font-bold text-white">
              {sentInvitations.length}
            </div>
            <div className="text-sm text-white/70">Total Sent</div>
          </div>
          <div className="bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl p-4 text-center">
            <div className="text-2xl font-bold text-yellow-400">
              {sentInvitations.filter(inv => inv.status === 'pending' && !isExpired(inv.expiresAt)).length}
            </div>
            <div className="text-sm text-white/70">Pending</div>
          </div>
          <div className="bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl p-4 text-center">
            <div className="text-2xl font-bold text-green-400">
              {sentInvitations.filter(inv => inv.status === 'accepted').length}
            </div>
            <div className="text-sm text-white/70">Accepted</div>
          </div>
          <div className="bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl p-4 text-center">
            <div className="text-2xl font-bold text-red-400">
              {sentInvitations.filter(inv => inv.status === 'declined').length}
            </div>
            <div className="text-sm text-white/70">Declined</div>
          </div>
        </div>
      )}

      {/* Invite User Modal */}
      <InviteUserModal
        isOpen={showInviteModal}
        onClose={() => setShowInviteModal(false)}
        clubId={clubId}
        clubName={clubName}
        onInviteSent={handleInviteSent}
      />
    </div>
  );
};

export default ClubInvitationsManager;
