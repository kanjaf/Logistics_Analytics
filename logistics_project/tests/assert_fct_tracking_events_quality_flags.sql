-- Test: assert_fct_tracking_events_quality_flags
-- Purpose: Ensure tracking event quality flags agree with source values.

SELECT
    tracking_event_id
FROM {{ ref('fct_tracking_events') }}

WHERE
       (shipment_id IS NULL AND missing_shipment_id_flag <> 1)
    OR (shipment_id IS NOT NULL AND missing_shipment_id_flag <> 0)

    OR (
        (latitude < -90 OR latitude > 90)
        AND invalid_latitude_flag <> 1
    )
    OR (
        latitude BETWEEN -90 AND 90
        AND invalid_latitude_flag <> 0
    )

    OR (
        (longitude < -180 OR longitude > 180)
        AND invalid_longitude_flag <> 1
    )
    OR (
        longitude BETWEEN -180 AND 180
        AND invalid_longitude_flag <> 0
    )