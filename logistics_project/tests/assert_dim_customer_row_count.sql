-- Verify that the customer dimension preserves all staging customers
-- and includes exactly one UNKNOWN member.

SELECT
    'Customer dimension row count mismatch' AS failure_reason
WHERE
    (SELECT COUNT(*) FROM {{ ref('dim_customer') }})
    <>
    (
        (SELECT COUNT(*) FROM {{ ref('stg_customers') }}) + 1
    )