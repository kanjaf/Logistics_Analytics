
-- Verify that the shipment fact preserves the staging row count.
-- Returns a row only when the counts differ.

SELECT
    'Row count mismatch' AS failure_reason
WHERE
    (SELECT COUNT(*) FROM {{ ref('fct_shipments') }})
    <>
    (SELECT COUNT(*) FROM {{ ref('stg_shipments') }})
