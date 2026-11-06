-- Test: dim_warehouse contains exactly one UNKNOWN member.

SELECT
    'Expected exactly one UNKNOWN warehouse member' AS failure_reason
WHERE
    (
        SELECT COUNT(*)
        FROM {{ ref('dim_warehouse') }}
        WHERE warehouse_id = 'UNKNOWN'
    ) <> 1