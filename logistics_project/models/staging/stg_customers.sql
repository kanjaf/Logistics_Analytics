
WITH source_data AS (
    SELECT *
    FROM {{ source('raw_logistics', 'customers') }}
),

geography AS (
    SELECT
        LOWER(LTRIM(RTRIM(city))) AS normalized_city,
        MAX(country) AS derived_country
    FROM dbo.african_countries_cities
    GROUP BY LOWER(LTRIM(RTRIM(city)))
),

cleaned AS (
    SELECT DISTINCT
        NULLIF(LTRIM(RTRIM(c.customer_id)), '') AS customer_id,
        NULLIF(LTRIM(RTRIM(c.customer_name)), '') AS customer_name,
        NULLIF(LTRIM(RTRIM(c.customer_segment)), '') AS customer_segment,
        NULLIF(LTRIM(RTRIM(c.city)), '') AS city,
        g.derived_country,
        c.account_created_date,
        c.credit_limit,
        CAST(ROUND(c.customer_rating, 2) AS DECIMAL(3, 2))
            AS customer_rating
    FROM source_data AS c
    LEFT JOIN geography AS g
        ON LOWER(LTRIM(RTRIM(c.city))) = g.normalized_city
)

SELECT *
FROM cleaned
