
-- Model: stg_drivers
-- Purpose: Clean and standardize driver records for logistics analytics.
--
-- Data-quality decisions:
-- 1. Remove exact duplicate rows without modifying the raw source.
-- 2. Trim whitespace and convert blank text values to NULL.
-- 3. Preserve missing safety scores rather than inventing values.
-- 4. Cast safety_score to DECIMAL to avoid floating-point artifacts.
-- 5. Preserve source gender, licence class, hire date and experience values.
-- 6. Do not impose unverified business rules on safety scores.

WITH source_data AS (

    SELECT *
    FROM {{ source('raw_logistics', 'drivers') }}

),

cleaned AS (

    SELECT DISTINCT
        NULLIF(LTRIM(RTRIM(driver_id)), '') AS driver_id,
        NULLIF(LTRIM(RTRIM(driver_name)), '') AS driver_name,
        NULLIF(LTRIM(RTRIM(gender)), '') AS gender,
        hire_date,
        CAST(experience_years AS INT) AS experience_years,
        NULLIF(LTRIM(RTRIM(license_class)), '') AS license_class,
        NULLIF(LTRIM(RTRIM(home_city)), '') AS home_city,

        -- Preserve NULL values; round floating-point scores to 2 decimals.
        CAST(ROUND(safety_score, 2) AS DECIMAL(5, 2)) AS safety_score

    FROM source_data

)

SELECT *
FROM cleaned
