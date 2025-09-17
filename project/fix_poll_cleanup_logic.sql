-- =====================================================
-- FIX POLL CLEANUP LOGIC
-- =====================================================
-- This script fixes the poll cleanup to handle both active and closed expired polls

-- Drop and recreate the cleanup function with corrected logic
DROP FUNCTION IF EXISTS cleanup_expired_polls();
DROP FUNCTION IF EXISTS maintain_poll_hygiene();

-- Fixed cleanup function that handles both active and closed polls
CREATE OR REPLACE FUNCTION cleanup_expired_polls()
RETURNS JSON AS $$
DECLARE
    deleted_polls INTEGER := 0;
    deleted_votes INTEGER := 0;
    cleanup_threshold TIMESTAMP WITH TIME ZONE;
    polls_to_delete UUID[];
BEGIN
    -- Set cleanup threshold: 24 hours after expiration
    cleanup_threshold := NOW() - INTERVAL '24 hours';
    
    RAISE NOTICE 'Cleanup threshold: %', cleanup_threshold;
    
    -- Get list of polls to delete (both active and closed that are expired >24h)
    SELECT ARRAY(
        SELECT id FROM book_club_polls 
        WHERE closes_at IS NOT NULL 
        AND closes_at < cleanup_threshold
        AND status IN ('active', 'closed')
    ) INTO polls_to_delete;
    
    RAISE NOTICE 'Found % polls to delete', array_length(polls_to_delete, 1);
    
    IF polls_to_delete IS NOT NULL AND array_length(polls_to_delete, 1) > 0 THEN
        -- Count votes that will be deleted (for reporting)
        SELECT COUNT(*) INTO deleted_votes
        FROM book_club_poll_votes v
        WHERE v.poll_id = ANY(polls_to_delete);
        
        RAISE NOTICE 'Will delete % votes', deleted_votes;
        
        -- Delete votes first (due to foreign key constraints)
        DELETE FROM book_club_poll_votes
        WHERE poll_id = ANY(polls_to_delete);
        
        -- Delete the expired polls
        DELETE FROM book_club_polls
        WHERE id = ANY(polls_to_delete);
        
        GET DIAGNOSTICS deleted_polls = ROW_COUNT;
        
        RAISE NOTICE 'Deleted % polls and % votes', deleted_polls, deleted_votes;
    END IF;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Poll cleanup completed - deleted ' || deleted_polls || ' polls and ' || deleted_votes || ' votes',
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

-- Updated maintain_poll_hygiene function
CREATE OR REPLACE FUNCTION maintain_poll_hygiene()
RETURNS JSON AS $$
DECLARE
    close_result JSON;
    cleanup_result JSON;
    final_stats JSON;
BEGIN
    RAISE NOTICE 'Starting poll maintenance...';
    
    -- Step 1: Close expired polls that are still active
    SELECT close_expired_polls() INTO close_result;
    RAISE NOTICE 'Close result: %', close_result;
    
    -- Step 2: Cleanup polls expired for 24+ hours (both active and closed)
    SELECT cleanup_expired_polls() INTO cleanup_result;
    RAISE NOTICE 'Cleanup result: %', cleanup_result;
    
    -- Step 3: Get final statistics
    SELECT get_poll_cleanup_stats() INTO final_stats;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Poll maintenance completed successfully',
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

-- Grant permissions
GRANT EXECUTE ON FUNCTION cleanup_expired_polls TO authenticated;
GRANT EXECUTE ON FUNCTION maintain_poll_hygiene TO authenticated;

-- Test the fixed cleanup function
DO $$
DECLARE
    test_result JSON;
BEGIN
    RAISE NOTICE '=== TESTING FIXED CLEANUP FUNCTION ===';
    
    -- Run the cleanup
    SELECT cleanup_expired_polls() INTO test_result;
    RAISE NOTICE 'Cleanup test result: %', test_result;
    
    -- Show remaining polls
    RAISE NOTICE 'Remaining polls after cleanup:';
    PERFORM id, title, status, closes_at
    FROM book_club_polls
    ORDER BY created_at DESC;
    
END $$;

-- Final status check
SELECT 
    'Final Poll Count' as info,
    COUNT(*) as total_polls,
    COUNT(*) FILTER (WHERE status = 'active') as active_polls,
    COUNT(*) FILTER (WHERE status = 'closed') as closed_polls
FROM book_club_polls;

DO $$
BEGIN
    RAISE NOTICE '=== POLL CLEANUP LOGIC FIXED ===';
    RAISE NOTICE '✅ Updated cleanup function to handle both active and closed polls';
    RAISE NOTICE '✅ Added comprehensive logging for debugging';
    RAISE NOTICE '✅ Fixed logic to delete polls regardless of status if expired >24h';
    RAISE NOTICE '✅ Manual cleanup button should now work properly';
END $$;
