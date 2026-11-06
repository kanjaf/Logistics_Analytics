{{ config(materialized='view') }}

-- Model: dim_vehicle
-- Grain: One row per vehicle, including one UNKNOWN member.
-- Purpose: Vehicle attributes for fleet and logistics performance analysis.

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
    negative_odometer_flag
FROM {{ ref('stg_vehicles') }}

UNION ALL

SELECT
    CAST('UNKNOWN' AS NVARCHAR(50)) AS vehicle_id,
    CAST('Unknown' AS NVARCHAR(100)) AS registration_number,
    CAST('Unknown' AS NVARCHAR(100)) AS vehicle_type,
    CAST(NULL AS INT) AS capacity_kg,
    CAST('Unknown' AS NVARCHAR(50)) AS fuel_type,
    CAST(NULL AS INT) AS vehicle_age_years,
    CAST(NULL AS DATE) AS purchase_date,
    CAST('Unknown' AS NVARCHAR(50)) AS status,
    CAST(NULL AS BIGINT) AS odometer_km,
    CAST(0 AS INT) AS negative_odometer_flag