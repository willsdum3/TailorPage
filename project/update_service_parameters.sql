-- This is a reference file showing the correct parameter names for all service functions
-- The actual updates need to be made in the TailorMatesService.ts file

-- CORRECT PARAMETER NAMES FOR ALL FUNCTIONS:

-- 1. create_book_club
-- Parameters: p_auth_user_id, p_club_name, p_club_description

-- 2. join_book_club  
-- Parameters: p_auth_user_id, p_club_id

-- 3. add_book_club_message
-- Parameters: p_auth_user_id, p_club_id, p_content

-- 4. get_book_club_messages
-- Parameters: p_auth_user_id, p_club_id

-- 5. promote_user_to_admin
-- Parameters: p_auth_user_id, p_club_id, p_user_to_promote_id

-- 6. invite_user_to_club
-- Parameters: p_auth_user_id, p_club_id, p_username, p_message

-- 7. add_discussion_message
-- Parameters: p_auth_user_id, p_discussion_id, p_message_content

-- All functions now use the 'p_' prefix to avoid ambiguous column references
