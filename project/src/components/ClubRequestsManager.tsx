import React, { useState, useEffect } from 'react';
import { Users, Check, X, Clock, User, MessageCircle } from 'lucide-react';
import { TailorMatesService } from '../services/tailorMatesService';

interface JoinRequest {
  id: string;
  user_id: string;
  user_name: string;
  user_username: string;
  user_avatar_url: string;
  status: string;
  requested_at: string;
  message: string;
}

interface ClubRequestsManagerProps {
  clubId: string;
  clubName: string;
  isAdmin: boolean;
}

const ClubRequestsManager: React.FC<ClubRequestsManagerProps> = ({
  clubId,
  clubName,
  isAdmin
}) => {
  const [joinRequests, setJoinRequests] = useState<JoinRequest[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [processingRequest, setProcessingRequest] = useState<string | null>(null);

  const loadJoinRequests = async () => {
    if (!isAdmin) return;
    
    try {
      setIsLoading(true);
      const requests = await TailorMatesService.getClubJoinRequests(clubId);
      setJoinRequests(requests);
    } catch (error) {
      console.error('Error loading join requests:', error);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadJoinRequests();
  }, [clubId, isAdmin]);

  const handleProcessRequest = async (requestId: string, approve: boolean, message?: string) => {
    if (!isAdmin) return;
    
    try {
      setProcessingRequest(requestId);
      const result = await TailorMatesService.processJoinRequest(requestId, approve, message);
      
      if (result.success) {
        // Remove the processed request from the list
        setJoinRequests(prev => prev.filter(req => req.id !== requestId));
        alert(result.message);
      } else {
        alert(result.message || 'Failed to process join request');
      }
    } catch (error) {
      console.error('Error processing join request:', error);
      alert('Failed to process join request. Please try again.');
    } finally {
      setProcessingRequest(null);
    }
  };

  if (!isAdmin) {
    return (
      <div className="text-center py-8">
        <div className="bg-red-500/20 border border-red-500/30 text-red-300 px-4 py-3 rounded-lg">
          Only admins can view club join requests.
        </div>
      </div>
    );
  }

  if (isLoading) {
    return (
      <div className="text-center py-8">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-pink-400 mx-auto"></div>
        <p className="text-white/70 mt-4">Loading join requests...</p>
      </div>
    );
  }

  const pendingRequests = joinRequests.filter(req => req.status === 'pending');
  const processedRequests = joinRequests.filter(req => req.status !== 'pending');

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-3">
          <Users className="w-6 h-6 text-pink-400" />
          <h2 className="text-2xl font-bold text-white">Club Requests</h2>
          {pendingRequests.length > 0 && (
            <div className="bg-pink-500/20 border border-pink-500/30 text-pink-300 px-2 py-1 rounded-full text-sm font-medium">
              {pendingRequests.length} pending
            </div>
          )}
        </div>
        <button
          onClick={loadJoinRequests}
          className="px-4 py-2 bg-white/10 hover:bg-white/20 border border-white/20 text-white rounded-lg transition-colors"
        >
          Refresh
        </button>
      </div>

      {/* Pending Requests */}
      {pendingRequests.length === 0 && processedRequests.length === 0 ? (
        <div className="text-center py-12">
          <Users className="w-16 h-16 text-white/30 mx-auto mb-4" />
          <h3 className="text-xl font-bold text-white mb-2">No Join Requests</h3>
          <p className="text-white/70">
            No users have requested to join this club yet.
          </p>
        </div>
      ) : (
        <>
          {pendingRequests.length > 0 && (
            <div className="space-y-4">
              <h3 className="text-lg font-semibold text-white flex items-center space-x-2">
                <Clock className="w-5 h-5 text-amber-400" />
                <span>Pending Requests ({pendingRequests.length})</span>
              </h3>
              
              {pendingRequests.map((request) => (
                <div key={request.id} className="bg-white/5 border border-white/10 rounded-xl p-4">
                  <div className="flex items-start space-x-4">
                    {/* User Avatar */}
                    <div className="flex-shrink-0">
                      {request.user_avatar_url ? (
                        <img
                          src={request.user_avatar_url}
                          alt={request.user_name}
                          className="w-12 h-12 rounded-full object-cover"
                        />
                      ) : (
                        <div className="w-12 h-12 bg-gradient-to-r from-pink-500 to-purple-600 rounded-full flex items-center justify-center">
                          <User className="w-6 h-6 text-white" />
                        </div>
                      )}
                    </div>

                    {/* Request Details */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center space-x-2 mb-2">
                        <h4 className="font-semibold text-white truncate">{request.user_name}</h4>
                        <span className="text-white/60 text-sm">@{request.user_username}</span>
                      </div>
                      
                      {request.message && (
                        <div className="mb-3">
                          <div className="flex items-start space-x-2">
                            <MessageCircle className="w-4 h-4 text-white/60 mt-0.5 flex-shrink-0" />
                            <p className="text-white/80 text-sm bg-white/5 rounded-lg p-3">
                              {request.message}
                            </p>
                          </div>
                        </div>
                      )}
                      
                      <div className="flex items-center justify-between">
                        <span className="text-white/60 text-sm">
                          Requested {new Date(request.requested_at).toLocaleDateString()}
                        </span>
                        
                        <div className="flex items-center space-x-2">
                          <button
                            onClick={() => handleProcessRequest(request.id, false)}
                            disabled={processingRequest === request.id}
                            className="px-4 py-2 bg-red-500/20 hover:bg-red-500/30 border border-red-500/30 text-red-300 rounded-lg transition-colors disabled:opacity-50 flex items-center space-x-2"
                          >
                            <X className="w-4 h-4" />
                            <span>Decline</span>
                          </button>
                          <button
                            onClick={() => handleProcessRequest(request.id, true)}
                            disabled={processingRequest === request.id}
                            className="px-4 py-2 bg-green-500/20 hover:bg-green-500/30 border border-green-500/30 text-green-300 rounded-lg transition-colors disabled:opacity-50 flex items-center space-x-2"
                          >
                            <Check className="w-4 h-4" />
                            <span>Approve</span>
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* Processed Requests */}
          {processedRequests.length > 0 && (
            <div className="space-y-4">
              <h3 className="text-lg font-semibold text-white flex items-center space-x-2">
                <Check className="w-5 h-5 text-green-400" />
                <span>Recent Activity ({processedRequests.length})</span>
              </h3>
              
              {processedRequests.slice(0, 5).map((request) => (
                <div key={request.id} className="bg-white/5 border border-white/10 rounded-xl p-4">
                  <div className="flex items-center space-x-3">
                    {/* User Avatar */}
                    <div className="flex-shrink-0">
                      {request.user_avatar_url ? (
                        <img
                          src={request.user_avatar_url}
                          alt={request.user_name}
                          className="w-10 h-10 rounded-full object-cover"
                        />
                      ) : (
                        <div className="w-10 h-10 bg-gradient-to-r from-pink-500 to-purple-600 rounded-full flex items-center justify-center">
                          <User className="w-5 h-5 text-white" />
                        </div>
                      )}
                    </div>

                    {/* Request Details */}
                    <div className="flex-1">
                      <div className="flex items-center space-x-2 mb-1">
                        <span className="font-medium text-white">{request.user_name}</span>
                        <span className="text-white/60 text-sm">@{request.user_username}</span>
                        <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                          request.status === 'approved' 
                            ? 'bg-green-500/20 text-green-300' 
                            : 'bg-red-500/20 text-red-300'
                        }`}>
                          {request.status === 'approved' ? 'Approved' : 'Declined'}
                        </span>
                      </div>
                      <span className="text-white/60 text-sm">
                        {new Date(request.requested_at).toLocaleDateString()}
                      </span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </>
      )}
    </div>
  );
};

export default ClubRequestsManager;
