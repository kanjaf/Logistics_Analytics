-- Test: dim_warehouse contains every staged warehouse plus one UNKNOWN member.

SELECT
    'Warehouse row count mismatch' AS failure_reason
WHERE
    (SELECT COUNT(*) FROM {{ ref('dim_warehouse') }})
    <>
    (SELECT COUNT(*) FROM {{ ref('stg_warehouses') }}) + 1