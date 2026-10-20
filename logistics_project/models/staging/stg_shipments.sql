
-- Model: stg_shipments
-- Purpose: Clean and standardize raw shipment data while preserving
-- source values and exposing identified data-quality issues.
--
-- Source: raw_logistics.shipments
--
-- Data-quality principles:
-- 1. Remove exact duplicate rows.
-- 2. Standardize whitespace and convert blank strings to NULL.
-- 3. Cast numeric fields to appropriate data types.
-- 4. Preserve original delivery status, dates, and delay indicator.
-- 5. Add explicit flags instead of silently correcting conflicting data.

WITH source_data AS (
    SELECT *
    FROM {{ source('raw_logistics', 'shipments') }}
),

cleaned AS (
    SELECT DISTINCT
        NULLIF(LTRIM(RTRIM(shipment_id)), '') AS shipment_id,
        NULLIF(LTRIM(RTRIM(customer_id)), '') AS customer_id,
        NULLIF(LTRIM(RTRIM(trip_id)), '') AS trip_id,
        NULLIF(LTRIM(RTRIM(route_id)), '') AS route_id,

        booking_date,

        NULLIF(LTRIM(RTRIM(shipment_type)), '') AS shipment_type,
        NULLIF(LTRIM(RTRIM(priority)), '') AS priority,
        NULLIF(LTRIM(RTRIM(origin)), '') AS origin,
        NULLIF(LTRIM(RTRIM(destination)), '') AS destination,

        CAST(weight_kg AS DECIMAL(12, 2)) AS weight_kg,
        CAST(volume_m3 AS DECIMAL(12, 3)) AS volume_m3,
        CAST(shipment_value AS DECIMAL(18, 2)) AS shipment_value,

        expected_delivery_date,
        actual_delivery_date,

        NULLIF(LTRIM(RTRIM(delivery_status)), '') AS delivery_status,

        -- Preserve the source-system delay indicator.
        -- This field is not recalculated from the delivery dates.
        is_delayed,

        -- DATA-QUALITY FLAG: delay_flag_mismatch
        -- 1 = The source delay indicator disagrees with the date comparison.
        -- 0 = The source delay indicator agrees with the date comparison.
        -- NULL = A date is missing, so the comparison cannot be evaluated.
        --
        -- Business rule used for this check:
        -- A shipment is late by dates when actual_delivery_date
        -- is later than expected_delivery_date.
        --
        -- This flag identifies a disagreement; it does not determine
        -- which source field is correct.
        CASE
            WHEN actual_delivery_date IS NULL
              OR expected_delivery_date IS NULL
                THEN NULL

            WHEN actual_delivery_date > expected_delivery_date
                 AND is_delayed = 0
                THEN 1

            WHEN actual_delivery_date <= expected_delivery_date
                 AND is_delayed = 1
                THEN 1

            ELSE 0
        END AS delay_flag_mismatch,

        CAST(delay_days AS INT) AS delay_days,

        -- DATA-QUALITY FLAG: in_transit_with_actual_date_flag
        -- 1 = The normalized delivery status is IN TRANSIT,
        --     but an actual delivery date is populated.
        -- 0 = This specific inconsistency was not detected.
        --
        -- Underscores are replaced with spaces so both
        -- 'IN_TRANSIT' and 'In Transit' are recognized.
        --
        -- A populated actual date does not independently prove
        -- that delivery occurred. Preserve both source fields
        -- for investigation rather than changing either value.
        CASE
            WHEN UPPER(
                REPLACE(
                    LTRIM(RTRIM(delivery_status)),
                    '_',
                    ' '
                )
            ) = 'IN TRANSIT'
            AND actual_delivery_date IS NOT NULL
                THEN 1
            ELSE 0
        END AS in_transit_with_actual_date_flag

    FROM source_data
)

SELECT *
FROM cleaned
