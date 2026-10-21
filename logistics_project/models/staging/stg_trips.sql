
-- Model: stg_trips
-- Purpose: Clean and standardize trip records for logistics analytics.
--
-- Data-quality decisions:
-- 1. Remove exact duplicate rows using ROW_NUMBER(), not DISTINCT.
-- 2. Trim text values and convert blank strings to NULL.
-- 3. Convert actual departure and arrival timestamps to datetime2.
-- 4. Preserve missing vehicle and driver IDs.
-- 5. Flag trips with missing vehicle or driver assignments.
-- 6. Preserve source values rather than inventing replacements.

WITH source_data AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                trip_id,
                route_id,
                vehicle_id,
                driver_id,
                planned_departure,
                actual_departure,
                planned_arrival,
                actual_arrival,
                planned_distance_km,
                actual_distance_km,
                trip_status
            ORDER BY trip_id
        ) AS duplicate_rank
    FROM {{ source('raw_logistics', 'trips') }}
),

deduplicated AS (
    SELECT
        trip_id,
        route_id,
        vehicle_id,
        driver_id,
        planned_departure,
        actual_departure,
        planned_arrival,
        actual_arrival,
        planned_distance_km,
        actual_distance_km,
        trip_status
    FROM source_data
    WHERE duplicate_rank = 1
),

cleaned AS (
    SELECT
        NULLIF(LTRIM(RTRIM(trip_id)), '') AS trip_id,
        NULLIF(LTRIM(RTRIM(route_id)), '') AS route_id,
        NULLIF(LTRIM(RTRIM(vehicle_id)), '') AS vehicle_id,
        NULLIF(LTRIM(RTRIM(driver_id)), '') AS driver_id,

        planned_departure,
        TRY_CONVERT(datetime2, NULLIF(
            LTRIM(RTRIM(actual_departure)), ''
        )) AS actual_departure,

        planned_arrival,
        TRY_CONVERT(datetime2, NULLIF(
            LTRIM(RTRIM(actual_arrival)), ''
        )) AS actual_arrival,

        planned_distance_km,
        actual_distance_km,

        CASE
            WHEN LOWER(LTRIM(RTRIM(trip_status))) = 'completed'
                THEN 'Completed'
            WHEN LOWER(LTRIM(RTRIM(trip_status))) = 'cancelled'
                THEN 'Cancelled'
            ELSE NULLIF(LTRIM(RTRIM(trip_status)), '')
        END AS trip_status

    FROM deduplicated
)

SELECT
    *,
    CASE
        WHEN vehicle_id IS NULL THEN 1
        ELSE 0
    END AS missing_vehicle_id_flag,

    CASE
        WHEN driver_id IS NULL THEN 1
        ELSE 0
    END AS missing_driver_id_flag,

    CASE
        WHEN actual_departure IS NULL THEN 1
        ELSE 0
    END AS missing_actual_departure_flag,

    CASE
        WHEN actual_arrival IS NULL THEN 1
        ELSE 0
    END AS missing_actual_arrival_flag

FROM cleaned;
