-- Test: dim_vehicle contains every staged vehicle plus one UNKNOWN member.

SELECT
    'Vehicle row count mismatch' AS failure_reason
WHERE
    (SELECT COUNT(*) FROM {{ ref('dim_vehicle') }})
    <>
    (SELECT COUNT(*) FROM {{ ref('stg_vehicles') }}) + 1