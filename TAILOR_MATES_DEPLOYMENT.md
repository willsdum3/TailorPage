# Tailor Mates Deployment Guide

## Issue
You're getting "Failed to create book club. Please try again." error when trying to create a book club in Tailor Mates.

## Root Cause
The Tailor Mates database tables and functions haven't been deployed to your Supabase database yet.

## Solution

### Option 1: Manual Deployment (Recommended)

1. **Go to your Supabase Dashboard**
   - Navigate to your Supabase project
   - Go to the SQL Editor

2. **Deploy the Schema**
   - Copy the entire contents of `tailor_mates_schema.sql`
   - Paste it into the SQL Editor
   - Click "Run" to execute

3. **Deploy the Functions**
   - Copy the entire contents of `tailor_mates_functions.sql`
   - Paste it into the SQL Editor
   - Click "Run" to execute

4. **Verify Deployment**
   - Go to the "Table Editor" in your Supabase dashboard
   - You should see these new tables:
     - `book_clubs`
     - `club_memberships`
     - `discussions`
     - `discussion_messages`
     - `discussion_participants`
     - `friend_connections`
     - `friend_recommendations`

### Option 2: Automated Deployment

If you have PowerShell available, you can run:

```powershell
.\deploy_tailor_mates.ps1
```

This script will automatically deploy the schema and functions using your Supabase credentials from the `.env` file.

## What Gets Deployed

### Tables
- **book_clubs**: Stores book club information
- **club_memberships**: Tracks club membership
- **discussions**: Stores discussion threads
- **discussion_messages**: Stores individual messages
- **discussion_participants**: Tracks discussion participation
- **friend_connections**: Manages friend relationships
- **friend_recommendations**: Stores friend suggestions

### Functions
- **create_book_club()**: Creates new book clubs
- **get_book_clubs()**: Retrieves book clubs
- **join_book_club()**: Joins a book club
- **leave_book_club()**: Leaves a book club
- **create_discussion()**: Creates new discussions
- **get_discussions()**: Retrieves discussions
- **send_friend_request()**: Sends friend requests
- **accept_friend_request()**: Accepts friend requests
- **generate_friend_recommendations()**: Generates friend suggestions

## After Deployment

1. **Restart your development server** if it's running
2. **Try creating a book club again**
3. **Check the browser console** for any remaining errors

## Troubleshooting

### If you still get errors:

1. **Check the browser console** for specific error messages
2. **Verify your user exists** in the `users` table
3. **Check RLS policies** are enabled for the new tables
4. **Ensure your Supabase credentials** are correct in `.env`

### Common Issues:

- **"User not found"**: Your user record doesn't exist in the database
- **"Function not found"**: The functions weren't deployed correctly
- **"Table not found"**: The tables weren't created

## Support

If you continue to have issues after following this guide, please check:
1. The browser console for detailed error messages
2. Your Supabase dashboard for any SQL execution errors
3. That all tables and functions are present in your database
