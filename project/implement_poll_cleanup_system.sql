-- =====================================================
-- IMPLEMENT POLL CLEANUP SYSTEM
-- =====================================================
-- This script implements automatic cleanup of expired polls after 24 hours

-- First, let's check the current state of polls
DO $$
DECLARE
    total_polls INTEGER;
    active_polls INTEGER;
    expired_polls INTEGER;
    polls_to_cleanup INTEGER;
    sample_poll RECORD;
BEGIN
    RAISE NOTICE '=== CURRENT POLLS STATUS ===';
    
    SELECT COUNT(*) INTO total_polls FROM book_club_polls;
    RAISE NOTICE 'Total polls in database: %', total_polls;
    
    SELECT COUNT(*) INTO active_polls 
    FROM book_club_polls 
    WHERE status = 'active' AND (closes_at IS NULL OR closes_at > NOW());
    RAISE NOTICE 'Currently active polls: %', active_polls;
    
    SELECT COUNT(*) INTO expired_polls 
    FROM book_club_polls 
    WHERE status = 'active' AND closes_at IS NOT NULL AND closes_at < NOW();
    RAISE NOTICE 'Expired but not cleaned polls: %', expired_polls;
    
    SELECT COUNT(*) INTO polls_to_cleanup 
    FROM book_club_polls 
    WHERE status = 'active' 
    AND closes_at IS NOT NULL 
    AND closes_at < NOW() - INTERVAL '24 hours';
    RAISE NOTICE 'Polls ready for cleanup (expired >24h): %', polls_to_cleanup;
    
    -- Show sample expired polls
    IF polls_to_cleanup > 0 THEN
        RAISE NOTICE 'Sample polls to cleanup:';
        FOR sample_poll IN 
            SELECT id, title, closes_at, 
                   EXTRACT(EPOCH FROM (NOW() - closes_at))/3600 as hours_expired
            FROM book_club_polls 
            WHERE status = 'active' 
            AND closes_at IS NOT NULL 
            AND closes_at < NOW() - INTERVAL '24 hours'
            LIMIT 5
        LOOP
            RAISE NOTICE '  Poll: % (expired %.1f hours ago)', sample_poll.title, sample_poll.hours_expired;
        END LOOP;
    END IF;
END $$;

-- Function to clean up expired polls (24+ hours after expiration)
CREATE OR REPLACE FUNCTION cleanup_expired_polls()
RETURNS JSON AS $$
DECLARE
    deleted_polls INTEGER := 0;
    deleted_votes INTEGER := 0;
    cleanup_threshold TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Set cleanup threshold: 24 hours after expiration
    cleanup_threshold := NOW() - INTERVAL '24 hours';
    
    -- Count votes that will be deleted (for reporting)
    SELECT COUNT(*) INTO deleted_votes
    FROM book_club_poll_votes v
    JOIN book_club_polls p ON v.poll_id = p.id
    WHERE p.status = 'active' 
    AND p.closes_at IS NOT NULL 
    AND p.closes_at < cleanup_threshold;
    
    -- Delete votes first (due to foreign key constraints)
    DELETE FROM book_club_poll_votes
    WHERE poll_id IN (
        SELECT id FROM book_club_polls 
        WHERE status = 'active' 
        AND closes_at IS NOT NULL 
        AND closes_at < cleanup_threshold
    );
    
    -- Delete the expired polls
    DELETE FROM book_club_polls
    WHERE status = 'active' 
    AND closes_at IS NOT NULL 
    AND closes_at < cleanup_threshold;
    
    GET DIAGNOSTICS deleted_polls = ROW_COUNT;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Poll cleanup completed',
        'deleted_polls', deleted_polls,
        'deleted_votes', deleted_votes,
        'cleanup_threshold', cleanup_threshold
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Cleanup failed: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark polls as closed when they expire (without deleting)
CREATE OR REPLACE FUNCTION close_expired_polls()
RETURNS JSON AS $$
DECLARE
    closed_polls INTEGER := 0;
BEGIN
    -- Mark expired polls as closed
    UPDATE book_club_polls
    SET status = 'closed', updated_at = NOW()
    WHERE status = 'active' 
    AND closes_at IS NOT NULL 
    AND closes_at < NOW();
    
    GET DIAGNOSTICS closed_polls = ROW_COUNT;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Expired polls closed',
        'closed_polls', closed_polls
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Failed to close polls: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get poll cleanup statistics
CREATE OR REPLACE FUNCTION get_poll_cleanup_stats()
RETURNS JSON AS $$
DECLARE
    stats JSON;
BEGIN
    SELECT json_build_object(
        'total_polls', (SELECT COUNT(*) FROM book_club_polls),
        'active_polls', (SELECT COUNT(*) FROM book_club_polls WHERE status = 'active'),
        'closed_polls', (SELECT COUNT(*) FROM book_club_polls WHERE status = 'closed'),
        'expired_active_polls', (
            SELECT COUNT(*) FROM book_club_polls 
            WHERE status = 'active' AND closes_at IS NOT NULL AND closes_at < NOW()
        ),
        'polls_ready_for_cleanup', (
            SELECT COUNT(*) FROM book_club_polls 
            WHERE status = 'active' 
            AND closes_at IS NOT NULL 
            AND closes_at < NOW() - INTERVAL '24 hours'
        ),
        'total_votes', (SELECT COUNT(*) FROM book_club_poll_votes)
    ) INTO stats;
    
    RETURN stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION cleanup_expired_polls TO authenticated;
GRANT EXECUTE ON FUNCTION close_expired_polls TO authenticated;
GRANT EXECUTE ON FUNCTION get_poll_cleanup_stats TO authenticated;

-- Run initial cleanup of existing expired polls
DO $$
DECLARE
    cleanup_result JSON;
    close_result JSON;
BEGIN
    RAISE NOTICE '=== RUNNING INITIAL CLEANUP ===';
    
    -- First close any expired polls
    SELECT close_expired_polls() INTO close_result;
    RAISE NOTICE 'Close expired polls result: %', close_result;
    
    -- Then cleanup polls that have been expired for 24+ hours
    SELECT cleanup_expired_polls() INTO cleanup_result;
    RAISE NOTICE 'Cleanup result: %', cleanup_result;
    
    RAISE NOTICE '=== CLEANUP COMPLETE ===';
END $$;

-- Show final statistics
SELECT 'Final Poll Statistics' as info, get_poll_cleanup_stats() as stats;

-- Create a simple function that can be called regularly to maintain poll hygiene
CREATE OR REPLACE FUNCTION maintain_poll_hygiene()
RETURNS JSON AS $$
DECLARE
    close_result JSON;
    cleanup_result JSON;
    final_stats JSON;
BEGIN
    -- Step 1: Close expired polls
    SELECT close_expired_polls() INTO close_result;
    
    -- Step 2: Cleanup polls expired for 24+ hours
    SELECT cleanup_expired_polls() INTO cleanup_result;
    
    -- Step 3: Get final statistics
    SELECT get_poll_cleanup_stats() INTO final_stats;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Poll maintenance completed',
        'close_result', close_result,
        'cleanup_result', cleanup_result,
        'final_stats', final_stats
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Poll maintenance failed: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION maintain_poll_hygiene TO authenticated;

-- Final status
DO $$
BEGIN
    RAISE NOTICE '=== POLL CLEANUP SYSTEM DEPLOYED ===';
    RAISE NOTICE '✅ Created cleanup_expired_polls() - Deletes polls expired >24h';
    RAISE NOTICE '✅ Created close_expired_polls() - Marks expired polls as closed';
    RAISE NOTICE '✅ Created get_poll_cleanup_stats() - Shows poll statistics';
    RAISE NOTICE '✅ Created maintain_poll_hygiene() - Complete maintenance function';
    RAISE NOTICE '';
    RAISE NOTICE '🔄 Automatic cleanup process:';
    RAISE NOTICE '1. Polls expire at closes_at timestamp';
    RAISE NOTICE '2. Expired polls are marked as "closed" status';
    RAISE NOTICE '3. After 24 hours, closed polls are deleted completely';
    RAISE NOTICE '4. Users have 24h to review results before deletion';
    RAISE NOTICE '';
    RAISE NOTICE '⚡ To run regular maintenance, call: SELECT maintain_poll_hygiene();';
    RAISE NOTICE '📊 To check statistics, call: SELECT get_poll_cleanup_stats();';
END $$;
