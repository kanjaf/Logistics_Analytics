
-- Model: stg_vehicles
-- Purpose: Clean and standardize vehicle records for logistics analytics.
--
-- Data-quality decisions:
-- 1. Remove exact duplicate rows defensively.
-- 2. Trim text and convert blank strings to NULL.
-- 3. Standardize text casing for fuel type, vehicle type and status.
-- 4. Preserve missing vehicle statuses as NULL.
-- 5. Preserve negative odometer readings and flag them for investigation.
-- 6. Do not invent replacement values for missing or invalid data.

WITH source_data AS (
    SELECT *
    FROM {{ source('raw_logistics', 'vehicles') }}
),

cleaned AS (
    SELECT DISTINCT
        NULLIF(LTRIM(RTRIM(vehicle_id)), '') AS vehicle_id,
        NULLIF(LTRIM(RTRIM(registration_number)), '') AS registration_number,

        CASE
            WHEN NULLIF(LTRIM(RTRIM(vehicle_type)), '') IS NULL THEN NULL
            ELSE UPPER(LEFT(LTRIM(RTRIM(vehicle_type)), 1))
                 + LOWER(SUBSTRING(
                     LTRIM(RTRIM(vehicle_type)),
                     2,
                     LEN(LTRIM(RTRIM(vehicle_type)))
                 ))
        END AS vehicle_type,

        CAST(capacity_kg AS INT) AS capacity_kg,

        CASE
            WHEN LOWER(LTRIM(RTRIM(fuel_type))) = 'diesel' THEN 'Diesel'
            WHEN NULLIF(LTRIM(RTRIM(fuel_type)), '') IS NULL THEN NULL
            ELSE LTRIM(RTRIM(fuel_type))
        END AS fuel_type,

        CAST(vehicle_age_years AS INT) AS vehicle_age_years,
        purchase_date,

        CASE
            WHEN NULLIF(LTRIM(RTRIM(status)), '') IS NULL THEN NULL
            ELSE UPPER(LEFT(LTRIM(RTRIM(status)), 1))
                 + LOWER(SUBSTRING(
                     LTRIM(RTRIM(status)),
                     2,
                     LEN(LTRIM(RTRIM(status)))
                 ))
        END AS status,

        CAST(odometer_km AS BIGINT) AS odometer_km,

        CASE
            WHEN odometer_km < 0 THEN 1
            ELSE 0
        END AS negative_odometer_flag

    FROM source_data
)

SELECT *
FROM cleaned;
