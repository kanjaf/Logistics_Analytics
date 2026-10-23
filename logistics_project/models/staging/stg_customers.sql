-- Model: stg_customers
-- Purpose: Clean and standardize customer records for logistics analytics.
--
-- Data-quality decisions:
-- 1. Remove exact duplicate source rows using original source values.
-- 2. Trim text, convert text to uppercase, and convert blank strings to NULL.
-- 3. Remove embedded spaces from customer_id and customer_segment.
-- 4. Enrich customer records with country information from the geography lookup.
-- 5. Preserve missing geography matches rather than inventing country values.
-- 6. Round customer ratings to two decimal places.

WITH source_data AS (
    SELECT
        customer_id,
        customer_name,
        customer_segment,
        city,
        account_created_date,
        credit_limit,
        customer_rating,
        ROW_NUMBER() OVER (
            PARTITION BY
                customer_id,
                customer_name,
                customer_segment,
                city,
                account_created_date,
                credit_limit,
                customer_rating
            ORDER BY (SELECT NULL)
        ) AS source_row_number
    FROM {{ source('raw_logistics', 'customers') }}
),

deduplicated AS (
    SELECT
        customer_id,
        customer_name,
        customer_segment,
        city,
        account_created_date,
        credit_limit,
        customer_rating
    FROM source_data
    WHERE source_row_number = 1
),

geography AS (
    SELECT
        UPPER(LTRIM(RTRIM(city))) AS normalized_city,
        MAX(country) AS derived_country
    FROM dbo.african_countries_cities
    GROUP BY UPPER(LTRIM(RTRIM(city)))
),

cleaned AS (
    SELECT
        NULLIF(
            UPPER(REPLACE(LTRIM(RTRIM(c.customer_id)), ' ', '')),
            ''
        ) AS customer_id,

        UPPER(NULLIF(LTRIM(RTRIM(c.customer_name)), ''))
            AS customer_name,

        NULLIF(
            UPPER(REPLACE(LTRIM(RTRIM(c.customer_segment)), ' ', '')),
            ''
        ) AS customer_segment,

        UPPER(NULLIF(LTRIM(RTRIM(c.city)), ''))
            AS city,

        UPPER(NULLIF(LTRIM(RTRIM(g.derived_country)), ''))
            AS derived_country,

        c.account_created_date,

        c.credit_limit,

        CAST(
            ROUND(c.customer_rating, 2)
            AS DECIMAL(3, 2)
        ) AS customer_rating

    FROM deduplicated AS c
    LEFT JOIN geography AS g
        ON UPPER(LTRIM(RTRIM(c.city))) = g.normalized_city
)

SELECT *
FROM cleaned