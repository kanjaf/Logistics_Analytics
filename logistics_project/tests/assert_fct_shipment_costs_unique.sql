-- Test: assert_fct_shipment_costs_unique
-- Purpose: Ensure each shipment cost record has a unique cost_id.

SELECT
    cost_id,
    COUNT(*) AS record_count

FROM {{ ref('fct_shipment_costs') }}

GROUP BY cost_id

HAVING COUNT(*) > 1