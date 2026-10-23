
-- Model: stg_routes
-- Purpose: Standardize route records and derive route scope from country mappings.
--
-- Data-quality decisions:
-- 1. Remove exact duplicate source rows using original source values.
-- 2. Use clean_text to trim, uppercase, replace hyphens with spaces,
--    and convert blank strings to NULL.
-- 3. Derive route_scope from origin and destination countries.
-- 4. Preserve original route_type for auditability.
-- 5. Preserve source distances and flag non-positive values.
-- 6. Preserve NONE in border_crossing because its meaning is unverified.
-- 7. Round transit hours to two decimal places.
-- 8. Leave route_scope NULL when either city has an ambiguous or
--    unmatched country mapping.

WITH source_data AS (
    SELECT
        route_id,
        origin_city,
        destination_city,
        distance_km,
        route_type,
        border_crossing,
        standard_transit_hours,
        road_quality,
        ROW_NUMBER() OVER (
            PARTITION BY
                route_id,
                origin_city,
                destination_city,
                distance_km,
                route_type,
                border_crossing,
                standard_transit_hours,
                road_quality
            ORDER BY (SELECT NULL)
        ) AS source_row_number
    FROM {{ source('raw_logistics', 'routes') }}
),

deduplicated AS (
    SELECT
        route_id,
        origin_city,
        destination_city,
        distance_km,
        route_type,
        border_crossing,
        standard_transit_hours,
        road_quality
    FROM source_data
    WHERE source_row_number = 1
),

city_country_counts AS (
    SELECT
        UPPER(LTRIM(RTRIM(city))) AS city,
        COUNT(DISTINCT UPPER(LTRIM(RTRIM(country))))
            AS country_count
    FROM {{ source('raw_logistics', 'african_countries_cities') }}
    GROUP BY UPPER(LTRIM(RTRIM(city)))
),

unique_city_countries AS (
    SELECT
        UPPER(LTRIM(RTRIM(M.city))) AS city,
        MAX(UPPER(LTRIM(RTRIM(M.country)))) AS country
    FROM {{ source('raw_logistics', 'african_countries_cities') }} AS M
    INNER JOIN city_country_counts AS C
        ON UPPER(LTRIM(RTRIM(M.city))) = C.city
    WHERE C.country_count = 1
    GROUP BY UPPER(LTRIM(RTRIM(M.city)))
),

cleaned AS (
    SELECT
        {{ clean_text('R.route_id') }} AS route_id,
        {{ clean_text('R.origin_city') }} AS origin_city,
        {{ clean_text('R.destination_city') }} AS destination_city,

        CAST(R.distance_km AS INT) AS distance_km,

        {{ clean_text('R.route_type') }} AS route_type,
        {{ clean_text('R.border_crossing') }} AS border_crossing,

        CAST(
            ROUND(R.standard_transit_hours, 2)
            AS DECIMAL(8, 2)
        ) AS standard_transit_hours,

        {{ clean_text('R.road_quality') }} AS road_quality,

        UPPER(LTRIM(RTRIM(O.country))) AS origin_country,
        UPPER(LTRIM(RTRIM(D.country))) AS destination_country

    FROM deduplicated AS R

    LEFT JOIN unique_city_countries AS O
        ON UPPER(LTRIM(RTRIM(R.origin_city))) = O.city

    LEFT JOIN unique_city_countries AS D
        ON UPPER(LTRIM(RTRIM(R.destination_city))) = D.city
),

flagged AS (
    SELECT
        *,
        CASE
            WHEN distance_km <= 0 THEN 1
            ELSE 0
        END AS invalid_distance_flag,

        CASE
            WHEN origin_country IS NULL
              OR destination_country IS NULL THEN NULL
            WHEN origin_country = destination_country THEN 'INLAND'
            ELSE 'CROSS BORDER'
        END AS route_scope

    FROM cleaned
)

SELECT *
FROM flagged
