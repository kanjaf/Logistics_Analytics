-- Test: dim_route contains every staged route plus one UNKNOWN member.

SELECT
    'Route row count mismatch' AS failure_reason
WHERE
    (SELECT COUNT(*) FROM {{ ref('dim_route') }})
    <>
    (SELECT COUNT(*) FROM {{ ref('stg_routes') }}) + 1