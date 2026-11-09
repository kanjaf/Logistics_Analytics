-- Test: assert_fct_shipment_costs_total_reconciliation
-- Purpose: Ensure calculated_total_cost equals the sum of all
-- five cost components whenever all components are available.

SELECT
    cost_id,
    transport_cost,
    fuel_cost,
    handling_cost,
    warehouse_cost,
    customs_cost,
    calculated_total_cost

FROM {{ ref('fct_shipment_costs') }}

WHERE
    transport_cost IS NOT NULL
    AND fuel_cost IS NOT NULL
    AND handling_cost IS NOT NULL
    AND warehouse_cost IS NOT NULL
    AND customs_cost IS NOT NULL
    AND (
        calculated_total_cost IS NULL
        OR ABS(
            calculated_total_cost -
            (
                transport_cost
                + fuel_cost
                + handling_cost
                + warehouse_cost
                + customs_cost
            )
        ) > 0.01
    )