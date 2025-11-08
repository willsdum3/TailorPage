import React, { useEffect, useState } from 'react';
import { TailorMatesService } from '../services/tailorMatesService';
import { SentInvitation } from '../types';
import { Users, Clock, RefreshCw, CheckCircle, XCircle, AlertCircle, Mail } from 'lucide-react';

interface AdminSentInvitationsOverviewProps {
  clubId: string;
  clubName: string;
  memberCount?: number;
  refreshToken?: any;
}

const statusIcon = (status: string) => {
  switch (status) {
    case 'accepted':
      return <CheckCircle className="w-4 h-4 text-green-500" />;
    case 'declined':
      return <XCircle className="w-4 h-4 text-red-500" />;
    case 'cancelled':
      return <AlertCircle className="w-4 h-4 text-gray-400" />;
    default:
      return <Clock className="w-4 h-4 text-yellow-500" />;
  }
};

const statusLabelClasses = (status: string) => {
  switch (status) {
    case 'accepted':
      return 'text-green-600 bg-green-50 border-green-100';
    case 'declined':
      return 'text-red-600 bg-red-50 border-red-100';
    case 'cancelled':
      return 'text-gray-600 bg-gray-100 border-gray-200';
    default:
      return 'text-yellow-600 bg-yellow-50 border-yellow-100';
  }
};

const AdminSentInvitationsOverview: React.FC<AdminSentInvitationsOverviewProps> = ({
  clubId,
  clubName,
  memberCount,
  refreshToken
}) => {
  const [invitations, setInvitations] = useState<SentInvitation[]>([]);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    if (!clubId) return;
    loadData();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [clubId, refreshToken]);

  const loadData = async () => {
    if (!clubId) return;

    try {
      setIsLoading(true);
      const result = await TailorMatesService.getClubSentInvitations(clubId);
      setInvitations(result || []);
    } catch (error) {
      console.error('Error loading admin sent invitations:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const pendingCount = invitations.filter((inv) => inv.status === 'pending').length;

  return (
    <div className="bg-white border border-gray-200 rounded-xl overflow-hidden shadow-sm">
      <div className="flex items-center justify-between p-4 border-b border-gray-200 bg-gradient-to-r from-amber-50 to-orange-50">
        <div className="flex items-center space-x-3">
          <div className="w-8 h-8 bg-gradient-to-r from-amber-400 to-orange-500 rounded-lg flex items-center justify-center">
            <Users className="w-4 h-4 text-white" />
          </div>
          <div>
            <h3 className="text-lg font-semibold text-gray-900">
              Sent Invitations ({clubName})
            </h3>
            <p className="text-sm text-gray-600">
              {invitations.length} sent • {pendingCount} pending • {memberCount ?? '-'} members
            </p>
          </div>
        </div>
        <button
          onClick={loadData}
          disabled={isLoading}
          className="p-2 text-gray-500 hover:text-gray-700 hover:bg-white rounded-lg transition-colors"
          title="Refresh invitations"
        >
          <RefreshCw className={`w-4 h-4 ${isLoading ? 'animate-spin' : ''}`} />
        </button>
      </div>

      {isLoading && invitations.length === 0 ? (
        <div className="flex items-center justify-center py-8">
          <div className="animate-spin w-6 h-6 border-2 border-amber-400 border-t-transparent rounded-full" />
        </div>
      ) : invitations.length === 0 ? (
        <div className="flex items-center justify-center py-8 text-sm text-gray-500">
          <Users className="w-5 h-5 mr-2 text-gray-400" />
          No invitations sent for this club yet.
        </div>
      ) : (
        <div className="divide-y divide-gray-100">
          {invitations.map((invitation) => (
            <div
              key={invitation.id}
              className="p-4 flex items-start justify-between hover:bg-amber-50 transition-colors"
            >
              <div className="flex-1 pr-4">
                <div className="flex items-center space-x-2 text-sm text-gray-700">
                  <Mail className="w-4 h-4 text-gray-500" />
                  <span className="font-medium">@{invitation.inviteeUsername}</span>
                  {invitation.inviteeName && (
                    <span className="text-gray-500">({invitation.inviteeName})</span>
                  )}
                  {invitation.inviteeEmail && (
                    <span className="text-gray-400">&lt;{invitation.inviteeEmail}&gt;</span>
                  )}
                </div>
                {invitation.message && (
                  <p className="text-sm text-gray-600 mt-2 italic">
                    “{invitation.message}”
                  </p>
                )}
                <div className="text-xs text-gray-500 mt-2 flex items-center space-x-4">
                  <span>Sent {new Date(invitation.createdAt).toLocaleString()}</span>
                  {invitation.respondedAt && (
                    <span>Responded {new Date(invitation.respondedAt).toLocaleString()}</span>
                  )}
                  {!invitation.respondedAt && invitation.status === 'pending' && (
                    <span>Awaiting response</span>
                  )}
                </div>
              </div>
              <div
                className={`flex items-center space-x-2 px-3 py-1 rounded-full border text-xs font-medium ${statusLabelClasses(
                  invitation.status
                )}`}
              >
                {statusIcon(invitation.status)}
                <span className="capitalize">{invitation.status}</span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default AdminSentInvitationsOverview;

