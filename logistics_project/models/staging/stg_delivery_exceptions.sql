
-- Model: stg_delivery_exceptions
-- Purpose: Clean delivery exception records for analytics.
--
-- Data-quality decisions:
-- 1. Preserve all source records; no duplicate IDs or exact duplicates found.
-- 2. Preserve missing severity values as NULL.
-- 3. Trim leading/trailing whitespace and uppercase all text columns.
-- 4. Preserve resolution hours; their meaning for open exceptions
--    requires clarification from the data owner.
-- 5. Round resolution hours to two decimal places for reporting.

WITH source_data AS (

    SELECT
        exception_id,
        shipment_id,
        exception_date,
        exception_type,
        severity,
        resolution_status,
        resolution_hours
    FROM {{ source('raw_logistics', 'delivery_exceptions') }}

),

cleaned AS (

    SELECT
        UPPER(NULLIF(LTRIM(RTRIM(exception_id)), ''))
            AS exception_id,

        UPPER(NULLIF(LTRIM(RTRIM(shipment_id)), ''))
            AS shipment_id,

        exception_date,

        UPPER(NULLIF(LTRIM(RTRIM(exception_type)), ''))
            AS exception_type,

        UPPER(NULLIF(LTRIM(RTRIM(severity)), ''))
            AS severity,

        UPPER(NULLIF(LTRIM(RTRIM(resolution_status)), ''))
            AS resolution_status,

        CAST(resolution_hours AS DECIMAL(10, 2))
            AS resolution_hours

    FROM source_data

)

SELECT *
FROM cleaned;
