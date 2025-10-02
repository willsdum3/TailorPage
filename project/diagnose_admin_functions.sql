-- Diagnose current state of admin functions

-- 1. Check if functions exist and their signatures
SELECT 
    'Function Existence Check' as check_type,
    routine_name,
    routine_type,
    data_type as return_type,
    specific_name
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name IN ('promote_user_to_admin', 'invite_user_to_club')
ORDER BY routine_name, specific_name;

-- 2. Check function parameters
SELECT 
    'promote_user_to_admin Parameters' as check_type,
    parameter_name,
    data_type,
    ordinal_position,
    specific_name
FROM information_schema.parameters 
WHERE specific_schema = 'public'
AND specific_name IN (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_schema = 'public' 
    AND routine_name = 'promote_user_to_admin'
)
ORDER BY specific_name, ordinal_position;

SELECT 
    'invite_user_to_club Parameters' as check_type,
    parameter_name,
    data_type,
    ordinal_position,
    specific_name
FROM information_schema.parameters 
WHERE specific_schema = 'public'
AND specific_name IN (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_schema = 'public' 
    AND routine_name = 'invite_user_to_club'
)
ORDER BY specific_name, ordinal_position;

-- 3. Check club_invitations table structure
SELECT 
    'club_invitations Table Structure' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public'
AND table_name = 'club_invitations'
ORDER BY ordinal_position;

-- 4. Check if there are any triggers on club_invitations that might be causing the "invited_by" error
SELECT 
    'club_invitations Triggers' as check_type,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table = 'club_invitations';

-- 5. Check for any functions that might be called by triggers
SELECT 
    'Functions with invited_by references' as check_type,
    routine_name,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_definition ILIKE '%invited_by%';

-- 6. List ALL functions that contain "invite" or "promote" in their names
SELECT 
    'All Invite/Promote Functions' as check_type,
    routine_name,
    routine_type,
    data_type as return_type,
    specific_name
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND (routine_name ILIKE '%invite%' OR routine_name ILIKE '%promote%')
ORDER BY routine_name, specific_name;
