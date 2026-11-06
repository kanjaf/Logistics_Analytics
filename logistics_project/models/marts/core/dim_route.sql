{{ config(materialized='view') }}

-- Model: dim_route
-- Grain: One row per route, including one UNKNOWN member.
-- Purpose: Route attributes for geographic and logistics performance analysis.

SELECT
    route_id,
    origin_city,
    destination_city,
    distance_km,
    route_type,
    border_crossing,
    standard_transit_hours,
    road_quality
FROM {{ ref('stg_routes') }}

UNION ALL

SELECT
    CAST('UNKNOWN' AS NVARCHAR(50)) AS route_id,
    CAST('Unknown' AS NVARCHAR(100)) AS origin_city,
    CAST('Unknown' AS NVARCHAR(100)) AS destination_city,
    CAST(NULL AS INT) AS distance_km,
    CAST('Unknown' AS NVARCHAR(50)) AS route_type,
    CAST('Unknown' AS NVARCHAR(50)) AS border_crossing,
    CAST(NULL AS FLOAT) AS standard_transit_hours,
    CAST('Unknown' AS NVARCHAR(50)) AS road_quality