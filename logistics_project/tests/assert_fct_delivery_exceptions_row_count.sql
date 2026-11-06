-- Test: Fact row count must match staging row count.

SELECT
    'Delivery exception fact row count does not match staging' AS failure_reason
WHERE
    (SELECT COUNT(*) FROM {{ ref('fct_delivery_exceptions') }})
    <>
    (SELECT COUNT(*) FROM {{ ref('stg_delivery_exceptions') }})