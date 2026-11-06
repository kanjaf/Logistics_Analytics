-- Test: dim_vehicle contains exactly one UNKNOWN member.

SELECT
    'Expected exactly one UNKNOWN vehicle member' AS failure_reason
WHERE
    (
        SELECT COUNT(*)
        FROM {{ ref('dim_vehicle') }}
        WHERE vehicle_id = 'UNKNOWN'
    ) <> 1