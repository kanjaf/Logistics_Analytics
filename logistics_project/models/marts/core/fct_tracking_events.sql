{{ config(materialized='view') }}

-- Model: fct_tracking_events
-- Grain: One row per tracking event.
-- Purpose: Supports shipment journey, milestone, location
-- and transit timeline analysis.
--
-- Data-quality decisions:
-- 1. Preserve all 60,014 tracking events.
-- 2. Preserve original shipment IDs, including NULLs
--    and references that do not match fct_shipments.
-- 3. Classify shipment references without dropping events.
-- 4. Preserve original coordinates and staging quality flags.
-- 5. Derive date_key from event_timestamp for date analysis.
-- 6. Retain all recorded event types and event sources.

SELECT
    t.tracking_event_id,

    t.shipment_id,

    CASE
        WHEN t.shipment_id IS NULL
            THEN 'MISSING'
        WHEN s.shipment_id IS NULL
            THEN 'UNMATCHED'
        ELSE 'MATCHED'
    END AS shipment_reference_status,

    CONVERT(INT, CONVERT(CHAR(8), t.event_timestamp, 112))
        AS date_key,

    t.event_timestamp,
    t.event_status,
    t.location,
    t.latitude,
    t.longitude,
    t.event_source,

    t.missing_shipment_id_flag,
    t.invalid_latitude_flag,
    t.invalid_longitude_flag

FROM {{ ref('stg_tracking_events') }} AS t

LEFT JOIN {{ ref('fct_shipments') }} AS s
    ON t.shipment_id = s.shipment_id