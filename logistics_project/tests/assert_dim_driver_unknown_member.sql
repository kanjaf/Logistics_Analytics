-- Test: dim_driver contains exactly one UNKNOWN member.

SELECT
    driver_id
FROM {{ ref('dim_driver') }}
WHERE driver_id = 'UNKNOWN'
HAVING COUNT(*) <> 1