import React, { useState } from 'react';
import { Settings, Users, UserPlus, UserMinus, Crown, Edit3, BarChart3, X } from 'lucide-react';
import { TailorMatesService } from '../services/tailorMatesService';

interface AdminPanelProps {
  clubId: string;
  members: any[];
  onMembersUpdate: () => void;
  onClubUpdate: () => void;
  onClose: () => void;
}

const AdminPanel: React.FC<AdminPanelProps> = ({ 
  clubId, 
  members, 
  onMembersUpdate, 
  onClubUpdate, 
  onClose 
}) => {
  const [activeTab, setActiveTab] = useState<'members' | 'polls' | 'settings'>('members');
  const [showInviteModal, setShowInviteModal] = useState(false);
  const [showEditClubModal, setShowEditClubModal] = useState(false);
  const [showCreatePollModal, setShowCreatePollModal] = useState(false);
  const [inviteUserId, setInviteUserId] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  const handleInviteUser = async () => {
    if (!inviteUserId.trim()) return;
    
    setIsLoading(true);
    try {
      const result = await TailorMatesService.inviteUserToBookClub(clubId, inviteUserId.trim());
      setMessage({ type: result.success ? 'success' : 'error', text: result.message });
      if (result.success) {
        setInviteUserId('');
        setShowInviteModal(false);
        onMembersUpdate();
      }
    } catch (error) {
      setMessage({ type: 'error', text: 'Failed to invite user' });
    } finally {
      setIsLoading(false);
    }
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
            { id: 'polls', label: 'Polls', icon: BarChart3 },
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

          {activeTab === 'polls' && (
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-semibold text-white">Manage Polls</h3>
                <button
                  onClick={() => setShowCreatePollModal(true)}
                  className="flex items-center space-x-2 bg-pink-500 hover:bg-pink-600 text-white px-4 py-2 rounded-lg transition-colors"
                >
                  <BarChart3 className="w-4 h-4" />
                  <span>Create Poll</span>
                </button>
              </div>
              <p className="text-white/60">Poll management coming soon...</p>
            </div>
          )}

          {activeTab === 'settings' && (
            <div className="space-y-4">
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
              <p className="text-white/60">Club settings management coming soon...</p>
            </div>
          )}
        </div>
      </div>

      {/* Invite User Modal */}
      {showInviteModal && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-60 flex items-center justify-center p-4">
          <div className="bg-slate-900 rounded-2xl border border-white/20 p-6 w-full max-w-md">
            <h3 className="text-xl font-bold text-white mb-4">Invite User</h3>
            <div className="space-y-4">
              <div>
                <label className="block text-white/80 text-sm mb-2">User ID</label>
                <input
                  type="text"
                  value={inviteUserId}
                  onChange={(e) => setInviteUserId(e.target.value)}
                  placeholder="Enter user ID to invite"
                  className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder-white/50 focus:outline-none focus:border-pink-400"
                />
              </div>
              <div className="flex space-x-3">
                <button
                  onClick={handleInviteUser}
                  disabled={isLoading || !inviteUserId.trim()}
                  className="flex-1 bg-pink-500 hover:bg-pink-600 disabled:opacity-50 text-white px-4 py-3 rounded-lg transition-colors"
                >
                  {isLoading ? 'Inviting...' : 'Invite User'}
                </button>
                <button
                  onClick={() => setShowInviteModal(false)}
                  className="px-4 py-3 text-white/60 hover:text-white transition-colors"
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default AdminPanel;
