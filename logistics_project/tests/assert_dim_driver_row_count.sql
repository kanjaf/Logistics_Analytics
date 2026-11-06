-- Test: dim_driver contains every staged driver plus one UNKNOWN member.

SELECT
    'Driver row count mismatch' AS failure_reason
WHERE
    (SELECT COUNT(*) FROM {{ ref('dim_driver') }})
    <>
    (SELECT COUNT(*) FROM {{ ref('stg_drivers') }}) + 1