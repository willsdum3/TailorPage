-- =====================================================
-- DEBUG MANUAL CLEANUP BUTTON ISSUE
-- =====================================================
-- This script will help us understand exactly what happens when cleanup is triggered

-- First, let's see the current state of polls
SELECT 
    'Current Polls Before Cleanup' as info,
    COUNT(*) as total_polls,
    COUNT(*) FILTER (WHERE status = 'active') as active_polls,
    COUNT(*) FILTER (WHERE status = 'closed') as closed_polls,
    COUNT(*) FILTER (WHERE closes_at IS NOT NULL AND closes_at < NOW()) as expired_polls,
    COUNT(*) FILTER (WHERE closes_at IS NOT NULL AND closes_at < NOW() - INTERVAL '24 hours') as cleanup_ready_polls
FROM book_club_polls;

-- Show detailed poll information
SELECT 
    'Detailed Poll Info' as info,
    id,
    title,
    status,
    closes_at,
    created_at,
    CASE 
        WHEN closes_at IS NULL THEN 'No expiration'
        WHEN closes_at > NOW() THEN 'Still active'
        WHEN closes_at < NOW() - INTERVAL '24 hours' THEN 'Ready for cleanup'
        WHEN closes_at < NOW() THEN 'In grace period'
    END as cleanup_status,
    ROUND(EXTRACT(EPOCH FROM (NOW() - closes_at))/3600, 1) as hours_since_expiration
FROM book_club_polls
ORDER BY created_at DESC;

-- Test the cleanup function step by step
DO $$
DECLARE
    cleanup_threshold TIMESTAMP WITH TIME ZONE;
    polls_to_delete UUID[];
    poll_count INTEGER;
    vote_count INTEGER;
    test_result JSON;
BEGIN
    RAISE NOTICE '=== TESTING CLEANUP FUNCTION STEP BY STEP ===';
    
    -- Calculate cleanup threshold
    cleanup_threshold := NOW() - INTERVAL '24 hours';
    RAISE NOTICE 'Cleanup threshold: %', cleanup_threshold;
    
    -- Find polls that should be deleted
    SELECT ARRAY(
        SELECT id FROM book_club_polls 
        WHERE closes_at IS NOT NULL 
        AND closes_at < cleanup_threshold
        AND status IN ('active', 'closed')
    ) INTO polls_to_delete;
    
    poll_count := COALESCE(array_length(polls_to_delete, 1), 0);
    RAISE NOTICE 'Polls that should be deleted: %', poll_count;
    
    IF poll_count > 0 THEN
        -- Show which polls will be deleted
        FOR i IN 1..poll_count LOOP
            RAISE NOTICE 'Poll to delete: %', polls_to_delete[i];
        END LOOP;
        
        -- Count associated votes
        SELECT COUNT(*) INTO vote_count
        FROM book_club_poll_votes
        WHERE poll_id = ANY(polls_to_delete);
        
        RAISE NOTICE 'Associated votes to delete: %', vote_count;
    END IF;
    
    -- Now test the actual cleanup function
    RAISE NOTICE 'Calling cleanup_expired_polls()...';
    SELECT cleanup_expired_polls() INTO test_result;
    RAISE NOTICE 'Cleanup function result: %', test_result;
    
END $$;

-- Check polls after cleanup attempt
SELECT 
    'Polls After Cleanup Attempt' as info,
    COUNT(*) as total_polls,
    COUNT(*) FILTER (WHERE status = 'active') as active_polls,
    COUNT(*) FILTER (WHERE status = 'closed') as closed_polls
FROM book_club_polls;

-- Show remaining polls
SELECT 
    'Remaining Polls After Cleanup' as info,
    id,
    title,
    status,
    closes_at,
    CASE 
        WHEN closes_at IS NULL THEN 'No expiration'
        WHEN closes_at > NOW() THEN 'Still active'
        WHEN closes_at < NOW() - INTERVAL '24 hours' THEN 'Should be deleted'
        WHEN closes_at < NOW() THEN 'In grace period'
    END as should_be_status
FROM book_club_polls
ORDER BY created_at DESC;
