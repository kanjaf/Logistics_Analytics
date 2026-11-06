-- Test: Resolution hours must not be negative.

SELECT
    exception_id,
    resolution_hours
FROM {{ ref('fct_delivery_exceptions') }}
WHERE resolution_hours < 0