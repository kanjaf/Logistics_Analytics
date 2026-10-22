
-- Model: stg_tracking_events
-- Purpose: Clean tracking event records and flag data-quality issues.
--
-- Data-quality decisions:
-- 1. Remove exact duplicate rows only.
-- 2. Preserve missing shipment IDs and coordinate values as NULL.
-- 3. Convert event_timestamp to DATETIME2.
-- 4. Standardize text fields by trimming whitespace.
-- 5. Flag coordinates outside valid geographic ranges.
-- 6. Preserve source coordinates; do not silently correct them.

WITH source_data AS (
    SELECT
        tracking_event_id,
        shipment_id,
        event_timestamp,
        event_status,
        location,
        latitude,
        longitude,
        event_source
    FROM {{ source('raw_logistics', 'tracking_events') }}
),

cleaned AS (
    SELECT
        UPPER(NULLIF(LTRIM(RTRIM(tracking_event_id)), ''))
            AS tracking_event_id,

        UPPER(NULLIF(LTRIM(RTRIM(shipment_id)), ''))
            AS shipment_id,

        TRY_CONVERT(
            DATETIME2,
            NULLIF(LTRIM(RTRIM(event_timestamp)), '')
        ) AS event_timestamp,

        UPPER(NULLIF(LTRIM(RTRIM(event_status)), ''))
            AS event_status,

        UPPER(NULLIF(LTRIM(RTRIM(location)), ''))
            AS location,

        CAST(latitude AS DECIMAL(10, 6)) AS latitude,
        CAST(longitude AS DECIMAL(10, 6)) AS longitude,

        UPPER(NULLIF(LTRIM(RTRIM(event_source)), ''))
            AS event_source

    FROM source_data
),

deduplicated AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                tracking_event_id,
                shipment_id,
                event_timestamp,
                event_status,
                location,
                latitude,
                longitude,
                event_source
            ORDER BY tracking_event_id
        ) AS duplicate_row_number
    FROM cleaned
),

flagged AS (
    SELECT
        tracking_event_id,
        shipment_id,
        event_timestamp,
        event_status,
        location,
        latitude,
        longitude,
        event_source,

        CASE
            WHEN shipment_id IS NULL THEN 1
            ELSE 0
        END AS missing_shipment_id_flag,

        CASE
            WHEN latitude IS NOT NULL
             AND (latitude < -90 OR latitude > 90)
            THEN 1
            ELSE 0
        END AS invalid_latitude_flag,

        CASE
            WHEN longitude IS NOT NULL
             AND (longitude < -180 OR longitude > 180)
            THEN 1
            ELSE 0
        END AS invalid_longitude_flag

    FROM deduplicated
    WHERE duplicate_row_number = 1
)

SELECT *
FROM flagged;
