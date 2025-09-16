import React, { useState, useEffect } from 'react';
import { Settings, Users, UserPlus, UserMinus, Crown, Edit3, X } from 'lucide-react';
import { TailorMatesService } from '../services/tailorMatesService';
import InviteUserModal from './InviteUserModal';

interface AdminPanelProps {
  clubId: string;
  members: any[];
  clubData?: any; // Add club data to access current public/private status
  onMembersUpdate: () => void;
  onClubUpdate: () => void;
  onClose: () => void;
}

const AdminPanel: React.FC<AdminPanelProps> = ({ 
  clubId, 
  members, 
  clubData,
  onMembersUpdate, 
  onClubUpdate, 
  onClose 
}) => {
  const [activeTab, setActiveTab] = useState<'members' | 'settings'>('members');
  const [showInviteModal, setShowInviteModal] = useState(false);
  const [showEditClubModal, setShowEditClubModal] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);
  const [isTogglingVisibility, setIsTogglingVisibility] = useState(false);
  const [currentVisibility, setCurrentVisibility] = useState<boolean | null>(null);

  // Initialize current visibility state when clubData changes
  useEffect(() => {
    if (clubData) {
      setCurrentVisibility(!clubData.isPrivate); // isPublic = !isPrivate
    }
  }, [clubData]);

  const handleInviteSent = () => {
    // Refresh members list after successful invitation
    onMembersUpdate();
    setMessage({ type: 'success', text: 'Invitation sent successfully!' });
  };

  const handleRemoveUser = async (userId: string, userName: string) => {
    if (!window.confirm(`Are you sure you want to remove ${userName} from the club?`)) return;
    
    setIsLoading(true);
    try {
      const result = await TailorMatesService.removeUserFromBookClub(clubId, userId);
      setMessage({ type: result.success ? 'success' : 'error', text: result.message });
      if (result.success) {
        onMembersUpdate();
      }
    } catch (error) {
      setMessage({ type: 'error', text: 'Failed to remove user' });
    } finally {
      setIsLoading(false);
    }
  };

  const handlePromoteUser = async (userId: string, userName: string) => {
    if (!window.confirm(`Are you sure you want to promote ${userName} to admin?`)) return;
    
    setIsLoading(true);
    try {
      const result = await TailorMatesService.promoteUserToAdmin(clubId, userId);
      setMessage({ type: result.success ? 'success' : 'error', text: result.message });
      if (result.success) {
        onMembersUpdate();
      }
    } catch (error) {
      setMessage({ type: 'error', text: 'Failed to promote user' });
    } finally {
      setIsLoading(false);
    }
  };

  const handleToggleVisibility = async (newVisibility: boolean) => {
    if (!clubData) return;
    
    console.log('Current club data:', clubData);
    console.log('Current isPrivate:', clubData.isPrivate);
    console.log('New visibility (isPublic):', newVisibility);
    
    setIsTogglingVisibility(true);
    try {
      const result = await TailorMatesService.toggleBookClubVisibility(clubId, newVisibility);
      console.log('Toggle result:', result);
      
      setMessage({ type: result.success ? 'success' : 'error', text: result.message });
      if (result.success) {
        setCurrentVisibility(newVisibility); // Update local state immediately
        onClubUpdate(); // Refresh club data
      }
    } catch (error) {
      console.error('Toggle visibility error:', error);
      setMessage({ type: 'error', text: 'Failed to update club visibility' });
    } finally {
      setIsTogglingVisibility(false);
    }
  };

  const clearMessage = () => setMessage(null);

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="bg-slate-900 rounded-2xl border border-white/20 w-full max-w-4xl max-h-[90vh] overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-white/10">
          <div className="flex items-center space-x-3">
            <Settings className="w-6 h-6 text-pink-400" />
            <h2 className="text-2xl font-bold text-white">Admin Panel</h2>
          </div>
          <button
            onClick={onClose}
            className="p-2 hover:bg-white/10 rounded-lg transition-colors"
          >
            <X className="w-5 h-5 text-white/60" />
          </button>
        </div>

        {/* Tabs */}
        <div className="flex border-b border-white/10">
          {[
            { id: 'members', label: 'Members', icon: Users },
            { id: 'settings', label: 'Settings', icon: Settings }
          ].map((tab) => {
            const IconComponent = tab.icon;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as any)}
                className={`flex items-center space-x-2 px-6 py-4 font-medium transition-colors ${
                  activeTab === tab.id
                    ? 'text-pink-400 border-b-2 border-pink-400'
                    : 'text-white/60 hover:text-white'
                }`}
              >
                <IconComponent className="w-4 h-4" />
                <span>{tab.label}</span>
              </button>
            );
          })}
        </div>

        {/* Content */}
        <div className="p-6 max-h-[60vh] overflow-y-auto">
          {message && (
            <div className={`mb-4 p-4 rounded-lg ${
              message.type === 'success' 
                ? 'bg-green-500/20 text-green-300 border border-green-500/30' 
                : 'bg-red-500/20 text-red-300 border border-red-500/30'
            }`}>
              <div className="flex items-center justify-between">
                <span>{message.text}</span>
                <button onClick={clearMessage} className="text-white/60 hover:text-white">
                  <X className="w-4 h-4" />
                </button>
              </div>
            </div>
          )}

          {activeTab === 'members' && (
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-semibold text-white">Manage Members</h3>
                <button
                  onClick={() => setShowInviteModal(true)}
                  className="flex items-center space-x-2 bg-pink-500 hover:bg-pink-600 text-white px-4 py-2 rounded-lg transition-colors"
                >
                  <UserPlus className="w-4 h-4" />
                  <span>Invite User</span>
                </button>
              </div>

              <div className="space-y-3">
                {members.map((member) => (
                  <div key={member.user_id} className="flex items-center justify-between p-4 bg-white/5 rounded-lg">
                    <div className="flex items-center space-x-3">
                      {member.avatar_url ? (
                        <img 
                          src={member.avatar_url} 
                          alt={member.name} 
                          className="w-10 h-10 rounded-full object-cover border border-white/20"
                        />
                      ) : (
                        <div className="w-10 h-10 bg-gradient-to-r from-pink-500 to-purple-600 rounded-full flex items-center justify-center">
                          <span className="text-white font-semibold text-sm">
                            {member.name.charAt(0).toUpperCase()}
                          </span>
                        </div>
                      )}
                      <div>
                        <div className="flex items-center space-x-2">
                          <span className="text-white font-medium">{member.name}</span>
                          {member.role === 'admin' && (
                            <Crown className="w-4 h-4 text-yellow-400" />
                          )}
                        </div>
                        <p className="text-white/60 text-sm">@{member.username}</p>
                      </div>
                    </div>
                    <div className="flex items-center space-x-2">
                      {member.role !== 'admin' && (
                        <button
                          onClick={() => handlePromoteUser(member.user_id, member.name)}
                          disabled={isLoading}
                          className="p-2 bg-yellow-500/20 hover:bg-yellow-500/30 text-yellow-300 rounded-lg transition-colors disabled:opacity-50"
                          title="Promote to Admin"
                        >
                          <Crown className="w-4 h-4" />
                        </button>
                      )}
                      <button
                        onClick={() => handleRemoveUser(member.user_id, member.name)}
                        disabled={isLoading}
                        className="p-2 bg-red-500/20 hover:bg-red-500/30 text-red-300 rounded-lg transition-colors disabled:opacity-50"
                        title="Remove User"
                      >
                        <UserMinus className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {activeTab === 'settings' && (
            <div className="space-y-6">
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-semibold text-white">Club Settings</h3>
                <button
                  onClick={() => setShowEditClubModal(true)}
                  className="flex items-center space-x-2 bg-pink-500 hover:bg-pink-600 text-white px-4 py-2 rounded-lg transition-colors"
                >
                  <Edit3 className="w-4 h-4" />
                  <span>Edit Club</span>
                </button>
              </div>

              {/* Public/Private Toggle */}
              <div className="bg-white/5 rounded-xl p-6 border border-white/10">
                <div className="flex items-center justify-between">
                  <div>
                    <h4 className="text-lg font-medium text-white mb-2">Club Visibility</h4>
                    <p className="text-white/70 text-sm">
                      {currentVisibility === false
                        ? 'This club is currently private. Only members can see and join it.'
                        : 'This club is currently public. Anyone can see and join it.'
                      }
                    </p>
                  </div>
                  <button
                    onClick={() => handleToggleVisibility(!currentVisibility)}
                    disabled={isTogglingVisibility || !clubData || currentVisibility === null}
                    className={`relative inline-flex h-8 w-14 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-pink-500 focus:ring-offset-2 focus:ring-offset-slate-900 disabled:opacity-50 disabled:cursor-not-allowed ${
                      currentVisibility ? 'bg-pink-500' : 'bg-gray-600'
                    }`}
                  >
                    <span
                      className={`inline-block h-6 w-6 transform rounded-full bg-white transition-transform ${
                        currentVisibility ? 'translate-x-7' : 'translate-x-1'
                      }`}
                    />
                    {isTogglingVisibility && (
                      <div className="absolute inset-0 flex items-center justify-center">
                        <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                      </div>
                    )}
                  </button>
                </div>
                <div className="mt-3 flex items-center space-x-2 text-sm">
                  <span className={`px-2 py-1 rounded-lg text-xs font-medium ${
                    currentVisibility === false
                      ? 'bg-red-500/20 text-red-300' 
                      : 'bg-green-500/20 text-green-300'
                  }`}>
                    {currentVisibility === false ? 'Private' : 'Public'}
                  </span>
                  <span className="text-white/50">
                    {currentVisibility === false ? 'Only members can join' : 'Anyone can join'}
                  </span>
                </div>
              </div>

              {/* Additional Settings Placeholder */}
              <div className="bg-white/5 rounded-xl p-6 border border-white/10">
                <h4 className="text-lg font-medium text-white mb-2">Additional Settings</h4>
                <p className="text-white/60 text-sm">More club settings will be available soon...</p>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Invite User Modal */}
      <InviteUserModal
        isOpen={showInviteModal}
        onClose={() => setShowInviteModal(false)}
        clubId={clubId}
        clubName={clubData?.name || 'Book Club'}
        onInviteSent={handleInviteSent}
      />
    </div>
  );
};

export default AdminPanel;
