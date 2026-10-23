-- Model: stg_warehouses
-- Purpose: Clean and standardize warehouse records for logistics analytics.
--
-- Data-quality decisions:
-- 1. Remove exact duplicate source rows using original source values.
-- 2. Trim text, convert text to uppercase, and convert blank strings to NULL.
-- 3. Preserve capacity and operating cost values for validation.
-- 4. Do not invent missing values or impose unverified business rules.

WITH source_data AS (
    SELECT
        warehouse_id,
        warehouse_name,
        city,
        country,
        warehouse_type,
        capacity_units,
        operating_cost_per_day,
        ROW_NUMBER() OVER (
            PARTITION BY
                warehouse_id,
                warehouse_name,
                city,
                country,
                warehouse_type,
                capacity_units,
                operating_cost_per_day
            ORDER BY (SELECT NULL)
        ) AS source_row_number
    FROM {{ source('raw_logistics', 'warehouses') }}
),

deduplicated AS (
    SELECT
        warehouse_id,
        warehouse_name,
        city,
        country,
        warehouse_type,
        capacity_units,
        operating_cost_per_day
    FROM source_data
    WHERE source_row_number = 1
),

cleaned AS (
    SELECT
        UPPER(NULLIF(LTRIM(RTRIM(warehouse_id)), ''))
            AS warehouse_id,

        UPPER(NULLIF(LTRIM(RTRIM(warehouse_name)), ''))
            AS warehouse_name,

        UPPER(NULLIF(LTRIM(RTRIM(city)), ''))
            AS city,

        UPPER(NULLIF(LTRIM(RTRIM(country)), ''))
            AS country,

        UPPER(NULLIF(LTRIM(RTRIM(warehouse_type)), ''))
            AS warehouse_type,

        CAST(capacity_units AS INT)
            AS capacity_units,

        CAST(operating_cost_per_day AS BIGINT)
            AS operating_cost_per_day

    FROM deduplicated
)

SELECT *
FROM cleaned