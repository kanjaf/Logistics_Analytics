-- Test: assert_fct_tracking_events_row_count
-- Purpose: Ensure the fact table preserves every staging event.

SELECT
    (SELECT COUNT(*)
     FROM {{ ref('stg_tracking_events') }}) AS staging_count,

    (SELECT COUNT(*)
     FROM {{ ref('fct_tracking_events') }}) AS fact_count

WHERE
    (SELECT COUNT(*)
     FROM {{ ref('stg_tracking_events') }})
    <>
    (SELECT COUNT(*)
     FROM {{ ref('fct_tracking_events') }})