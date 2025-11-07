import React, { useState, useEffect } from 'react';
import { BarChart3, Clock, Users, CheckCircle, BookOpen, Calendar } from 'lucide-react';
import { TailorMatesService } from '../services/tailorMatesService';

interface PollVotingInterfaceProps {
  clubId: string;
  onPollUpdate?: () => void; // Callback to refresh polls
}

interface Poll {
  id: string;
  title: string;
  description: string;
  poll_type: string;
  status: string;
  options: any[];
  total_votes: number;
  created_at: string;
  closes_at: string | null;
  created_by_name: string;
  user_vote: number | null;
  vote_counts: Array<{ option_index: number; vote_count: number }>;
}

const PollVotingInterface: React.FC<PollVotingInterfaceProps> = ({ clubId, onPollUpdate }) => {
  const [polls, setPolls] = useState<Poll[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [votingPollId, setVotingPollId] = useState<string | null>(null);
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  const showMessage = (type: 'success' | 'error', text: string) => {
    setMessage({ type, text });
    setTimeout(() => setMessage(null), 5000);
  };

  const loadPolls = async () => {
    try {
      setIsLoading(true);
      console.log('Loading polls for club:', clubId);
      const pollsData = await TailorMatesService.getClubPolls(clubId);
      console.log('Polls data received:', pollsData);
      setPolls(pollsData || []);
    } catch (error) {
      console.error('Error loading polls:', error);
      showMessage('error', 'Failed to load polls');
      setPolls([]);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadPolls();
  }, [clubId]);

  const handleVote = async (pollId: string, optionIndex: number) => {
    try {
      setVotingPollId(pollId);
      const result = await TailorMatesService.voteOnPoll(pollId, optionIndex);
      
      if (result.success) {
        showMessage('success', result.message);
        // Reload polls to show updated vote counts
        await loadPolls();
        if (onPollUpdate) onPollUpdate();
      } else {
        showMessage('error', result.message);
      }
    } catch (error) {
      console.error('Error voting:', error);
      showMessage('error', 'Failed to vote');
    } finally {
      setVotingPollId(null);
    }
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-GB', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const isPollActive = (poll: Poll) => {
    if (poll.status !== 'active') return false;
    if (!poll.closes_at) return true;
    return new Date(poll.closes_at) > new Date();
  };

  const getPollStatusColor = (poll: Poll) => {
    if (poll.status === 'closed') return 'text-red-400';
    if (poll.status === 'active' && isPollActive(poll)) return 'text-green-400';
    return 'text-yellow-400';
  };

  const getPollStatusText = (poll: Poll) => {
    if (poll.status === 'closed') return 'Closed';
    if (poll.status === 'active' && isPollActive(poll)) return 'Active';
    if (poll.closes_at && new Date(poll.closes_at) <= new Date()) return 'Expired';
    return 'Active';
  };

  const getNormalizedOptions = (poll: Poll) => {
    const rawOptions = Array.isArray(poll.options) ? poll.options : [];
    return rawOptions.map((option: any, index: number) => ({
      optionIndex: typeof option?.optionIndex === 'number' ? option.optionIndex : index,
      title: option?.title || '',
      author: option?.author || '',
      coverUrl: option?.coverUrl || '',
      description: option?.description || ''
    }));
  };

  const findOptionByIndex = (poll: Poll, optionIndex: number | null) => {
    if (optionIndex === null || optionIndex === undefined) return null;
    const options = getNormalizedOptions(poll);
    return options.find((option) => option.optionIndex === optionIndex) || null;
  };

  const getVotePercentage = (poll: Poll, optionIndex: number) => {
    if (poll.total_votes === 0) return 0;
    
    const voteCount = poll.vote_counts?.find(vc => vc.option_index === optionIndex)?.vote_count || 0;
    return Math.round((voteCount / poll.total_votes) * 100);
  };

  const getVoteCount = (poll: Poll, optionIndex: number) => {
    return poll.vote_counts?.find(vc => vc.option_index === optionIndex)?.vote_count || 0;
  };

  if (isLoading) {
    return (
      <div className="bg-white/5 rounded-xl p-6 border border-white/10">
        <div className="flex items-center justify-center space-x-2 text-white/70">
          <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-amber-400"></div>
          <span>Loading polls...</span>
        </div>
      </div>
    );
  }

  // Error fallback
  if (polls === null || polls === undefined) {
    return (
      <div className="bg-white/5 rounded-xl p-6 border border-white/10">
        <div className="text-center text-white/70">
          <BarChart3 className="w-12 h-12 mx-auto mb-3 text-white/30" />
          <h3 className="text-lg font-medium mb-2">Error Loading Polls</h3>
          <p className="text-sm">There was an error loading the polls. Please try again.</p>
          <button 
            onClick={loadPolls}
            className="mt-3 bg-amber-500/20 hover:bg-amber-500/30 border border-amber-500/30 text-amber-300 px-4 py-2 rounded-lg text-sm transition-all duration-300"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  if (polls.length === 0) {
    return (
      <div className="bg-white/5 rounded-xl p-6 border border-white/10">
        <div className="text-center text-white/70">
          <BarChart3 className="w-12 h-12 mx-auto mb-3 text-white/30" />
          <h3 className="text-lg font-medium mb-2">No Polls Yet</h3>
          <p className="text-sm">Admins can create polls to help choose the next book for your club.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {message && (
        <div className={`p-3 rounded-lg text-sm ${message.type === 'success' ? 'bg-green-500/20 text-green-300' : 'bg-red-500/20 text-red-300'}`}>
          {message.text}
        </div>
      )}

      {polls.map((poll) => (
        <div key={poll.id} className="bg-white/5 rounded-xl p-6 border border-white/10">
          <div className="flex items-start justify-between mb-4">
            <div className="flex-1">
              <div className="flex items-center space-x-2 mb-2">
                <h3 className="text-xl font-bold text-white">{poll.title}</h3>
                <span className={`px-2 py-1 rounded-lg text-xs font-medium ${getPollStatusColor(poll)} bg-white/10`}>
                  {getPollStatusText(poll)}
                </span>
              </div>
              <p className="text-white/70 text-sm mb-3">{poll.description}</p>
              <div className="flex items-center space-x-4 text-xs text-white/50">
                <div className="flex items-center space-x-1">
                  <Users className="w-4 h-4" />
                  <span>Created by {poll.created_by_name}</span>
                </div>
                <div className="flex items-center space-x-1">
                  <Clock className="w-4 h-4" />
                  <span>{formatDate(poll.created_at)}</span>
                </div>
                {poll.closes_at && (
                  <div className="flex items-center space-x-1">
                    <Calendar className="w-4 h-4" />
                    <span>Closes {formatDate(poll.closes_at)}</span>
                  </div>
                )}
                <div className="flex items-center space-x-1">
                  <BarChart3 className="w-4 h-4" />
                  <span>{poll.total_votes} votes</span>
                </div>
              </div>
            </div>
          </div>

          <div className="space-y-3">
            {getNormalizedOptions(poll).map((option) => {
              const isVoted = poll.user_vote === option.optionIndex;
              const isVoting = votingPollId === poll.id;
              const canVote = isPollActive(poll) && poll.user_vote === null;

              return (
                <div key={`${poll.id}-${option.optionIndex}`} className="relative">
                  <button
                    onClick={() => canVote && handleVote(poll.id, option.optionIndex)}
                    disabled={!canVote || isVoting}
                    className={`w-full p-4 rounded-xl border transition-all duration-300 text-left ${
                      isVoted
                        ? 'bg-green-500/20 border-green-500/50 text-green-300'
                        : canVote
                        ? 'bg-white/5 border-white/20 hover:bg-white/10 hover:border-white/30 text-white'
                        : 'bg-white/5 border-white/10 text-white/60'
                    } ${isVoting ? 'opacity-70 cursor-wait' : ''}`}
                  >
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="font-semibold text-lg">{option.title}</p>
                        <p className="text-sm text-white/60">{option.author}</p>
                        {option.description && (
                          <p className="text-xs text-white/40 mt-2">{option.description}</p>
                        )}
                      </div>
                      {poll.total_votes > 0 && (
                        <div className="text-right">
                          <p className="text-2xl font-bold text-white">
                            {getVotePercentage(poll, option.optionIndex)}%
                          </p>
                          <p className="text-xs text-white/50">{getVoteCount(poll, option.optionIndex)} votes</p>
                        </div>
                      )}
                    </div>
                  </button>
                </div>
              );
            })}
          </div>

          {poll.user_vote !== null && (
            <div className="mt-4 p-3 bg-green-500/10 border border-green-500/30 rounded-lg text-sm text-green-200 flex items-center space-x-2">
              <CheckCircle className="w-4 h-4" />
              <span>You voted for: {findOptionByIndex(poll, poll.user_vote)?.title || 'Unknown option'}</span>
            </div>
          )}

          {!isPollActive(poll) && poll.user_vote === null && (
            <div className="mt-4 p-3 bg-yellow-500/10 border border-yellow-500/30 rounded-lg">
              <div className="flex items-center space-x-2 text-yellow-300 text-sm">
                <Clock className="w-4 h-4" />
                <span>This poll is no longer active</span>
              </div>
            </div>
          )}
        </div>
      ))}
    </div>
  );
};

export default PollVotingInterface;
