
-- Model: stg_warehouses
-- Purpose: Clean and standardize warehouse records for logistics analytics.
--
-- Data-quality decisions:
-- 1. Remove exact duplicate rows defensively.
-- 2. Trim text and convert blank strings to NULL.
-- 3. Standardize warehouse names, cities, and countries to uppercase.
-- 4. Standardize warehouse-type labels.
-- 5. Preserve capacity and operating cost values for validation.
-- 6. Do not invent missing values or impose unverified business rules.

WITH source_data AS (
    SELECT *
    FROM {{ source('raw_logistics', 'warehouses') }}
),

cleaned AS (
    SELECT DISTINCT
        NULLIF(LTRIM(RTRIM(warehouse_id)), '')
            AS warehouse_id,

        UPPER(NULLIF(LTRIM(RTRIM(warehouse_name)), ''))
            AS warehouse_name,

        UPPER(NULLIF(LTRIM(RTRIM(city)), ''))
            AS city,

        UPPER(NULLIF(LTRIM(RTRIM(country)), ''))
            AS country,

        CASE
            WHEN LOWER(LTRIM(RTRIM(warehouse_type)))
                 = 'fulfillment center'
                THEN 'Fulfillment Center'

            WHEN LOWER(LTRIM(RTRIM(warehouse_type)))
                 = 'regional hub'
                THEN 'Regional Hub'

            WHEN LOWER(LTRIM(RTRIM(warehouse_type)))
                 = 'cross-dock'
                THEN 'Cross-Dock'

            WHEN NULLIF(LTRIM(RTRIM(warehouse_type)), '') IS NULL
                THEN NULL

            ELSE LTRIM(RTRIM(warehouse_type))
        END AS warehouse_type,

        CAST(capacity_units AS INT)
            AS capacity_units,

        CAST(operating_cost_per_day AS BIGINT)
            AS operating_cost_per_day

    FROM source_data
)

SELECT *
FROM cleaned;
