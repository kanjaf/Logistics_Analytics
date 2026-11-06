-- Test: Each exception must appear exactly once in the fact table.

SELECT
    exception_id,
    COUNT(*) AS record_count
FROM {{ ref('fct_delivery_exceptions') }}
GROUP BY exception_id
HAVING COUNT(*) > 1