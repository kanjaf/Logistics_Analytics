-- Test: assert_fct_tracking_events_unique
-- Purpose: Ensure each tracking event appears exactly once.

SELECT
    tracking_event_id,
    COUNT(*) AS event_count
FROM {{ ref('fct_tracking_events') }}
GROUP BY tracking_event_id
HAVING COUNT(*) > 1