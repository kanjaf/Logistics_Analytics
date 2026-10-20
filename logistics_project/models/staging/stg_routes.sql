
-- Model: stg_routes
-- Purpose: Clean and standardize route records for logistics analytics.
--
-- Data-quality decisions:
-- 1. Remove exact duplicate rows defensively.
-- 2. Trim text and convert blank strings to NULL.
-- 3. Standardize city-name casing.
-- 4. Standardize route type labels.
-- 5. Preserve the source distance and flag non-positive values.
-- 6. Preserve 'None' in border_crossing because its business meaning
--    has not yet been independently verified.
-- 7. Round transit hours to two decimal places to remove float artifacts.

WITH source_data AS (
    SELECT *
    FROM {{ source('raw_logistics', 'routes') }}
),

cleaned AS (
    SELECT DISTINCT
        NULLIF(LTRIM(RTRIM(route_id)), '') AS route_id,

        CASE
            WHEN NULLIF(LTRIM(RTRIM(origin_city)), '') IS NULL THEN NULL
            ELSE UPPER(LEFT(LTRIM(RTRIM(origin_city)), 1))
                 + LOWER(SUBSTRING(
                     LTRIM(RTRIM(origin_city)),
                     2,
                     LEN(LTRIM(RTRIM(origin_city)))
                 ))
        END AS origin_city,

        CASE
            WHEN NULLIF(LTRIM(RTRIM(destination_city)), '') IS NULL THEN NULL
            ELSE UPPER(LEFT(LTRIM(RTRIM(destination_city)), 1))
                 + LOWER(SUBSTRING(
                     LTRIM(RTRIM(destination_city)),
                     2,
                     LEN(LTRIM(RTRIM(destination_city)))
                 ))
        END AS destination_city,

        CAST(distance_km AS INT) AS distance_km,

        CASE
            WHEN LOWER(REPLACE(LTRIM(RTRIM(route_type)), '-', ' ')) = 'cross border'
                THEN 'Cross-Border'
            WHEN NULLIF(LTRIM(RTRIM(route_type)), '') IS NULL THEN NULL
            ELSE LTRIM(RTRIM(route_type))
        END AS route_type,

        NULLIF(LTRIM(RTRIM(border_crossing)), '') AS border_crossing,

        CAST(ROUND(standard_transit_hours, 2) AS DECIMAL(8, 2))
            AS standard_transit_hours,

        CASE
            WHEN LOWER(LTRIM(RTRIM(road_quality))) = 'good' THEN 'Good'
            WHEN LOWER(LTRIM(RTRIM(road_quality))) = 'moderate' THEN 'Moderate'
            WHEN LOWER(LTRIM(RTRIM(road_quality))) = 'poor' THEN 'Poor'
            WHEN NULLIF(LTRIM(RTRIM(road_quality)), '') IS NULL THEN NULL
            ELSE LTRIM(RTRIM(road_quality))
        END AS road_quality

    FROM source_data
),

flagged AS (
    SELECT
        *,
        CASE
            WHEN distance_km <= 0 THEN 1
            ELSE 0
        END AS invalid_distance_flag
    FROM cleaned
)

SELECT *
FROM flagged;
