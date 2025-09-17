-- =====================================================
-- DEBUG POLL CLEANUP ISSUE
-- =====================================================
-- This script will help us understand why polls aren't being deleted

-- Check current poll status
SELECT 
    'Current Poll Status' as info,
    id,
    title,
    status,
    closes_at,
    created_at,
    CASE 
        WHEN closes_at IS NULL THEN 'No expiration'
        WHEN closes_at > NOW() THEN 'Active'
        WHEN closes_at < NOW() THEN 'Expired'
    END as expiration_status,
    CASE 
        WHEN closes_at IS NOT NULL AND closes_at < NOW() - INTERVAL '24 hours' THEN 'Ready for cleanup'
        WHEN closes_at IS NOT NULL AND closes_at < NOW() THEN 'In grace period'
        ELSE 'Not expired'
    END as cleanup_status,
    EXTRACT(EPOCH FROM (NOW() - closes_at))/3600 as hours_since_expiration
FROM book_club_polls
ORDER BY created_at DESC;

-- Check what the cleanup function is actually looking for
DO $$
DECLARE
    cleanup_threshold TIMESTAMP WITH TIME ZONE;
    polls_to_delete INTEGER;
    sample_poll RECORD;
BEGIN
    RAISE NOTICE '=== DEBUGGING CLEANUP LOGIC ===';
    
    cleanup_threshold := NOW() - INTERVAL '24 hours';
    RAISE NOTICE 'Cleanup threshold: %', cleanup_threshold;
    
    -- Check what polls match the cleanup criteria
    SELECT COUNT(*) INTO polls_to_delete
    FROM book_club_polls
    WHERE status = 'active' 
    AND closes_at IS NOT NULL 
    AND closes_at < cleanup_threshold;
    
    RAISE NOTICE 'Polls matching cleanup criteria (status=active AND expired >24h): %', polls_to_delete;
    
    -- Check what polls match if we include 'closed' status
    SELECT COUNT(*) INTO polls_to_delete
    FROM book_club_polls
    WHERE status IN ('active', 'closed')
    AND closes_at IS NOT NULL 
    AND closes_at < cleanup_threshold;
    
    RAISE NOTICE 'Polls matching if we include closed status: %', polls_to_delete;
    
    -- Show sample polls that should be deleted
    FOR sample_poll IN 
        SELECT id, title, status, closes_at,
               EXTRACT(EPOCH FROM (NOW() - closes_at))/3600 as hours_expired
        FROM book_club_polls
        WHERE closes_at IS NOT NULL 
        AND closes_at < cleanup_threshold
        LIMIT 5
    LOOP
        RAISE NOTICE 'Poll ready for cleanup: % (status: %, expired %.1f hours ago)', 
            sample_poll.title, sample_poll.status, sample_poll.hours_expired;
    END LOOP;
END $$;

-- Test manual deletion of a specific poll (if any exist)
DO $$
DECLARE
    test_poll_id UUID;
    deleted_votes INTEGER;
    deleted_polls INTEGER;
BEGIN
    RAISE NOTICE '=== TESTING MANUAL DELETION ===';
    
    -- Find a poll that should be deleted
    SELECT id INTO test_poll_id
    FROM book_club_polls
    WHERE closes_at IS NOT NULL 
    AND closes_at < NOW() - INTERVAL '24 hours'
    LIMIT 1;
    
    IF test_poll_id IS NOT NULL THEN
        RAISE NOTICE 'Found test poll to delete: %', test_poll_id;
        
        -- Count associated votes
        SELECT COUNT(*) INTO deleted_votes
        FROM book_club_poll_votes
        WHERE poll_id = test_poll_id;
        
        RAISE NOTICE 'Poll has % votes that will be deleted', deleted_votes;
        
        -- Delete votes first
        DELETE FROM book_club_poll_votes WHERE poll_id = test_poll_id;
        
        -- Delete poll
        DELETE FROM book_club_polls WHERE id = test_poll_id;
        
        GET DIAGNOSTICS deleted_polls = ROW_COUNT;
        
        RAISE NOTICE 'Successfully deleted poll and % votes', deleted_votes;
    ELSE
        RAISE NOTICE 'No polls found that meet deletion criteria';
    END IF;
END $$;

-- Show final status
SELECT 
    'After Manual Test' as info,
    COUNT(*) as remaining_polls,
    COUNT(*) FILTER (WHERE status = 'closed') as closed_polls,
    COUNT(*) FILTER (WHERE status = 'active') as active_polls
FROM book_club_polls;
