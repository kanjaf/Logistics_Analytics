
-- Model: dim_customer
-- Grain: One row per customer, including one Unknown member.
-- Purpose: Customer attributes for shipment and commercial analysis.

SELECT
    customer_id,
    customer_name,
    customer_segment,
    city,
    derived_country AS country,
    CAST(account_created_date AS DATE) AS account_created_date,
    credit_limit,
    customer_rating
FROM {{ ref('stg_customers') }}

UNION ALL

SELECT
    CAST('UNKNOWN' AS NVARCHAR(50)) AS customer_id,
    CAST('Unknown' AS NVARCHAR(255)) AS customer_name,
    CAST('Unknown' AS NVARCHAR(100)) AS customer_segment,
    CAST('Unknown' AS NVARCHAR(100)) AS city,
    CAST('Unknown' AS NVARCHAR(100)) AS country,
    CAST(NULL AS DATE) AS account_created_date,
    CAST(NULL AS INT) AS credit_limit,
    CAST(NULL AS DECIMAL(10, 2)) AS customer_rating
