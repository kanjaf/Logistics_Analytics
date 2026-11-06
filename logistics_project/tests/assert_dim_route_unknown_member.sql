-- Test: dim_route contains exactly one UNKNOWN member.

SELECT
    'Expected exactly one UNKNOWN route member' AS failure_reason
WHERE
    (
        SELECT COUNT(*)
        FROM {{ ref('dim_route') }}
        WHERE route_id = 'UNKNOWN'
    ) <> 1