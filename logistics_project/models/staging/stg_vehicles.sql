-- Model: stg_vehicles
-- Purpose: Clean and standardize vehicle records for logistics analytics.
--
-- Data-quality decisions:
-- 1. Remove exact duplicate source rows using original source values.
-- 2. Trim text, convert text to uppercase, and convert blank strings to NULL.
-- 3. Preserve missing vehicle statuses as NULL.
-- 4. Preserve negative odometer readings and flag them for investigation.
-- 5. Do not invent replacement values for missing or invalid data.

WITH source_data AS (
    SELECT
        vehicle_id,
        registration_number,
        vehicle_type,
        capacity_kg,
        fuel_type,
        vehicle_age_years,
        purchase_date,
        status,
        odometer_km,
        ROW_NUMBER() OVER (
            PARTITION BY
                vehicle_id,
                registration_number,
                vehicle_type,
                capacity_kg,
                fuel_type,
                vehicle_age_years,
                purchase_date,
                status,
                odometer_km
            ORDER BY (SELECT NULL)
        ) AS source_row_number
    FROM {{ source('raw_logistics', 'vehicles') }}
),

deduplicated AS (
    SELECT
        vehicle_id,
        registration_number,
        vehicle_type,
        capacity_kg,
        fuel_type,
        vehicle_age_years,
        purchase_date,
        status,
        odometer_km
    FROM source_data
    WHERE source_row_number = 1
),

cleaned AS (
    SELECT
        UPPER(NULLIF(LTRIM(RTRIM(vehicle_id)), '')) AS vehicle_id,
        UPPER(NULLIF(LTRIM(RTRIM(registration_number)), '')) AS registration_number,
        UPPER(NULLIF(LTRIM(RTRIM(vehicle_type)), '')) AS vehicle_type,
        CAST(capacity_kg AS INT) AS capacity_kg,
        UPPER(NULLIF(LTRIM(RTRIM(fuel_type)), '')) AS fuel_type,
        CAST(vehicle_age_years AS INT) AS vehicle_age_years,
        purchase_date,
        UPPER(NULLIF(LTRIM(RTRIM(status)), '')) AS status,
        CAST(odometer_km AS BIGINT) AS odometer_km,
        CASE
            WHEN odometer_km < 0 THEN 1
            ELSE 0
        END AS negative_odometer_flag
    FROM deduplicated
)

SELECT *
FROM cleaned