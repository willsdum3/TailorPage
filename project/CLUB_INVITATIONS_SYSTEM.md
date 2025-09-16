# 🎯 Club Invitations System

## Overview

The Club Invitations System allows book club administrators to invite users by their username to join their clubs. This feature enhances the social aspect of Tailor Mates by enabling targeted invitations and streamlined club growth.

## ✨ Features

### For Club Admins (Owners & Admins)
- **🔍 Username Search**: Search for users by username with real-time results
- **📧 Send Invitations**: Invite users with optional personal messages
- **📊 Invitation Management**: View all sent invitations with status tracking
- **📈 Statistics**: Track invitation success rates and engagement
- **⏰ Expiration Handling**: Automatic cleanup of expired invitations

### For Users
- **🔔 Real-time Notifications**: See pending invitations on the Tailor Mates page
- **💬 Personal Messages**: Read personal messages from inviters
- **✅ Accept/Decline**: Respond to invitations with one-click actions
- **⚡ Instant Joining**: Automatic club membership upon acceptance

## 🏗️ Architecture

### Database Schema

#### `club_invitations` Table
```sql
- id: UUID (Primary Key)
- club_id: UUID (Foreign Key to book_clubs)
- inviter_id: UUID (Foreign Key to users)
- invitee_id: UUID (Foreign Key to users)
- status: TEXT ('pending', 'accepted', 'declined', 'cancelled')
- message: TEXT (Optional personal message)
- created_at: TIMESTAMP
- updated_at: TIMESTAMP
- expires_at: TIMESTAMP (Default: 7 days from creation)
```

#### Key Constraints
- Unique constraint on (club_id, invitee_id) - prevents duplicate invitations
- Check constraint to prevent self-invitations
- Foreign key cascading deletes for data integrity

### Database Functions

#### `search_users_by_username(search_term, limit_count)`
- Searches users by username with intelligent ranking
- Exact matches first, then starts-with, then contains
- Case-insensitive search with configurable limits

#### `invite_user_to_club(auth_user_id, club_id, username, message)`
- Validates admin permissions
- Checks for existing memberships and pending invitations
- Creates invitation with optional personal message
- Returns detailed success/error responses

#### `get_user_club_invitations(auth_user_id)`
- Retrieves pending invitations for a user
- Includes club details and inviter information
- Filters out expired invitations

#### `respond_to_club_invitation(auth_user_id, invitation_id, response)`
- Processes acceptance or decline responses
- Automatically adds user to club on acceptance
- Updates invitation status and timestamps

#### `get_club_sent_invitations(auth_user_id, club_id)`
- Admin-only function to view sent invitations
- Includes invitation status and recipient details
- Ordered by creation date (newest first)

#### `cleanup_expired_invitations()`
- Utility function to remove expired pending invitations
- Returns count of cleaned up invitations
- Can be run periodically via cron jobs

## 🎨 UI Components

### `InviteUserModal`
**Location**: `src/components/InviteUserModal.tsx`

- **Search Interface**: Real-time username search with debouncing
- **User Selection**: Visual user cards with avatars and names
- **Message Input**: Optional personal message textarea
- **Feedback System**: Success/error messages with icons
- **Loading States**: Spinner animations during operations

**Key Features**:
- Debounced search (300ms delay)
- Input validation and error handling
- Responsive design with mobile support
- Accessibility features (ARIA labels, keyboard navigation)

### `ClubInvitationsManager`
**Location**: `src/components/ClubInvitationsManager.tsx`

- **Admin Dashboard**: Overview of all sent invitations
- **Status Tracking**: Visual status indicators with colors
- **Statistics Cards**: Success rates and engagement metrics
- **Refresh Controls**: Manual refresh with loading indicators

**Key Features**:
- Admin-only visibility
- Real-time status updates
- Responsive grid layout
- Empty state handling

### `ClubInvitationsNotifications`
**Location**: `src/components/ClubInvitationsNotifications.tsx`

- **Notification Cards**: Rich invitation display with club details
- **Personal Messages**: Highlighted personal messages from inviters
- **Action Buttons**: Accept/Decline with loading states
- **Expiration Warnings**: Visual indicators for expiring invitations

**Key Features**:
- Auto-refresh after responses
- Responsive card layout
- Smooth animations and transitions
- Error handling with user feedback

## 🚀 Integration

### BookClubDetailPage Integration
- Added "Invitations" tab for club admins
- Integrated `ClubInvitationsManager` component
- Tab visibility based on user admin status
- Seamless navigation between club features

### TailorMatesPage Integration
- Added `ClubInvitationsNotifications` at the top of the page
- Automatic data refresh after invitation responses
- Conditional rendering based on user authentication
- Non-intrusive display (only shows when invitations exist)

## 🔒 Security

### Row Level Security (RLS)
All database operations are protected by comprehensive RLS policies:

#### View Permissions
- Users can only view invitations they sent or received
- No access to other users' invitation data

#### Create Permissions
- Only club admins (owner/admin roles) can create invitations
- Automatic validation of admin status

#### Update Permissions
- Users can update invitations they're involved in
- Status changes logged with timestamps

#### Delete Permissions
- Only invitation senders can delete their invitations
- Prevents unauthorized invitation management

### Function Security
All database functions use `SECURITY DEFINER` with proper validation:
- Authentication checks for all operations
- Admin permission validation for privileged functions
- Input sanitization and type validation
- Comprehensive error handling

## 📋 Deployment Guide

### Prerequisites
- Tailor Mates main system must be deployed
- Required tables: `book_clubs`, `club_memberships`, `users`
- PostgreSQL with UUID extension enabled

### Deployment Steps

1. **Deploy Database Schema**
   ```sql
   -- Run in Supabase SQL Editor
   -- Copy contents of deploy_invitations_system.sql
   ```

2. **Verify Deployment**
   - Check that `club_invitations` table exists
   - Verify all functions are created
   - Test RLS policies are active

3. **Frontend Integration**
   - Components are already integrated
   - No additional configuration needed
   - Automatic feature activation

### Environment Requirements
- Supabase project with RLS enabled
- Authenticated user sessions
- Existing Tailor Mates user base

## 🧪 Testing

### Manual Testing Checklist

#### Admin Functions
- [ ] Search for users by username
- [ ] Send invitations with and without messages
- [ ] View sent invitations dashboard
- [ ] Check invitation statistics
- [ ] Verify admin-only access to invitation features

#### User Functions
- [ ] Receive invitation notifications
- [ ] Accept invitations and verify club membership
- [ ] Decline invitations and verify status update
- [ ] Check expiration warnings work correctly

#### Edge Cases
- [ ] Duplicate invitation prevention
- [ ] Full club invitation handling
- [ ] Expired invitation cleanup
- [ ] Invalid username handling
- [ ] Permission boundary testing

### Automated Testing
Consider adding tests for:
- Database function behavior
- Component rendering and interactions
- Permission and security validations
- Error handling and edge cases

## 🔧 Maintenance

### Regular Tasks
1. **Monitor Invitation Success Rates**
   - Track acceptance/decline ratios
   - Identify popular clubs and active inviters

2. **Clean Up Expired Invitations**
   ```sql
   SELECT cleanup_expired_invitations();
   ```

3. **Performance Monitoring**
   - Monitor search query performance
   - Check index usage and optimization opportunities

### Troubleshooting

#### Common Issues

**"Only club admins can send invitations"**
- Verify user has 'owner' or 'admin' role in club_memberships table
- Check RLS policies are correctly applied

**"User not found with username"**
- Verify username exists in users table
- Check for exact spelling and case sensitivity

**Search not returning results**
- Verify users have non-null, non-empty usernames
- Check database connection and function permissions

**Invitations not appearing**
- Verify invitations haven't expired
- Check user authentication status
- Confirm invitation status is 'pending'

## 🚀 Future Enhancements

### Planned Features
- **📱 Email Notifications**: Send email alerts for new invitations
- **🔔 Push Notifications**: Real-time browser notifications
- **📊 Analytics Dashboard**: Detailed invitation analytics for admins
- **🎯 Bulk Invitations**: Invite multiple users at once
- **📝 Invitation Templates**: Pre-written invitation messages
- **🔄 Invitation Reminders**: Remind users about pending invitations

### Technical Improvements
- **⚡ Caching**: Redis cache for search results
- **🔍 Advanced Search**: Search by name, interests, or reading preferences
- **📱 Mobile App**: Native mobile app integration
- **🌐 Internationalization**: Multi-language support

## 📚 API Reference

### TypeScript Interfaces

```typescript
interface ClubInvitation {
  id: string;
  clubId: string;
  clubName: string;
  clubDescription: string;
  inviterName: string;
  inviterUsername: string;
  message?: string;
  createdAt: string;
  expiresAt: string;
  status: 'pending' | 'accepted' | 'declined' | 'cancelled';
}

interface UserSearchResult {
  id: string;
  username: string;
  name: string;
  avatarUrl?: string;
}

interface SentInvitation {
  id: string;
  inviteeUsername: string;
  inviteeName: string;
  message?: string;
  status: 'pending' | 'accepted' | 'declined' | 'cancelled';
  createdAt: string;
  expiresAt: string;
}
```

### Service Methods

```typescript
// Search users by username
TailorMatesService.searchUsersByUsername(searchTerm: string): Promise<UserSearchResult[]>

// Send invitation
TailorMatesService.inviteUserToClub(clubId: string, username: string, message?: string): Promise<{success: boolean; message: string}>

// Get user's invitations
TailorMatesService.getUserClubInvitations(): Promise<ClubInvitation[]>

// Respond to invitation
TailorMatesService.respondToClubInvitation(invitationId: string, response: 'accepted' | 'declined'): Promise<{success: boolean; message: string}>

// Get sent invitations (admin only)
TailorMatesService.getClubSentInvitations(clubId: string): Promise<SentInvitation[]>

// Check admin status
TailorMatesService.isClubAdmin(clubId: string): Promise<boolean>
```

---

**🎉 The Club Invitations System is now ready to enhance your Tailor Mates experience!**

For questions or issues, please check the troubleshooting section or contact the development team.
