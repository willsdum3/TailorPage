import React, { useState, useEffect } from 'react';
import { Bell, X, MessageCircle, Users, Crown, UserPlus, BookOpen, Check, Trash2, Settings } from 'lucide-react';
import { Notification, User as UserType } from '../types';
import { TailorMatesService } from '../services/tailorMatesService';

interface NotificationsPanelProps {
  isOpen: boolean;
  onClose: () => void;
  user: UserType | null;
  onNotificationClick?: (notification: Notification) => void;
}

const NotificationsPanel: React.FC<NotificationsPanelProps> = ({ isOpen, onClose, user, onNotificationClick }) => {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'unread'>('all');

  useEffect(() => {
    if (isOpen && user) {
      loadNotifications();
    }
  }, [isOpen, user]);

  const loadNotifications = async () => {
    if (!user) return;
    
    try {
      setIsLoading(true);
      const notificationsData = await TailorMatesService.getNotifications(50, 0, false);
      setNotifications(notificationsData);
    } catch (error) {
      console.error('Error loading notifications:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleMarkAsRead = async (notificationId: string) => {
    try {
      const result = await TailorMatesService.markNotificationAsRead(notificationId);
      
      if (result.success) {
        setNotifications(prev =>
          prev.map(notif =>
            notif.id === notificationId ? { ...notif, isRead: true } : notif
          )
        );
      }
    } catch (error) {
      console.error('Error marking notification as read:', error);
    }
  };

  const handleMarkAllAsRead = async () => {
    try {
      const result = await TailorMatesService.markAllNotificationsAsRead();
      
      if (result.success) {
        setNotifications(prev =>
          prev.map(notif => ({ ...notif, isRead: true }))
        );
      }
    } catch (error) {
      console.error('Error marking all notifications as read:', error);
    }
  };

  const handleDeleteNotification = async (notificationId: string) => {
    try {
      const result = await TailorMatesService.deleteNotification(notificationId);
      
      if (result.success) {
        setNotifications(prev =>
          prev.filter(notif => notif.id !== notificationId)
        );
      }
    } catch (error) {
      console.error('Error deleting notification:', error);
    }
  };

  const getNotificationIcon = (type: Notification['type']) => {
    switch (type) {
      case 'club_message':
        return <Users className="w-4 h-4 text-blue-400" />;
      case 'discussion_message':
        return <MessageCircle className="w-4 h-4 text-green-400" />;
      case 'friend_message':
        return <MessageCircle className="w-4 h-4 text-pink-400" />;
      case 'club_invitation':
        return <BookOpen className="w-4 h-4 text-purple-400" />;
      case 'friend_request':
        return <UserPlus className="w-4 h-4 text-amber-400" />;
      case 'admin_promotion':
        return <Crown className="w-4 h-4 text-yellow-400" />;
      default:
        return <Bell className="w-4 h-4 text-gray-400" />;
    }
  };

  const filteredNotifications = notifications.filter(notif =>
    filter === 'all' || (filter === 'unread' && !notif.isRead)
  );

  const unreadCount = notifications.filter(notif => !notif.isRead).length;

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-start justify-center pt-20 p-4">
      <div className="bg-slate-900 rounded-2xl border border-white/20 w-full max-w-2xl max-h-[80vh] overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-white/10">
          <div className="flex items-center space-x-3">
            <div className="relative">
              <Bell className="w-6 h-6 text-pink-400" />
              {unreadCount > 0 && (
                <span className="absolute -top-2 -right-2 bg-red-500 text-white text-xs px-2 py-1 rounded-full min-w-[20px] text-center">
                  {unreadCount}
                </span>
              )}
            </div>
            <h2 className="text-2xl font-bold text-white">Notifications</h2>
          </div>
          <button
            onClick={onClose}
            className="p-2 hover:bg-white/10 rounded-lg transition-colors"
          >
            <X className="w-5 h-5 text-white/60" />
          </button>
        </div>

        {/* Filter and Actions */}
        <div className="flex items-center justify-between p-4 border-b border-white/10 bg-white/5">
          <div className="flex space-x-2">
            <button
              onClick={() => setFilter('all')}
              className={`px-3 py-1 rounded-lg text-sm font-medium transition-colors ${
                filter === 'all'
                  ? 'bg-pink-500/20 text-pink-300 border border-pink-500/30'
                  : 'text-white/60 hover:text-white hover:bg-white/10'
              }`}
            >
              All ({notifications.length})
            </button>
            <button
              onClick={() => setFilter('unread')}
              className={`px-3 py-1 rounded-lg text-sm font-medium transition-colors ${
                filter === 'unread'
                  ? 'bg-pink-500/20 text-pink-300 border border-pink-500/30'
                  : 'text-white/60 hover:text-white hover:bg-white/10'
              }`}
            >
              Unread ({unreadCount})
            </button>
          </div>
          
          {unreadCount > 0 && (
            <button
              onClick={handleMarkAllAsRead}
              className="flex items-center space-x-2 text-green-400 hover:text-green-300 text-sm transition-colors"
            >
              <Check className="w-4 h-4" />
              <span>Mark all read</span>
            </button>
          )}
        </div>

        {/* Notifications List */}
        <div className="flex-1 overflow-y-auto max-h-96">
          {isLoading ? (
            <div className="text-center py-12">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-pink-400 mx-auto"></div>
              <p className="text-white/60 mt-2">Loading notifications...</p>
            </div>
          ) : filteredNotifications.length === 0 ? (
            <div className="text-center py-12">
              <Bell className="w-12 h-12 text-white/30 mx-auto mb-4" />
              <p className="text-white/60">
                {filter === 'unread' ? 'No unread notifications' : 'No notifications yet'}
              </p>
              <p className="text-white/40 text-sm mt-1">
                {filter === 'unread' 
                  ? 'You\'re all caught up!' 
                  : 'Notifications will appear here when you receive them'
                }
              </p>
            </div>
          ) : (
            <div className="divide-y divide-white/10">
              {filteredNotifications.map((notification) => {
                const isClickable = (notification.type === 'friend_message' && notification.relatedId) ||
                                   (notification.type === 'friend_request' && notification.relatedId);
                return (
                <div
                  key={notification.id}
                  onClick={(e) => {
                    // Only handle click if not clicking on action buttons
                    const target = e.target as HTMLElement;
                    const isButtonClick = target.closest('button') || target.tagName === 'BUTTON';
                    
                    if (isClickable && onNotificationClick && !isButtonClick) {
                      e.preventDefault();
                      e.stopPropagation();
                      onNotificationClick(notification);
                    }
                  }}
                  className={`p-4 transition-all ${
                    isClickable 
                      ? 'cursor-pointer hover:bg-white/15 active:bg-white/20 hover:shadow-lg' 
                      : 'hover:bg-white/5'
                  } ${
                    !notification.isRead ? 'bg-pink-500/5 border-l-4 border-pink-500/50' : ''
                  }`}
                  role={isClickable ? 'button' : undefined}
                  tabIndex={isClickable ? 0 : undefined}
                  onKeyDown={(e) => {
                    if (isClickable && onNotificationClick && (e.key === 'Enter' || e.key === ' ')) {
                      e.preventDefault();
                      onNotificationClick(notification);
                    }
                  }}
                >
                  <div className="flex items-start space-x-3">
                    <div className="flex-shrink-0 mt-1">
                      {getNotificationIcon(notification.type)}
                    </div>
                    
                    <div className="flex-1 min-w-0">
                      <div className="flex items-start justify-between">
                        <div className="flex-1">
                          <h4 className={`text-sm font-medium ${
                            notification.isRead ? 'text-white/80' : 'text-white'
                          }`}>
                            {notification.title}
                          </h4>
                          <p className={`text-sm mt-1 ${
                            notification.isRead ? 'text-white/60' : 'text-white/80'
                          }`}>
                            {notification.message}
                          </p>
                          {notification.relatedName && (
                            <p className="text-xs text-pink-400 mt-1">
                              {notification.relatedName}
                            </p>
                          )}
                          <p className="text-xs text-white/40 mt-2">
                            {TailorMatesService.formatDate(notification.createdAt)}
                          </p>
                        </div>
                        
                        <div className="flex items-center space-x-1 ml-2" onClick={(e) => e.stopPropagation()}>
                          {!notification.isRead && (
                            <button
                              onClick={() => handleMarkAsRead(notification.id)}
                              className="p-1 text-green-400 hover:text-green-300 transition-colors"
                              title="Mark as read"
                            >
                              <Check className="w-3 h-3" />
                            </button>
                          )}
                          <button
                            onClick={() => handleDeleteNotification(notification.id)}
                            className="p-1 text-red-400 hover:text-red-300 transition-colors"
                            title="Delete notification"
                          >
                            <Trash2 className="w-3 h-3" />
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                );
              })}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="p-4 border-t border-white/10 bg-white/5">
          <button
            onClick={() => {
              // This could open notification settings
              alert('Notification settings coming soon!');
            }}
            className="flex items-center space-x-2 text-white/60 hover:text-white text-sm transition-colors"
          >
            <Settings className="w-4 h-4" />
            <span>Notification Settings</span>
          </button>
        </div>
      </div>
    </div>
  );
};

export default NotificationsPanel;
