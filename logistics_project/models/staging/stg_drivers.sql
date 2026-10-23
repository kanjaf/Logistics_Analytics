
-- Model: stg_drivers
-- Purpose: Clean and standardize driver records for logistics analytics.
--
-- Data-quality decisions:
-- 1. Remove exact duplicate source rows using original source values.
-- 2. Trim whitespace, convert text to uppercase, and convert blank text values to NULL.
-- 3. Preserve missing safety scores rather than inventing values.
-- 4. Cast safety_score to DECIMAL to avoid floating-point artifacts.
-- 5. Preserve source gender, licence class, hire date and experience values.
-- 6. Do not impose unverified business rules on safety scores.

WITH source_data AS (

    SELECT
        driver_id,
        driver_name,
        gender,
        hire_date,
        experience_years,
        license_class,
        home_city,
        safety_score,

        ROW_NUMBER() OVER (
            PARTITION BY
                driver_id,
                driver_name,
                gender,
                hire_date,
                experience_years,
                license_class,
                home_city,
                safety_score
            ORDER BY (SELECT NULL)
        ) AS source_row_number

    FROM {{ source('raw_logistics', 'drivers') }}

),

deduplicated AS (

    SELECT
        driver_id,
        driver_name,
        gender,
        hire_date,
        experience_years,
        license_class,
        home_city,
        safety_score
    FROM source_data
    WHERE source_row_number = 1

),

cleaned AS (

    SELECT
        UPPER(NULLIF(LTRIM(RTRIM(driver_id)), '')) AS driver_id,
        UPPER(NULLIF(LTRIM(RTRIM(driver_name)), '')) AS driver_name,
        UPPER(NULLIF(LTRIM(RTRIM(gender)), '')) AS gender,
        hire_date,
        CAST(experience_years AS INT) AS experience_years,
        UPPER(NULLIF(LTRIM(RTRIM(license_class)), '')) AS license_class,
        UPPER(NULLIF(LTRIM(RTRIM(home_city)), '')) AS home_city,

        -- Preserve NULL values; round floating-point scores to 2 decimals.
        CAST(ROUND(safety_score, 2) AS DECIMAL(5, 2)) AS safety_score

    FROM deduplicated

)

SELECT *
FROM cleaned
