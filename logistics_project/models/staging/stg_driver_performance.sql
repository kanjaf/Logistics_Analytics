
-- Model: stg_driver_performance
-- Purpose: Clean driver performance metrics and flag suspicious values.
--
-- Data-quality decisions:
-- 1. Preserve source metric values; do not silently correct anomalies.
-- 2. Standardize numeric precision for reporting.
-- 3. Flag on-time rates outside the assumed 0-1 range.
-- 4. Flag fuel-efficiency scores outside the assumed 0-100 range.
-- 5. Preserve the source performance period.

WITH source_data AS (
    SELECT
        driver_id,
        period,
        trips_completed,
        average_distance_km,
        safety_score,
        on_time_rate,
        fuel_efficiency_score
    FROM {{ source('raw_logistics', 'driver_performance') }}
),

cleaned AS (
    SELECT
        NULLIF(LTRIM(RTRIM(driver_id)), '') AS driver_id,
        period,
        trips_completed,
        CAST(average_distance_km AS DECIMAL(10, 2))
            AS average_distance_km,
        CAST(safety_score AS DECIMAL(5, 2)) AS safety_score,
        CAST(on_time_rate AS DECIMAL(6, 3)) AS on_time_rate,
        CAST(fuel_efficiency_score AS DECIMAL(6, 2))
            AS fuel_efficiency_score
    FROM source_data
)

SELECT
    *,
    CASE
        WHEN on_time_rate < 0 OR on_time_rate > 1 THEN 1
        ELSE 0
    END AS invalid_on_time_rate_flag,
    CASE
        WHEN fuel_efficiency_score < 0
          OR fuel_efficiency_score > 100 THEN 1
        ELSE 0
    END AS invalid_fuel_efficiency_score_flag
FROM cleaned;
