
-- Model: stg_shipments
-- Purpose: Clean and standardize shipment records for logistics analytics.
--
-- Data-quality decisions:
-- 1. Remove exact duplicate source rows using original source values.
-- 2. Trim whitespace, convert text to uppercase, and convert blank text values to NULL.
-- 3. Preserve source delivery dates, status, and delay indicator.
-- 4. Flag disagreements between the source delay indicator and delivery dates.
-- 5. Flag IN TRANSIT shipments with a populated actual delivery date.
-- 6. Preserve source values when data-quality issues are detected.

WITH source_data AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                shipment_id,
                customer_id,
                trip_id,
                route_id,
                booking_date,
                shipment_type,
                priority,
                origin,
                destination,
                weight_kg,
                volume_m3,
                shipment_value,
                expected_delivery_date,
                actual_delivery_date,
                delivery_status,
                is_delayed,
                delay_days
            ORDER BY (SELECT NULL)
        ) AS source_row_number
    FROM {{ source('raw_logistics', 'shipments') }}

),

deduplicated AS (

    SELECT *
    FROM source_data
    WHERE source_row_number = 1

),

cleaned AS (

    SELECT
        UPPER(NULLIF(LTRIM(RTRIM(shipment_id)), '')) AS shipment_id,
        UPPER(NULLIF(LTRIM(RTRIM(customer_id)), '')) AS customer_id,
        UPPER(NULLIF(LTRIM(RTRIM(trip_id)), '')) AS trip_id,
        UPPER(NULLIF(LTRIM(RTRIM(route_id)), '')) AS route_id,

        booking_date,

        UPPER(NULLIF(LTRIM(RTRIM(shipment_type)), '')) AS shipment_type,
        UPPER(NULLIF(LTRIM(RTRIM(priority)), '')) AS priority,
        UPPER(NULLIF(LTRIM(RTRIM(origin)), '')) AS origin,
        UPPER(NULLIF(LTRIM(RTRIM(destination)), '')) AS destination,

        CAST(weight_kg AS DECIMAL(12, 2)) AS weight_kg,
        CAST(volume_m3 AS DECIMAL(12, 3)) AS volume_m3,
        CAST(shipment_value AS DECIMAL(18, 2)) AS shipment_value,

        expected_delivery_date,
        actual_delivery_date,

        UPPER(
            NULLIF(LTRIM(RTRIM(delivery_status)), '')
        ) AS delivery_status,

        -- Preserve the source-system delay indicator.
        is_delayed,

        -- 1 = Source delay indicator disagrees with delivery dates.
        -- 0 = No disagreement detected.
        -- NULL = A required date is missing.
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

        -- 1 = IN TRANSIT status with an actual delivery date.
        -- Preserve both source values for investigation.
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

    FROM deduplicated

)

SELECT *
FROM cleaned
