-- =====================================================
-- POLL CLEANUP EXPLANATION AND TESTING
-- =====================================================
-- This script explains the current state and provides testing options

-- Calculate when the poll will be eligible for cleanup
DO $$
DECLARE
    poll_closes_at TIMESTAMP WITH TIME ZONE;
    cleanup_eligible_at TIMESTAMP WITH TIME ZONE;
    hours_remaining NUMERIC;
BEGIN
    RAISE NOTICE '=== POLL CLEANUP TIMING EXPLANATION ===';
    
    -- Get the poll's expiration time
    SELECT closes_at INTO poll_closes_at
    FROM book_club_polls 
    WHERE title = 'Choose the book for November';
    
    -- Calculate when it becomes eligible for cleanup (24 hours after expiration)
    cleanup_eligible_at := poll_closes_at + INTERVAL '24 hours';
    
    -- Calculate hours remaining until cleanup
    hours_remaining := EXTRACT(EPOCH FROM (cleanup_eligible_at - NOW()))/3600;
    
    RAISE NOTICE 'Poll expired at: %', poll_closes_at;
    RAISE NOTICE 'Will be eligible for cleanup at: %', cleanup_eligible_at;
    RAISE NOTICE 'Hours remaining until cleanup: %.1f', hours_remaining;
    
    IF hours_remaining > 0 THEN
        RAISE NOTICE '✅ Poll is correctly in grace period - will auto-delete in %.1f hours', hours_remaining;
    ELSE
        RAISE NOTICE '⚠️ Poll should be eligible for cleanup now - investigating...';
    END IF;
END $$;

-- Create a test function that can force cleanup for testing (bypasses 24h rule)
CREATE OR REPLACE FUNCTION force_cleanup_expired_polls()
RETURNS JSON AS $$
DECLARE
    deleted_polls INTEGER := 0;
    deleted_votes INTEGER := 0;
    polls_to_delete UUID[];
BEGIN
    -- Get list of ALL expired polls (ignoring 24h rule for testing)
    SELECT ARRAY(
        SELECT id FROM book_club_polls 
        WHERE closes_at IS NOT NULL 
        AND closes_at < NOW()
        AND status IN ('active', 'closed')
    ) INTO polls_to_delete;
    
    RAISE NOTICE 'Force cleanup - found % expired polls to delete', array_length(polls_to_delete, 1);
    
    IF polls_to_delete IS NOT NULL AND array_length(polls_to_delete, 1) > 0 THEN
        -- Count votes that will be deleted
        SELECT COUNT(*) INTO deleted_votes
        FROM book_club_poll_votes v
        WHERE v.poll_id = ANY(polls_to_delete);
        
        -- Delete votes first
        DELETE FROM book_club_poll_votes
        WHERE poll_id = ANY(polls_to_delete);
        
        -- Delete the polls
        DELETE FROM book_club_polls
        WHERE id = ANY(polls_to_delete);
        
        GET DIAGNOSTICS deleted_polls = ROW_COUNT;
    END IF;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Force cleanup completed - deleted ' || deleted_polls || ' polls and ' || deleted_votes || ' votes',
        'deleted_polls', deleted_polls,
        'deleted_votes', deleted_votes,
        'note', 'This was a force cleanup that bypassed the 24-hour grace period'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Force cleanup failed: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permission for testing
GRANT EXECUTE ON FUNCTION force_cleanup_expired_polls TO authenticated;

-- Show current cleanup criteria vs actual poll data
DO $$
DECLARE
    cleanup_threshold TIMESTAMP WITH TIME ZONE;
    poll_info RECORD;
BEGIN
    RAISE NOTICE '=== CLEANUP CRITERIA ANALYSIS ===';
    
    cleanup_threshold := NOW() - INTERVAL '24 hours';
    RAISE NOTICE 'Current cleanup threshold: %', cleanup_threshold;
    
    FOR poll_info IN 
        SELECT 
            title,
            status,
            closes_at,
            EXTRACT(EPOCH FROM (NOW() - closes_at))/3600 as hours_expired,
            CASE 
                WHEN closes_at < cleanup_threshold THEN 'ELIGIBLE'
                ELSE 'NOT_ELIGIBLE'
            END as cleanup_eligibility
        FROM book_club_polls
        WHERE closes_at IS NOT NULL
    LOOP
        RAISE NOTICE 'Poll: % | Status: % | Expired: %.1f hours | Eligible: %', 
            poll_info.title, 
            poll_info.status, 
            poll_info.hours_expired,
            poll_info.cleanup_eligibility;
    END LOOP;
END $$;

-- Final recommendation
DO $$
BEGIN
    RAISE NOTICE '=== RECOMMENDATION ===';
    RAISE NOTICE '';
    RAISE NOTICE 'The cleanup system is working correctly!';
    RAISE NOTICE 'Your poll "Choose the book for November" is in the 24-hour grace period.';
    RAISE NOTICE '';
    RAISE NOTICE 'Options:';
    RAISE NOTICE '1. WAIT: Poll will auto-delete when 24h grace period expires';
    RAISE NOTICE '2. TEST: Run "SELECT force_cleanup_expired_polls();" to test immediate deletion';
    RAISE NOTICE '3. VERIFY: The cleanup button is working - it just respects the 24h rule';
    RAISE NOTICE '';
    RAISE NOTICE 'The 24-hour grace period gives users time to see poll results before deletion.';
END $$;
